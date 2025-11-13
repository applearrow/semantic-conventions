#!/bin/bash

# Script para escanear todos los puertos comunes de OpenTelemetry
# y reportar qué servicios están activos

echo "🔍 Escaneando puertos comunes de OpenTelemetry en localhost..."
echo "=================================================="
echo ""

# Definir puertos con su información (compatible con macOS)
get_port_info() {
    case $1 in
        4317) echo "gRPC OTLP|OpenTelemetry Collector (gRPC receiver)" ;;
        4318) echo "HTTP OTLP|OpenTelemetry Collector (HTTP receiver)" ;;
        8888) echo "Prometheus metrics|OpenTelemetry Collector (metrics endpoint)" ;;
        8889) echo "Health/diagnostics|OpenTelemetry Collector (health endpoint)" ;;
        13133) echo "Health check|OpenTelemetry Collector (health check)" ;;
        14250) echo "Jaeger gRPC|Jaeger Collector (gRPC)" ;;
        14268) echo "Jaeger HTTP|Jaeger Collector (HTTP)" ;;
        6831) echo "Jaeger UDP|Jaeger Agent (UDP compact)" ;;
        6832) echo "Jaeger UDP|Jaeger Agent (UDP binary)" ;;
        9411) echo "Zipkin HTTP|Zipkin Collector" ;;
        16686) echo "Jaeger UI|Jaeger Query Service (Web UI)" ;;
        14269) echo "Jaeger Admin|Jaeger Collector (Admin port)" ;;
        5778) echo "Jaeger Config|Jaeger Agent (Config endpoint)" ;;
        *) echo "Unknown|Unknown service" ;;
    esac
}

# Lista de puertos a escanear
PORTS=(4317 4318 8888 8889 13133 14250 14268 6831 6832 9411 16686 14269 5778)

# Contadores
total_ports=${#PORTS[@]}
active_ports=0
active_services=()

echo "📋 Puertos encontrados activos:"
echo "--------------------------------"

for port in "${PORTS[@]}"; do
    # Extraer información del puerto
    port_info=$(get_port_info $port)
    IFS='|' read -r protocol service <<< "$port_info"
    
    # Verificar si el puerto está abierto
    if timeout 2 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        active_ports=$((active_ports + 1))
        
        echo -n "✅ Puerto $port ($protocol): "
        
        # Analizar qué tipo de servicio es
        case $port in
            4317)
                # Probar gRPC OTLP con grpcurl
                echo -n "🔍 Analizando gRPC... "
                grpc_services=$(grpcurl -plaintext -max-time 3 localhost:$port list 2>/dev/null)
                grpc_exit_code=$?
                
                if [ $grpc_exit_code -eq 0 ] && echo "$grpc_services" | grep -q "opentelemetry"; then
                    echo ""
                    echo "🎯 OTLP gRPC activo - $service"
                    otlp_services=$(echo "$grpc_services" | grep "opentelemetry" | wc -l | tr -d ' ')
                    echo "      └─ Servicios OTLP detectados: $otlp_services"
                    active_services+=("OTLP gRPC con $otlp_services servicios (puerto $port)")
                elif [ $grpc_exit_code -eq 0 ] && [ -n "$grpc_services" ]; then
                    echo ""
                    service_count=$(echo "$grpc_services" | wc -l | tr -d ' ')
                    echo "⚠️  gRPC activo pero sin servicios OTLP - $service"
                    echo "      └─ Servicios gRPC encontrados: $service_count"
                    active_services+=("gRPC genérico con $service_count servicios (puerto $port)")
                elif [ $grpc_exit_code -eq 0 ]; then
                    echo ""
                    echo "⚠️  gRPC responde pero sin reflection - $service"
                    echo "      └─ Posible OTLP sin reflection habilitado"
                    active_services+=("Posible OTLP gRPC sin reflection (puerto $port)")
                else
                    echo ""
                    # Intentar detectar si es HTTP en puerto gRPC
                    if curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null | grep -q "404\|not found\|error"; then
                        echo "❓ Puerto responde HTTP en vez de gRPC - $service"
                        echo "      └─ Posible configuración incorrecta (HTTP en puerto gRPC)"
                        active_services+=("HTTP en puerto gRPC 4317 (configuración incorrecta)")
                    else
                        # Último intento: podría ser gRPC sin reflection
                        echo "❓ Posible gRPC sin reflection o protocolo propietario - $service"
                        echo "      └─ Puerto estándar OTLP pero no responde a análisis automático"
                        echo "      └─ Sugerencia: Probar conexión OTLP directa"
                        active_services+=("Posible OTLP gRPC sin reflection (puerto $port)")
                    fi
                fi
                ;;
            4318)
                # Probar HTTP OTLP
                echo -n "🔍 Analizando HTTP... "
                
                # Probar endpoint OTLP específico
                otlp_response=$(curl -s --max-time 3 -w "%{http_code}" "http://localhost:$port/v1/traces" -X POST -H "Content-Type: application/json" -d '{}' 2>/dev/null)
                http_code="${otlp_response: -3}"
                
                if [ "$http_code" = "200" ] || [ "$http_code" = "400" ] || [ "$http_code" = "405" ]; then
                    echo ""
                    echo "🎯 OTLP HTTP activo - $service"
                    echo "      └─ Endpoint /v1/traces responde (código: $http_code)"
                    active_services+=("OTLP HTTP activo (puerto $port)")
                elif curl -s --max-time 2 "http://localhost:$port/health" 2>/dev/null | grep -q "available\|ok\|healthy"; then
                    echo ""
                    echo "🎯 HTTP con health endpoint - $service"
                    echo "      └─ Health endpoint disponible"
                    active_services+=("OTLP HTTP con health (puerto $port)")
                elif curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null >/dev/null; then
                    echo ""
                    echo "📡 Servidor HTTP genérico - $service"
                    echo "      └─ Responde HTTP pero sin endpoints OTLP conocidos"
                    active_services+=("HTTP genérico en puerto OTLP (puerto $port)")
                else
                    echo ""
                    echo "❓ Puerto abierto pero no responde HTTP - $service"
                    echo "      └─ Posible protocolo no HTTP"
                    active_services+=("Puerto 4318 abierto (no HTTP)")
                fi
                ;;
            8888)
                # Probar Prometheus metrics
                if curl -s --max-time 2 "http://localhost:$port/metrics" 2>/dev/null | grep -q "# HELP\|# TYPE"; then
                    echo "📊 Prometheus metrics activo - $service"
                    active_services+=("Prometheus metrics (puerto $port)")
                else
                    echo "📡 HTTP en puerto de métricas - $service"
                    active_services+=("HTTP métricas (puerto $port)")
                fi
                ;;
            8889|13133)
                # Probar health endpoints
                if curl -s --max-time 2 "http://localhost:$port/health" 2>/dev/null | grep -q "available\|ok\|healthy"; then
                    echo "💚 Health endpoint activo - $service"
                    active_services+=("Health endpoint (puerto $port)")
                else
                    echo "📡 HTTP en puerto de health - $service"
                    active_services+=("HTTP health (puerto $port)")
                fi
                ;;
            14250)
                # Jaeger gRPC con grpcurl
                echo -n "🔍 Analizando gRPC... "
                grpc_services=$(grpcurl -plaintext -max-time 3 localhost:$port list 2>/dev/null)
                grpc_exit_code=$?
                
                if [ $grpc_exit_code -eq 0 ] && echo "$grpc_services" | grep -q "jaeger"; then
                    echo ""
                    echo "🔍 Jaeger gRPC activo - $service"
                    jaeger_services=$(echo "$grpc_services" | grep "jaeger" | wc -l | tr -d ' ')
                    echo "      └─ Servicios Jaeger detectados: $jaeger_services"
                    active_services+=("Jaeger gRPC con $jaeger_services servicios (puerto $port)")
                elif [ $grpc_exit_code -eq 0 ] && [ -n "$grpc_services" ]; then
                    echo ""
                    service_count=$(echo "$grpc_services" | wc -l | tr -d ' ')
                    echo "📡 gRPC activo en puerto Jaeger - $service"
                    echo "      └─ Servicios gRPC encontrados: $service_count (no Jaeger)"
                    active_services+=("gRPC genérico en puerto Jaeger con $service_count servicios (puerto $port)")
                elif [ $grpc_exit_code -eq 0 ]; then
                    echo ""
                    echo "⚠️  gRPC responde pero sin reflection - $service"
                    echo "      └─ Posible Jaeger sin reflection habilitado"
                    active_services+=("Posible Jaeger gRPC sin reflection (puerto $port)")
                else
                    echo ""
                    echo "❌ Puerto abierto pero no es gRPC - $service"
                    echo "      └─ Protocolo desconocido o no disponible"
                    active_services+=("Puerto 14250 abierto (no gRPC)")
                fi
                ;;
            14268|14269)
                # Jaeger HTTP
                if curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null | grep -qi "jaeger"; then
                    echo "🔍 Jaeger HTTP activo - $service"
                    active_services+=("Jaeger HTTP (puerto $port)")
                else
                    echo "📡 HTTP en puerto Jaeger - $service"
                    active_services+=("HTTP Jaeger probable (puerto $port)")
                fi
                ;;
            16686)
                # Jaeger UI
                if curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null | grep -qi "jaeger\|search\|trace"; then
                    echo "🌐 Jaeger UI activo - $service"
                    active_services+=("Jaeger UI (puerto $port)")
                else
                    echo "🌐 Web UI en puerto Jaeger - $service"
                    active_services+=("Web UI Jaeger (puerto $port)")
                fi
                ;;
            9411)
                # Zipkin
                if curl -s --max-time 2 "http://localhost:$port/api/v2/services" 2>/dev/null | grep -q "\[\]"; then
                    echo "📦 Zipkin activo - $service"
                    active_services+=("Zipkin (puerto $port)")
                else
                    echo "📡 HTTP en puerto Zipkin - $service"
                    active_services+=("HTTP Zipkin probable (puerto $port)")
                fi
                ;;
            6831|6832)
                # Jaeger UDP (más difícil de probar)
                echo "📡 Puerto UDP Jaeger detectado - $service"
                active_services+=("Jaeger UDP Agent (puerto $port)")
                ;;
            5778)
                # Jaeger Agent config
                if curl -s --max-time 2 "http://localhost:$port/sampling" 2>/dev/null | grep -q "strategies"; then
                    echo "⚙️  Jaeger Agent config activo - $service"
                    active_services+=("Jaeger Agent config (puerto $port)")
                else
                    echo "📡 HTTP en puerto config Jaeger - $service"
                    active_services+=("HTTP config Jaeger (puerto $port)")
                fi
                ;;
        esac
    fi
done

echo ""
echo "📊 Resumen del escaneo:"
echo "======================"
echo "🔍 Puertos escaneados: $total_ports"
echo "✅ Puertos activos: $active_ports"

if [ $active_ports -gt 0 ]; then
    echo ""
    echo "🎯 Servicios detectados:"
    echo "------------------------"
    for service in "${active_services[@]}"; do
        echo "  • $service"
    done
    
    echo ""
    echo "💡 Comandos sugeridos para conectar:"
    echo "------------------------------------"
    
    # Generar comandos de ejemplo basados en servicios encontrados
    for service in "${active_services[@]}"; do
        if [[ $service == *"OTLP gRPC"* ]]; then
            echo "  # Para OTLP gRPC:"
            echo "  export OTEL_EXPORTER_OTLP_ENDPOINT=\"http://localhost:4317\""
        elif [[ $service == *"OTLP HTTP"* ]]; then
            echo "  # Para OTLP HTTP:"
            echo "  export OTEL_EXPORTER_OTLP_ENDPOINT=\"http://localhost:4318\""
        elif [[ $service == *"Jaeger gRPC"* ]]; then
            echo "  # Para Jaeger gRPC:"
            echo "  export OTEL_EXPORTER_JAEGER_ENDPOINT=\"http://localhost:14250\""
        elif [[ $service == *"Jaeger HTTP"* ]]; then
            echo "  # Para Jaeger HTTP:"
            echo "  export OTEL_EXPORTER_JAEGER_ENDPOINT=\"http://localhost:14268/api/traces\""
        elif [[ $service == *"Zipkin"* ]]; then
            echo "  # Para Zipkin:"
            echo "  export OTEL_EXPORTER_ZIPKIN_ENDPOINT=\"http://localhost:9411/api/v2/spans\""
        fi
    done
    

    
    # Mostrar UIs disponibles
    has_ui=false
    for service in "${active_services[@]}"; do
        if [[ $service == *"Jaeger UI"* ]]; then
            if [ "$has_ui" = false ]; then
                echo ""
                echo "🌐 Interfaces web disponibles:"
                echo "------------------------------"
                has_ui=true
            fi
            echo "  • Jaeger UI: http://localhost:16686"
        fi
    done
    
else
    echo ""
    echo "❌ No se detectaron servicios OpenTelemetry activos"
    echo ""
    echo "💡 Para iniciar un OpenTelemetry Collector:"
    echo "   docker run -p 4317:4317 -p 4318:4318 -p 8888:8888 otel/opentelemetry-collector-contrib:latest"
fi

echo ""
echo "⚠️  Notas importantes:"
echo "---------------------"
echo "- ✅ grpcurl disponible - análisis gRPC detallado activado"
echo "- 🔍 'gRPC sin reflection' puede indicar servicio OTLP/Jaeger funcional"
echo "- 📡 'HTTP genérico' puede ser OTLP que responde de forma inesperada"
echo "- 🚨 'HTTP en puerto gRPC' indica posible error de configuración"
echo "- 🔧 Para diagnosticar: grpcurl -plaintext localhost:PUERTO list"
echo "- 🧪 Para probar OTLP HTTP: curl -X POST http://localhost:4318/v1/traces"