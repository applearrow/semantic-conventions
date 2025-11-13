#!/usr/bin/env python3
"""
Script para generar un registry de weaver desde spans OTLP capturados.

Uso:
  python generate_registry_from_spans.py captured_spans.json output_registry.yaml
"""

import json
import yaml
import sys
from collections import defaultdict, Counter

def analyze_spans(spans_data):
    """Analiza spans para extraer información de atributos y patrones."""
    
    all_attributes = {}
    span_operations = defaultdict(lambda: {
        'kinds': Counter(),
        'attributes': set(),
        'names': set()
    })
    
    for span in spans_data:
        span_name = span.get('name', 'unknown')
        span_kind = span.get('kind', 'INTERNAL')
        attributes = span.get('attributes', {})
        
        # Analizar atributos
        for attr_name, attr_value in attributes.items():
            if attr_name not in all_attributes:
                all_attributes[attr_name] = {
                    'examples': set(),
                    'type': 'string'  # default
                }
            
            all_attributes[attr_name]['examples'].add(str(attr_value))
            
            # Inferir tipo
            if isinstance(attr_value, int):
                all_attributes[attr_name]['type'] = 'int'
            elif isinstance(attr_value, float):
                all_attributes[attr_name]['type'] = 'double'
            elif isinstance(attr_value, bool):
                all_attributes[attr_name]['type'] = 'boolean'
        
        # Analizar patrones de span
        operation_key = extract_operation_key(span_name)
        span_operations[operation_key]['kinds'][span_kind] += 1
        span_operations[operation_key]['names'].add(span_name)
        span_operations[operation_key]['attributes'].update(attributes.keys())
    
    return {
        'attributes': all_attributes,
        'span_operations': dict(span_operations)
    }

def extract_operation_key(span_name):
    """Extrae clave de operación del nombre del span."""
    # Lógica simple - mejora según tus patrones
    parts = span_name.split('.')
    if len(parts) > 1:
        return '.'.join(parts[:-1])
    return span_name.lower().replace(' ', '_').replace('/', '_')

def generate_registry(analysis, app_name):
    """Genera estructura de registry YAML."""
    
    registry = {'groups': []}
    
    # 1. Generar attribute group
    attribute_group = {
        'id': f'registry.{app_name}.attributes',
        'type': 'attribute_group',
        'brief': f'Atributos comunes de {app_name}',
        'attributes': []
    }
    
    for attr_name, attr_info in analysis['attributes'].items():
        examples = list(attr_info['examples'])[:3]  # Máximo 3 ejemplos
        
        attribute = {
            'name': attr_name,
            'type': attr_info['type'],
            'brief': f'Atributo {attr_name}',
            'examples': examples,
            'requirement_level': 'recommended',
            'stability': 'development'
        }
        
        attribute_group['attributes'].append(attribute)
    
    registry['groups'].append(attribute_group)
    
    # 2. Generar span groups
    for operation_key, operation_info in analysis['span_operations'].items():
        most_common_kind = operation_info['kinds'].most_common(1)[0][0].lower()
        
        span_group = {
            'id': f'span.{app_name}.{operation_key}',
            'type': 'span',
            'span_kind': most_common_kind,
            'brief': f'Span para operación {operation_key}',
            'attributes': []
        }
        
        # Agregar referencias a atributos
        for attr_name in operation_info['attributes']:
            span_group['attributes'].append({
                'ref': attr_name,
                'requirement_level': 'recommended'
            })
        
        registry['groups'].append(span_group)
    
    return registry

def main():
    if len(sys.argv) != 3:
        print("Uso: python generate_registry_from_spans.py <input.json> <output.yaml>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Cargar datos de spans
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            spans_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: No se puede encontrar el archivo {input_file}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: El archivo {input_file} no es JSON válido")
        sys.exit(1)
    
    if not isinstance(spans_data, list):
        print("Error: El archivo JSON debe contener una lista de spans")
        sys.exit(1)
    
    # Inferir nombre de app
    app_name = 'myapp'
    if spans_data and isinstance(spans_data[0].get('attributes'), dict):
        service_name = spans_data[0]['attributes'].get('service.name')
        if service_name:
            app_name = service_name.lower().replace('-', '_').replace(' ', '_')
    
    # Analizar spans
    analysis = analyze_spans(spans_data)
    
    # Generar registry
    registry = generate_registry(analysis, app_name)
    
    # Guardar resultado
    with open(output_file, 'w', encoding='utf-8') as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
    
    print(f"Registry generado en {output_file}")
    print(f"Atributos únicos encontrados: {len(analysis['attributes'])}")
    print(f"Patrones de span encontrados: {len(analysis['span_operations'])}")

if __name__ == '__main__':
    main()