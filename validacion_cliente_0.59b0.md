# Validación de Cliente con opentelemetry-semantic-conventions 0.59b0

## Pasos para validar spans/atributos contra versión específica

### 1. Configurar tu aplicación cliente

```bash
# Tu aplicación debe configurarse para enviar a OTLP
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"

# Ejecutar tu app
python tu_aplicacion.py
```

### 2. Capturar y analizar spans

```bash
# Opción 1: Captura básica para análisis
just capture-spans analisis_cliente_0.59b0.json 4317 180

# Opción 2: Validación contra modelo atual
just capture-validate ./model analisis_validado.json 4317 180
```

### 3. Identificar la versión correcta del modelo

Para obtener las versiones desde el repo original de OpenTelemetry:

```bash
# Obtener tags desde upstream (original de OpenTelemetry)
git fetch upstream --tags

# Ver releases disponibles (últimas 15 versiones)
git tag --list | sort -V | tail -15
```

**Mapeo aproximado para 0.59b0**: Las versiones de Python `0.59b0` típicamente corresponden a semantic-conventions `v1.26.0` - `v1.28.0`

### 4. Validar contra versión específica

```bash
# Checkout a versión específica que corresponde a 0.59b0
git checkout v1.27.0  # versión aproximada para 0.59b0

# Validar spans contra esa versión específica
just capture-validate ./model spans_v1.27_vs_0.59b0.json 4317 120

# Volver a main
git checkout main
```

### 5. Análisis de resultados

El archivo JSON generado contendrá:

- **Violations**: Atributos que no cumplen las convenciones
- **Missing attributes**: Atributos requeridos que faltan
- **Unknown attributes**: Atributos no reconocidos
- **Type mismatches**: Tipos de datos incorrectos
- **Recommendations**: Sugerencias de mejoras

### 6. Ejemplo de análisis

```bash
# Ver violations
jq '.violations' analisis_cliente_0.59b0.json

# Ver atributos desconocidos
jq '.unknown_attributes' analisis_cliente_0.59b0.json

# Ver estadísticas generales
jq '.stats' analisis_cliente_0.59b0.json
```

### 7. Control del proceso

- **Parar manualmente**: Ctrl+C
- **Parar via API**: `curl http://localhost:4320/stop`
- **Auto-stop**: Después del timeout configurado

### 8. Comparación con versiones

```bash
# Generar análisis con diferentes versiones del modelo
git checkout v1.26.0
just capture-validate ./model spans_v1.26.json 4317 60

git checkout v1.30.0  
just capture-validate ./model spans_v1.30.json 4317 60

# Comparar diferencias
jq -s 'def diff(a; b): a - b; {added: diff(.[1].attributes; .[0].attributes), removed: diff(.[0].attributes; .[1].attributes)}' spans_v1.26.json spans_v1.30.json
```

## Mapeo CORRECTO de versiones Python ↔ Semantic Conventions

**¡IMPORTANTE!** Los tags de este repo NO se mapean directamente con las versiones Python.

### Mapeo real encontrado via GitHub API:

| Python Package Version | Semantic Conventions Version | Fecha | Notas |
|------------------------|------------------------------|--------|-------|
| **0.59b0** | **v1.38.0** | Oct 2025 | ✅ Confirmado via API |
| 0.60.0 | v1.39.0 (estimado) | TBD | Próximo release |

### Comando COMPLETO para validar cliente 0.59b0 (RECOMENDADO):

```bash
# 🚀 WORKFLOW COMPLETO: captura + valida + filtra SDK lag
just capture-and-filter-sdk v1.38.0 analisis_cliente_0.59b0.json 4317

# Esto automáticamente:
# 1. Cambia a v1.38.0 (versión correcta para 0.59b0)
# 2. Captura y valida spans contra esa versión  
# 3. Filtra violations conocidas del SDK lag
# 4. Vuelve a main
# 5. Genera analisis_cliente_0.59b0_filtered.json
```

### Comando MANUAL paso a paso:

```bash
# 1. Obtener versión CORRECTA
git fetch upstream --tags
git checkout v1.38.0  # ← Esta es la versión correcta para 0.59b0

# 2. Capturar y validar spans de tu cliente
just capture-validate ./model analisis_cliente_0.59b0.json 4317 180

# 3. Filtrar violations conocidas del SDK lag
just filter-sdk-lag analisis_cliente_0.59b0.json

# 4. Volver a main cuando termines
git checkout main
```

### ¿Cómo se encontró este mapeo?

```bash
# Query a GitHub API para obtener releases de opentelemetry-python-contrib
curl -s "https://api.github.com/repos/open-telemetry/opentelemetry-python-contrib/releases" \
  | jq -r '.[] | select(.tag_name | contains("0.59b0")) | "\(.tag_name) - \(.name)"'
# Resultado: v0.59b0 - Version 1.38.0/0.59b0
```

### Ejemplo práctico completo:

#### Situación: Tu cliente 0.59b0 usa `deployment.environment` (deprecado en v1.27.0)

```bash
# 1. Ir a la versión exacta que corresponde a tu cliente 0.59b0
git checkout v1.38.0

# 2. Configurar tu aplicación para enviar spans
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"

# 3. En una terminal, iniciar la captura con validación
just capture-validate ./model spans_cliente_0.59b0.json 4317 120

# 4. En otra terminal, ejecutar tu aplicación
python tu_app_con_0.59b0.py

# 5. Revisar resultados (después de que termine la captura)
jq '.violations | length' spans_cliente_0.59b0.json  # número de violations
jq '.violations[] | select(.attribute == "deployment.environment")' spans_cliente_0.59b0.json

# 6. Volver a main
git checkout main
```

#### ¿Qué verás en los resultados?

```json
{
  "violations": [
    {
      "type": "deprecated_attribute",
      "attribute": "deployment.environment",
      "message": "Replaced by deployment.environment.name",
      "replacement": "deployment.environment.name"
    }
  ]
}
```

#### ¿Qué hacer con los atributos deprecados del SDK?

**Opción 1**: Esperar a que el SDK se actualice
**Opción 2**: Usar un processor personalizado para mapear atributos
**Opción 3**: Para análisis, filtrar los deprecados conocidos del SDK

### El problema del desfase SDK vs Especificaciones

**Tu caso específico**: `deployment.environment` → `deployment.environment.name`

- **Cambio en especificaciones**: v1.27.0 (2023)
- **Tu SDK Python**: 0.59b0 → usa v1.38.0 (Oct 2025) 
- **El problema**: Aunque 0.59b0 implementa v1.38.0, el SDK Python aún no actualizó este atributo específico

#### ¿Cómo validar considerando este desfase?

**Opción 1: Usar el workflow automático (RECOMENDADO)**
```bash
# Todo en un comando - automático y completo
just capture-and-filter-sdk v1.38.0 mi_analisis.json 4317
```

**Opción 2: Manual con filtrado inteligente**
```bash
# 1. Validar contra la versión que SÍ usa tu SDK
git checkout v1.38.0
just capture-validate ./model spans_real.json 4317 120

# 2. Filtrar violations usando el script especializado
just filter-sdk-lag spans_real.json

# 3. Ver resumen de violations filtradas
jq '.summary' spans_real_filtered.json
```

**Opción 3: Filtrado manual básico (para casos específicos)**
```bash
# Solo filtrar deployment.environment conocido
jq '.violations[] | select(.type != "deprecated_attribute" or .attribute != "deployment.environment")' spans_real.json

# Ver estadísticas rápidas
jq '{
  total: (.violations | length),
  real_issues: ([.violations[] | select(.type != "deprecated_attribute")] | length),
  known_deprecated: ([.violations[] | select(.type == "deprecated_attribute")] | length)
}' spans_real.json
```

### ¿Por qué este mapeo es correcto?

El release **`v0.59b0 - Version 1.38.0/0.59b0`** en opentelemetry-python-contrib indica que la versión 0.59b0 del paquete Python **intenta** implementar semantic conventions v1.38.0, pero algunos atributos pueden estar desfasados debido a actualizaciones lentas del SDK.

*Fuente: [opentelemetry-python-contrib releases](https://github.com/open-telemetry/opentelemetry-python-contrib/releases)*