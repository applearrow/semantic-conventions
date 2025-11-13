# Guía paso a paso para generar registry desde spans existentes

## Opción 1: Usar live-check de weaver (Recomendado)

### Paso 1: Preparar tu aplicación
Configura tu aplicación para enviar spans a un puerto específico (ej. 4317)

### Paso 2: Ejecutar live-check para capturar
```bash
# Iniciar captura de spans
weaver registry live-check \
  --input-source otlp \
  --otlp-grpc-port 4317 \
  --format json \
  --output captured_analysis.json \
  --inactivity-timeout 30
```

### Paso 3: Ejecutar tu aplicación
Con live-check ejecutándose, ejecuta los flujos principales de tu aplicación
para generar spans representativos.

### Paso 4: Analizar la salida
El archivo captured_analysis.json contendrá información sobre:
- Atributos encontrados con sus tipos
- Violaciones de convenciones existentes  
- Sugerencias de mejoras

## Opción 2: Análisis manual de spans

### Paso 1: Exportar spans en formato JSON
Si ya tienes spans almacenados, expórtalos en formato JSON OTLP.

### Paso 2: Crear registry manualmente
Basándote en los atributos más frecuentes, crear registry como:

```yaml
groups:
- id: registry.mi_app.common
  type: attribute_group
  brief: Atributos comunes de mi aplicación
  attributes:
  - name: [nombre_atributo_mas_frecuente]
    type: [string|int|double|boolean]
    brief: Descripción del atributo
    examples: [ejemplo1, ejemplo2]
    requirement_level: recommended
    stability: development

- id: span.mi_app.operacion_principal  
  type: span
  span_kind: [client|server|internal|producer|consumer]
  brief: Descripción de la operación
  attributes:
  - ref: [nombre_atributo]
    requirement_level: [required|recommended|opt_in]
```

## Opción 3: Proceso iterativo

### Paso 1: Registry mínimo inicial
Comienza con un registry básico que cubra los 5-10 atributos más importantes.

### Paso 2: Validar incrementalmente  
```bash
# Validar registry
weaver registry check -r ./mi_registry

# Generar documentación
weaver registry generate -r ./mi_registry markdown ./docs
```

### Paso 3: Expandir progresivamente
Agrega más atributos y spans conforme identifiques patrones adicionales.

## Tips importantes:

1. **Empieza pequeño**: No intentes capturar todos los atributos de una vez
2. **Prioriza por frecuencia**: Los atributos más utilizados primero
3. **Usa namespaces consistentes**: Sigue convenciones como `http.*`, `db.*`, etc.
4. **Valida frecuentemente**: Usa `weaver registry check` a menudo
5. **Revisa convenciones existentes**: Muchos atributos ya están en el registry oficial

## Ejemplo de flujo completo:

```bash
# 1. Capturar spans de tu app
weaver registry live-check --input-source otlp --format json -o analysis.json

# 2. Crear registry inicial (manual)
# 3. Validar
weaver registry check -r ./mi_registry

# 4. Generar documentación  
weaver registry generate -r ./mi_registry markdown ./docs

# 5. Iterar y mejorar
```