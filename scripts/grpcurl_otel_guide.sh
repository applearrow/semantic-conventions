#!/bin/bash

# Script con comandos grpcurl útiles para OpenTelemetry

echo "🔧 Comandos grpcurl útiles para OpenTelemetry"
echo "============================================="
echo ""

echo "📋 Comandos básicos de inspección:"
echo "----------------------------------"
echo ""
echo "# Listar todos los servicios en un puerto gRPC:"
echo "grpcurl -plaintext localhost:4317 list"
echo ""
echo "# Describir un servicio específico:"
echo "grpcurl -plaintext localhost:4317 describe opentelemetry.proto.collector.trace.v1.TraceService"
echo ""
echo "# Ver métodos de un servicio:"
echo "grpcurl -plaintext localhost:4317 list opentelemetry.proto.collector.trace.v1.TraceService"
echo ""

echo "🎯 Servicios OpenTelemetry comunes:"
echo "-----------------------------------"
echo ""
echo "## Servicios OTLP (puerto 4317):"
echo "- opentelemetry.proto.collector.trace.v1.TraceService"
echo "- opentelemetry.proto.collector.metrics.v1.MetricsService"  
echo "- opentelemetry.proto.collector.logs.v1.LogsService"
echo ""
echo "## Comandos para inspeccionar OTLP:"
echo "grpcurl -plaintext localhost:4317 list | grep opentelemetry"
echo "grpcurl -plaintext localhost:4317 describe opentelemetry.proto.collector.trace.v1.TraceService.Export"
echo ""

echo "🔍 Servicios Jaeger comunes:"
echo "----------------------------"
echo ""
echo "## Servicios Jaeger (puerto 14250):"
echo "- jaeger.api_v2.CollectorService"
echo "- jaeger.api_v2.SamplingManager"
echo ""
echo "## Comandos para inspeccionar Jaeger:"
echo "grpcurl -plaintext localhost:14250 list | grep jaeger"
echo "grpcurl -plaintext localhost:14250 describe jaeger.api_v2.CollectorService"
echo ""

echo "🧪 Comandos para probar conectividad:"
echo "-------------------------------------"
echo ""
echo "# Probar si un servicio gRPC está disponible (simple ping):"
echo "grpcurl -plaintext localhost:4317 list >/dev/null 2>&1 && echo \"✅ gRPC disponible\" || echo \"❌ gRPC no disponible\""
echo ""
echo "# Verificar servicios OTLP específicos:"
echo "grpcurl -plaintext localhost:4317 list 2>/dev/null | grep -q \"opentelemetry.proto.collector.trace.v1.TraceService\" && echo \"✅ Trace service disponible\" || echo \"❌ Trace service no disponible\""
echo ""

echo "📡 Testear con datos de ejemplo:"
echo "--------------------------------"
echo ""
echo "# NOTA: Estos comandos requieren datos en formato protobuf"
echo "# Para generar datos de prueba, usar herramientas como otel-cli o telemetrygen"
echo ""
echo "# Ejemplo conceptual (requiere payload válido):"
echo "# grpcurl -plaintext -d '{\"resource_spans\":[]}' localhost:4317 opentelemetry.proto.collector.trace.v1.TraceService/Export"
echo ""

echo "🔧 Funciones útiles para tu shell:"
echo "----------------------------------"
echo ""
cat << 'EOF'
# Agregar estas funciones a tu ~/.zshrc o ~/.bashrc:

# Función para listar servicios gRPC rápidamente
otel-grpc-list() {
    local port=${1:-4317}
    echo "🔍 Servicios gRPC en localhost:$port:"
    grpcurl -plaintext localhost:$port list 2>/dev/null || echo "❌ No disponible"
}

# Función para verificar OTLP
otel-check() {
    local port=${1:-4317}
    if grpcurl -plaintext localhost:$port list 2>/dev/null | grep -q "opentelemetry"; then
        echo "✅ OTLP gRPC disponible en puerto $port"
        grpcurl -plaintext localhost:$port list | grep opentelemetry
    else
        echo "❌ OTLP gRPC no disponible en puerto $port"
    fi
}

# Función para verificar Jaeger
jaeger-check() {
    local port=${1:-14250}
    if grpcurl -plaintext localhost:$port list 2>/dev/null | grep -q "jaeger"; then
        echo "✅ Jaeger gRPC disponible en puerto $port"
        grpcurl -plaintext localhost:$port list | grep jaeger
    else
        echo "❌ Jaeger gRPC no disponible en puerto $port"
    fi
}
EOF

echo ""
echo "💡 Para usar las funciones, ejecuta:"
echo "    source ~/.zshrc"
echo "    otel-check"
echo "    jaeger-check"
echo "    otel-grpc-list 4317"