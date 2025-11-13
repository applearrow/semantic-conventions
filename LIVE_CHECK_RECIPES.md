# Nuevas recetas Just para captura de spans

## Recetas agregadas para generar registry desde spans reales:

### 1. `capture-spans` - Captura básica de spans
```bash
# Uso básico (puerto 4317, 30 segundos de timeout)
just capture-spans

# Personalizado 
just capture-spans mi_analisis.json 4318 60
```

**Parámetros:**
- `output`: Archivo donde guardar el análisis (default: "captured_spans.json")
- `port`: Puerto OTLP para escuchar (default: "4317") 
- `timeout`: Segundos de inactividad antes de parar (default: "30")

### 2. `capture-validate` - Captura CON validación contra registry existente
```bash
# Validar spans contra semantic-search registry
just capture-validate ./model/semantic-search analysis.json

# Con puerto y timeout personalizados
just capture-validate ./mi_registry mi_analisis.json 4318 45
```

**Parámetros:**
- `registry`: Ruta al registry para validar contra
- `output`: Archivo de salida del análisis
- `port`: Puerto OTLP (default: "4317")
- `timeout`: Timeout en segundos (default: "30")

### 3. `quick-capture` - Inicio rápido
```bash
# Captura por 60 segundos en puerto 4317
just quick-capture
```

Guarda automáticamente en `captured_telemetry.json`

## Flujo de trabajo recomendado:

### Para crear nuevo registry:
1. **Capturar spans**: `just capture-spans spans_de_mi_app.json 4317 60`
2. **Ejecutar tu app** para que envíe spans a localhost:4317
3. **Analizar resultado** en spans_de_mi_app.json
4. **Crear registry manual** basado en atributos encontrados
5. **Validar**: `weaver registry check -r mi_nuevo_registry`

### Para validar app existente:
1. **Capturar y validar**: `just capture-validate ./mi_registry analysis.json`
2. **Ejecutar tu app** 
3. **Revisar violations** en analysis.json
4. **Corregir registry o app** según sea necesario

## Control del proceso:

- **Parar manualmente**: Ctrl+C
- **Parar via HTTP**: `curl http://localhost:4320/stop`
- **Auto-stop**: Después del timeout configurado

## Configuración de tu aplicación:

Tu app debe enviar spans vía OTLP gRPC al puerto especificado:

```bash
# Ejemplo con variables de entorno
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"

# Luego ejecutar tu aplicación
python mi_app.py
```

## Formato de salida:

El análisis se guarda en formato JSON con:
- **Violations** encontradas
- **Atributos** por span
- **Recomendaciones** de mejoras
- **Estadísticas** de uso