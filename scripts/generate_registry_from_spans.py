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
from typing import Dict, List, Set, Any

def create_default_attribute_info():
    return {
        'types': Counter(),
        'examples': set(),
        'span_contexts': set()
    }

def create_default_span_pattern():
    return {
        'kinds': Counter(),
        'attributes': Counter(),
        'names': set()
    }

def analyze_spans(spans_data: List[Dict]) -> Dict:
    """Analiza spans para extraer información de atributos y patrones."""
    
    attributes_info = defaultdict(create_default_attribute_info)
    span_patterns = defaultdict(create_default_span_pattern)
    
    for span in spans_data:
        span_name = span.get('name', 'unknown')
        span_kind = span.get('kind', 'INTERNAL')
        attributes = span.get('attributes', {})
        
        # Analizar atributos
        for attr_name, attr_value in attributes.items():
            attr_type = type(attr_value).__name__
            if attr_type == 'str':
                attr_type = 'string'
            elif attr_type == 'int':
                attr_type = 'int'
            elif attr_type == 'float':
                attr_type = 'double'
            elif attr_type == 'bool':
                attr_type = 'boolean'
            
            attributes_info[attr_name]['types'][attr_type] += 1
            attributes_info[attr_name]['examples'].add(str(attr_value))
            attributes_info[attr_name]['span_contexts'].add(span_name)
        
        # Analizar patrones de span
        operation_key = extract_operation_key(span_name)
        span_patterns[operation_key]['kinds'][span_kind] += 1
        span_patterns[operation_key]['names'].add(span_name)
        
        for attr_name in attributes.keys():
            span_patterns[operation_key]['attributes'][attr_name] += 1
    
    return {
        'attributes': dict(attributes_info),
        'span_patterns': dict(span_patterns)
    }

def extract_operation_key(span_name: str) -> str:
    """Extrae clave de operación del nombre del span."""
    # Lógica simple - podrías mejorar esto según tus patrones
    parts = span_name.split('.')
    if len(parts) > 1:
        return '.'.join(parts[:-1])  # Todo excepto la última parte
    return span_name.lower().replace(' ', '_')

def infer_attribute_type(type_counter: Counter) -> str:
    """Infiere el tipo más común de un atributo."""
    if not type_counter:
        return 'string'
    return type_counter.most_common(1)[0][0]

def generate_registry(analysis: Dict, app_name: str) -> Dict:
    """Genera estructura de registry YAML."""
    
    registry = {
        'groups': []
    }
    
    # 1. Generar attribute groups
    attribute_group = {
        'id': f'registry.{app_name}.attributes',
        'type': 'attribute_group',
        'brief': f'Atributos comunes de {app_name}',
        'attributes': []
    }
    
    for attr_name, attr_info in analysis['attributes'].items():
        attr_type = infer_attribute_type(attr_info['types'])
        examples = list(attr_info['examples'])[:3]  # Máximo 3 ejemplos
        
        attribute = {
            'name': attr_name,
            'type': attr_type,
            'brief': f'Atributo {attr_name}',
            'examples': examples,
            'requirement_level': 'recommended',
            'stability': 'development'
        }
        
        attribute_group['attributes'].append(attribute)
    
    registry['groups'].append(attribute_group)
    
    # 2. Generar span groups
    for operation_key, pattern_info in analysis['span_patterns'].items():
        most_common_kind = pattern_info['kinds'].most_common(1)[0][0].lower()
        
        span_group = {
            'id': f'span.{app_name}.{operation_key}',
            'type': 'span',
            'span_kind': most_common_kind,
            'brief': f'Span para operación {operation_key}',
            'attributes': []
        }
        
        # Agregar atributos más comunes para este span
        for attr_name, count in pattern_info['attributes'].most_common(10):
            requirement = 'required' if count > len(pattern_info['names']) * 0.8 else 'recommended'
            span_group['attributes'].append({
                'ref': attr_name,
                'requirement_level': requirement
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
    with open(input_file, 'r') as f:
        spans_data = json.load(f)
    
    if not isinstance(spans_data, list):
        print("Error: El archivo JSON debe contener una lista de spans")
        sys.exit(1)
    
    # Inferir nombre de app desde el primer span o usar default
    app_name = 'myapp'
    if spans_data and 'service.name' in spans_data[0].get('attributes', {}):
        app_name = spans_data[0]['attributes']['service.name'].lower()
    
    # Analizar spans
    analysis = analyze_spans(spans_data)
    
    # Generar registry
    registry = generate_registry(analysis, app_name)
    
    # Guardar resultado
    with open(output_file, 'w') as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False)
    
    print(f"Registry generado en {output_file}")
    print(f"Atributos únicos encontrados: {len(analysis['attributes'])}")
    print(f"Patrones de span encontrados: {len(analysis['span_patterns'])}")

if __name__ == '__main__':
    main()