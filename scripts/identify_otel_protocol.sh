#!/bin/bash

PORT=${1:-4317}
HOST=${2:-localhost}

echo "Analizando protocolo en $HOST:$PORT..."

# 1. Verificar si el puerto está abierto
if ! timeout 2 bash -c "</dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "❌ Puerto $PORT no está abierto en $HOST"
    exit 1
fi

echo "✅ Puerto $PORT está abierto"

# 2. Probar HTTP endpoints comunes
echo ""
echo "🔍 Probando endpoints HTTP..."

# Health check
if curl -s --max-time 3 "http://$HOST:$PORT/health" 2>/dev/null | grep -q "Server available"; then
    echo "✅ HTTP Health endpoint responde - Probablemente OTLP/HTTP"
elif curl -s --max-time 3 "http://$HOST:$PORT/v1/traces" -X POST -H "Content-Type: application/json" -d '{}' 2>/dev/null; then
    echo "✅ OTLP/HTTP endpoint traces responde"
elif curl -s --max-time 3 "http://$HOST:$PORT/metrics" 2>/dev/null | grep -q "#"; then
    echo "✅ Prometheus metrics endpoint - Puerto de métricas/health"
else
    echo "❓ No responde a endpoints HTTP comunes"
fi

# 3. Probar gRPC con grpcurl
echo ""
echo "🔍 Probando gRPC..."

grpc_services=$(grpcurl -plaintext "$HOST:$PORT" list 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$grpc_services" ]; then
    echo "✅ Servidor gRPC detectado"
    
    # Contar servicios
    service_count=$(echo "$grpc_services" | wc -l | tr -d ' ')
    echo "📊 Servicios gRPC encontrados: $service_count"
    
    # Verificar servicios específicos
    if echo "$grpc_services" | grep -q "opentelemetry"; then
        echo "🎯 Servicios OpenTelemetry detectados:"
        echo "$grpc_services" | grep "opentelemetry" | sed 's/^/    • /'
    fi
    
    if echo "$grpc_services" | grep -q "jaeger"; then
        echo "🔍 Servicios Jaeger detectados:"
        echo "$grpc_services" | grep "jaeger" | sed 's/^/    • /'
    fi
    
    echo ""
    echo "📋 Todos los servicios gRPC:"
    echo "$grpc_services" | sed 's/^/    • /'
    
else
    echo "❓ No es gRPC o no responde a reflection"
fi

# 4. Analizar headers HTTP
echo ""
echo "🔍 Analizando headers HTTP..."
curl -sI --max-time 3 "http://$HOST:$PORT/" 2>/dev/null | head -5

echo ""
echo "📋 Resumen de puertos comunes OpenTelemetry:"
echo "  4317: gRPC OTLP (por defecto)"  
echo "  4318: HTTP OTLP (por defecto)"
echo "  8888: Prometheus metrics"
echo "  8889: Health/diagnostics"
echo "  13133: Health check"
echo "  14250: Jaeger gRPC"
echo "  14268: Jaeger HTTP"