
# scan otel services

### What it does

The `scan_otel_services.sh` script scans localhost for common OpenTelemetry service ports and reports which services are active. It performs intelligent analysis to identify:

- **OTLP services** (both gRPC and HTTP receivers)
- **OpenTelemetry Collector** endpoints (metrics, health, diagnostics)
- **Jaeger services** (collectors, agents, UI)
- **Zipkin collectors**

The script provides detailed analysis including:
- Service type detection with protocol verification
- Health endpoint checking
- gRPC service reflection analysis
- HTTP endpoint validation
- Configuration suggestions and connection commands

### How to call it

```bash
# Make the script executable (if needed)
chmod +x scripts/scan_otel_services.sh

# Run the scan
./scripts/scan_otel_services.sh
```

The script will:
1. Scan all common OpenTelemetry ports (4317, 4318, 8888, 8889, 13133, 14250, 14268, 6831, 6832, 9411, 16686, 14269, 5778)
2. Analyze each active port to determine the service type
3. Provide a summary of detected services
4. Suggest connection commands and environment variables
5. Display available web interfaces

**Requirements:**
- `curl` for HTTP endpoint testing
- `grpcurl` for detailed gRPC analysis (optional but recommended)
- Network access to localhost

**Example output:**
```
🔍 Escaneando puertos comunes de OpenTelemetry en localhost...
==================================================

📋 Puertos encontrados activos:
--------------------------------
✅ Puerto 4317 (gRPC OTLP): 🎯 OTLP gRPC activo - OpenTelemetry Collector (gRPC receiver)
✅ Puerto 4318 (HTTP OTLP): 🎯 OTLP HTTP activo - OpenTelemetry Collector (HTTP receiver)
✅ Puerto 8888 (Prometheus metrics): 📊 Prometheus metrics activo - OpenTelemetry Collector (metrics endpoint)

📊 Resumen del escaneo:
======================
🔍 Puertos escaneados: 13
✅ Puertos activos: 3

🎯 Servicios detectados:
------------------------
  • OTLP gRPC con 3 servicios (puerto 4317)
  • OTLP HTTP activo (puerto 4318)
  • Prometheus metrics (puerto 8888)
```