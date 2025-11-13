#!/usr/bin/env python3
"""
Filtro para violations conocidas de SDKs desfasados.

Este script filtra violations que son esperadas cuando el SDK aún no ha actualizado
atributos que fueron deprecados en versiones anteriores de semantic conventions.
"""

import json
import sys
from typing import Dict, List, Any, Set

# Atributos deprecados más comunes que los SDKs tardan en actualizar
KNOWN_SDK_LAG_ATTRIBUTES = {
    # Deployment - deprecados en v1.27.0
    "deployment.environment": "deployment.environment.name",
    
    # Database - deprecados principalmente en v1.26.0
    "db.statement": "db.query.text",
    "db.operation": "db.operation.name", 
    "db.name": "db.namespace",
    "db.system": "db.system.name",
    "db.user": None,  # Sin reemplazo
    "db.connection_string": "server.address + server.port",
    "db.instance.id": None,
    
    # Cassandra
    "db.cassandra.table": "db.collection.name",
    "db.cassandra.consistency_level": "cassandra.consistency.level",
    "db.cassandra.coordinator.dc": "cassandra.coordinator.dc",
    "db.cassandra.coordinator.id": "cassandra.coordinator.id",
    "db.cassandra.idempotence": "cassandra.query.idempotent",
    
    # MongoDB
    "db.mongodb.collection": "db.collection.name",
    
    # CosmosDB
    "db.cosmosdb.container": "db.collection.name",
    "db.cosmosdb.consistency_level": "azure.cosmosdb.consistency.level",
    "db.cosmosdb.operation_type": None,
    "db.cosmosdb.regions_contacted": "azure.cosmosdb.operation.contacted_regions",
    
    # Elasticsearch
    "db.elasticsearch.cluster.name": "db.namespace",
    "db.elasticsearch.node.name": "elasticsearch.node.name",
    
    # Redis
    "db.redis.database_index": "db.namespace",
    
    # Messaging - deprecados en v1.26.0 y v1.27.0
    "messaging.operation": "messaging.operation.type",
    "messaging.kafka.consumer.group": "messaging.consumer.group.name",
    "messaging.kafka.destination.partition": "messaging.destination.partition.id", 
    "messaging.kafka.message.offset": "messaging.kafka.offset",
    "messaging.eventhubs.consumer.group": "messaging.consumer.group.name",
    "messaging.rocketmq.client_group": "messaging.consumer.group.name",
    "messaging.servicebus.destination.subscription_name": "messaging.destination.subscription.name",
    "messaging.destination_publish.name": None,
    "messaging.destination_publish.anonymous": None,
    "messaging.client_id": "messaging.client.id",
    
    # RPC - deprecados en v1.26.0
    "message.compressed_size": "rpc.message.compressed_size",
    "message.id": "rpc.message.id", 
    "message.type": "rpc.message.type",
    "message.uncompressed_size": "rpc.message.uncompressed_size",
    
    # End User - deprecados en versiones anteriores
    "enduser.role": "user.roles",
    "enduser.scope": None,
    
    # TLS - deprecado en v1.27.0
    "tls.client.server_name": "server.address",
}

def filter_known_sdk_lag_violations(analysis_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Filtra violations conocidas del desfase de SDKs y las separa en categorías.
    
    Args:
        analysis_data: Datos del análisis de spans (JSON parseado)
        
    Returns:
        Diccionario con violations filtradas y estadísticas
    """
    original_violations = analysis_data.get('violations', [])
    
    # Separar violations en categorías
    real_violations = []
    sdk_lag_violations = []
    unknown_deprecated = []
    
    for violation in original_violations:
        attr_name = violation.get('attribute', '')
        violation_type = violation.get('type', '')
        
        if violation_type == 'deprecated_attribute' and attr_name in KNOWN_SDK_LAG_ATTRIBUTES:
            # Esta es una violation conocida del desfase del SDK
            violation['category'] = 'known_sdk_lag'
            violation['replacement'] = KNOWN_SDK_LAG_ATTRIBUTES[attr_name]
            sdk_lag_violations.append(violation)
        elif violation_type == 'deprecated_attribute':
            # Deprecado pero no conocido - podría ser nuevo
            violation['category'] = 'unknown_deprecated'
            unknown_deprecated.append(violation)
        else:
            # Violation real que necesita atención
            real_violations.append(violation)
    
    # Crear reporte filtrado
    filtered_analysis = {
        'original_analysis': analysis_data,
        'filtered_results': {
            'real_violations': real_violations,
            'sdk_lag_violations': sdk_lag_violations, 
            'unknown_deprecated': unknown_deprecated,
        },
        'summary': {
            'total_violations': len(original_violations),
            'real_issues': len(real_violations),
            'known_sdk_lag': len(sdk_lag_violations),
            'unknown_deprecated': len(unknown_deprecated),
            'attention_needed': len(real_violations) + len(unknown_deprecated),
        },
        'recommendations': generate_recommendations(real_violations, unknown_deprecated, sdk_lag_violations)
    }
    
    return filtered_analysis

def generate_recommendations(real_violations: List[Dict], unknown_deprecated: List[Dict], sdk_lag: List[Dict]) -> Dict[str, Any]:
    """Genera recomendaciones basadas en las violations encontradas."""
    
    recommendations = {
        'immediate_action': [],
        'monitor': [],
        'sdk_updates': [],
    }
    
    if real_violations:
        recommendations['immediate_action'].append({
            'type': 'fix_violations',
            'count': len(real_violations),
            'message': f'Fix {len(real_violations)} real violations in your application code',
            'violations': real_violations[:5]  # Mostrar solo las primeras 5
        })
    
    if unknown_deprecated:
        recommendations['monitor'].append({
            'type': 'check_new_deprecated',
            'count': len(unknown_deprecated),
            'message': f'Check {len(unknown_deprecated)} deprecated attributes not in known SDK lag list',
            'violations': unknown_deprecated
        })
    
    if sdk_lag:
        # Agrupar por área
        areas = {}
        for violation in sdk_lag:
            attr = violation['attribute']
            if attr.startswith('db.'):
                area = 'database'
            elif attr.startswith('messaging.'):
                area = 'messaging'
            elif attr.startswith('deployment.'):
                area = 'deployment'
            elif attr.startswith('rpc.') or attr.startswith('message.'):
                area = 'rpc'
            else:
                area = 'other'
            
            areas.setdefault(area, []).append(violation)
        
        recommendations['sdk_updates'] = [{
            'type': 'sdk_lag',
            'message': f'SDK lag detected in {len(areas)} areas: {", ".join(areas.keys())}',
            'areas': areas,
            'total_count': len(sdk_lag)
        }]
    
    return recommendations

def main():
    """Función principal del filtro."""
    if len(sys.argv) != 2:
        print("Usage: python3 filter_sdk_lag.py <spans_analysis.json>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = input_file.replace('.json', '_filtered.json')
    
    try:
        with open(input_file, 'r') as f:
            analysis_data = json.load(f)
        
        filtered_results = filter_known_sdk_lag_violations(analysis_data)
        
        # Guardar resultados filtrados
        with open(output_file, 'w') as f:
            json.dump(filtered_results, f, indent=2)
        
        # Mostrar resumen en consola
        summary = filtered_results['summary']
        print(f"\n🔍 ANÁLISIS DE VIOLATIONS FILTRADO")
        print(f"{'='*50}")
        print(f"📊 Total violations: {summary['total_violations']}")
        print(f"🚨 Issues reales: {summary['real_issues']} (requieren atención inmediata)")
        print(f"⏳ SDK lag conocido: {summary['known_sdk_lag']} (esperado)")
        print(f"❓ Deprecados desconocidos: {summary['unknown_deprecated']} (revisar)")
        print(f"\n💡 ATENCIÓN REQUERIDA: {summary['attention_needed']} violations")
        
        if summary['attention_needed'] == 0:
            print(f"✅ ¡Excelente! Solo violations de SDK lag esperado.")
        
        print(f"\n📝 Resultados detallados guardados en: {output_file}")
        
        # Mostrar recommendations importantes
        recs = filtered_results['recommendations']
        if recs['immediate_action']:
            print(f"\n🔴 ACCIÓN INMEDIATA:")
            for rec in recs['immediate_action']:
                print(f"   - {rec['message']}")
        
        if recs['monitor']:
            print(f"\n🟡 REVISAR:")
            for rec in recs['monitor']:
                print(f"   - {rec['message']}")
        
    except FileNotFoundError:
        print(f"Error: File {input_file} not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()