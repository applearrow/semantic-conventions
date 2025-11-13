# Ejemplo de uso de las convenciones semánticas de Semantic Search

## Resumen

Este ejemplo muestra cómo usar Weaver para validar que los spans `semantic-search.pomera` y `semantic-search.pom` 
cumplen con las convenciones semánticas definidas.

## Archivos definidos

### 1. `/model/semantic-search/registry.yaml`
Define los atributos disponibles para las operaciones Semantic Search:
- `operation.type`: Tipo de operación (pomera, pom, etc.)
- `operation.id`: Identificador único de la operación  
- `operation.status`: Estado de la operación (success, failure, pending)

### 2. `/model/semantic-search/spans.yaml`
Define las convenciones para los spans:
- `span.semantic_search.pomera`: Span para operaciones semantic-search.pomera
- `span.semantic_search.pom`: Span para operaciones semantic-search.pom

## Validación con Weaver

Para validar tus convenciones semánticas:

```bash
# Validar toda la registry
docker run --rm -u $(id -u):$(id -g) \
  --mount 'type=bind,source=/path/to/semantic-conventions/model,target=/home/weaver/source,readonly' \
  docker.io/otel/weaver:v0.19.0 registry check \
  --registry=/home/weaver/source

# Generar documentación
docker run --rm -u $(id -u):$(id -g) \
  --mount 'type=bind,source=/path/to/semantic-conventions/templates,target=/home/weaver/templates,readonly' \
  --mount 'type=bind,source=/path/to/semantic-conventions/model,target=/home/weaver/source,readonly' \
  --mount 'type=bind,source=/path/to/semantic-conventions/docs,target=/home/weaver/target' \
  docker.io/otel/weaver:v0.19.0 registry generate \
  --registry=/home/weaver/source \
  --templates=/home/weaver/templates \
  markdown /home/weaver/target/registry/
```

## Ejemplo de instrumentación

Cuando implementes instrumentación para tus spans, deberías seguir estas convenciones:

### Span semantic-search.pomera
```json
{
  "name": "semantic-search.pomera",
  "kind": "INTERNAL",
  "attributes": {
    "operation.type": "pomera",
    "operation.id": "op-123",
    "operation.status": "success"
  }
}
```

### Span semantic-search.pom  
```json
{
  "name": "semantic-search.pom",
  "kind": "INTERNAL", 
  "attributes": {
    "operation.type": "pom",
    "operation.id": "batch-456",
    "operation.status": "pending"
  }
}
```

### En caso de error
```json
{
  "name": "semantic-search.pomera",
  "kind": "INTERNAL",
  "status": {
    "code": "ERROR",
    "message": "Operation failed due to timeout"
  },
  "attributes": {
    "operation.type": "pomera", 
    "operation.id": "op-789",
    "operation.status": "failure",
    "error.type": "timeout"
  }
}
```

## Estructura de archivos requerida

```
model/
└── semantic-search/
    ├── registry.yaml    # Define los atributos
    └── spans.yaml       # Define los spans
```

## Notas importantes

1. **Nombres de spans**: Los nombres `semantic-search.pomera` y `semantic-search.pom` son válidos según las convenciones de nomenclatura de OpenTelemetry.

2. **Atributos requeridos**: El atributo `operation.type` es obligatorio para ambos tipos de span.

3. **Consistencia**: El valor de `operation.type` debe coincidir con el tipo de span:
   - Para `semantic-search.pomera` → `operation.type` = "pomera"
   - Para `semantic-search.pom` → `operation.type` = "pom"

4. **Manejo de errores**: Cuando una operación falla, usa `error.type` y establece el estado del span como ERROR.

5. **Validación**: Weaver validará que todas las referencias de atributos se resuelvan correctamente y que cumplan con las políticas definidas.