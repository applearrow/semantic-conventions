#!/bin/bash

# Puertos comunes de OpenTelemetry Collector
COMMON_PORTS=(4317 4318 8888 8889 13133 14250 14268 6831 6832 9411)

echo "Probando puertos comunes de OpenTelemetry Collector..."

for port in "${COMMON_PORTS[@]}"; do
    echo -n "Puerto $port: "
    
    # Probar conexión TCP
    if timeout 2 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        echo -n "ABIERTO - "
        
        # Probar si es HTTP
        if curl -s --max-time 2 "http://localhost:$port/health" >/dev/null 2>&1; then
            echo "HTTP (posible OTLP/HTTP)"
        elif curl -s --max-time 2 "http://localhost:$port/metrics" >/dev/null 2>&1; then
            echo "HTTP (posible métricas/health)"
        else
            # Podría ser gRPC
            echo "Posible gRPC o protocolo binario"
        fi
    else
        echo "CERRADO"
    fi
done
