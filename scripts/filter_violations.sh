#!/bin/bash
# Script wrapper para filtrar violations de SDK lag conocidas

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER_SCRIPT="$SCRIPT_DIR/filter_sdk_lag.py"

usage() {
    echo "Usage: $0 <spans_analysis.json>"
    echo ""
    echo "Filtra violations conocidas del desfase entre SDKs y semantic conventions."
    echo "Útil para separar problemas reales de tu app vs limitations conocidas del SDK."
    echo ""
    echo "Ejemplo:"
    echo "  $0 spans_cliente_0.59b0.json"
    echo ""
    echo "Genera:"
    echo "  - spans_cliente_0.59b0_filtered.json: Análisis completo filtrado"
    echo "  - Resumen en consola con violations categorizadas"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

INPUT_FILE="$1"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "❌ Error: File $INPUT_FILE not found"
    exit 1
fi

if [[ ! "$INPUT_FILE" =~ \.json$ ]]; then
    echo "❌ Error: Input file must be a JSON file"
    exit 1
fi

echo "🚀 Filtrando violations conocidas del SDK lag..."
echo "📄 Input: $INPUT_FILE"

# Verificar que Python esté disponible
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found. Please install Python 3."
    exit 1
fi

# Ejecutar el filtro
python3 "$FILTER_SCRIPT" "$INPUT_FILE"

OUTPUT_FILE="${INPUT_FILE%.*}_filtered.json"
echo ""
echo "✅ Filtrado completado!"
echo "📊 Ver resultados detallados:"
echo "   jq '.summary' $OUTPUT_FILE"
echo ""
echo "🔍 Ver solo violations reales:"
echo "   jq '.filtered_results.real_violations' $OUTPUT_FILE"
echo ""
echo "⏳ Ver SDK lag conocido:"
echo "   jq '.filtered_results.sdk_lag_violations' $OUTPUT_FILE"