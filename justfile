# Constants
REGISTRIES_DIR := './registries'
MODEL_DIR := './model/semantic-search'
CAPTURE_DIR := './captured'
DEFAULT_TIMEOUT := '120'

@_:
    just --list

# ================================
# VALIDATION AND CHECKING
# ================================

# Check semantic-search model with weaver
[group('validation')]
check:
    weaver registry check -r {{MODEL_DIR}}

# Check with future validation rules enabled (recommended for new registries)
[group('validation')]
check-future:
    weaver registry check -r {{MODEL_DIR}} --future

# Check with policy validation
[group('validation')]
check-policies:
    weaver registry check -r {{MODEL_DIR}} -p ./policies

# Check the full model directory
[group('validation')]
check-all:
    weaver registry check -r ./model

# Check with debug output
[group('validation')]
check-debug:
    weaver registry check -r {{MODEL_DIR}} --debug

# ================================
# GENERATION AND RESOLUTION
# ================================

# Generate artifacts for a specific target
[group('generation')]
generate target="markdown" output="semantic-search-registry":
    weaver registry generate -r {{MODEL_DIR}} {{target}} {{REGISTRIES_DIR}}/{{output}}

# Resolve the registry and output to stdout
[group('generation')]
resolve output="semantic-search-registry.yaml":
    weaver registry resolve -r {{MODEL_DIR}} -o {{REGISTRIES_DIR}}/{{output}}

# Resolve to JSON format
[group('generation')]
resolve-json output="resolved.json":
    weaver registry resolve -r {{MODEL_DIR}} -f json -o {{REGISTRIES_DIR}}/{{output}}

# Generate JSON schema
[group('generation')]
json-schema output="schema.json":
    weaver registry json-schema -o {{REGISTRIES_DIR}}/{{output}}

# ================================
# SEARCH AND ANALYSIS
# ================================

# Search the registry interactively
[group('analysis')]
search:
    weaver registry search -r {{MODEL_DIR}}

# Search for specific term
[group('analysis')]
search-term term:
    weaver registry search -r {{MODEL_DIR}} "{{term}}"

# Get registry statistics
[group('analysis')]
stats:
    weaver registry stats -r {{MODEL_DIR}}

# Compare with baseline registry
[group('analysis')]
diff baseline:
    weaver registry diff -r {{MODEL_DIR}} --baseline-registry {{baseline}}

# ================================
# DOCUMENTATION AND MAINTENANCE
# ================================

# Update markdown files
[group('maintenance')]
update-markdown target markdown_dir="docs":
    weaver registry update-markdown -r {{MODEL_DIR}} --target {{target}} {{markdown_dir}}

# ================================
# TESTING AND DEVELOPMENT
# ================================

# Emit example signals to OTLP receiver
[group('development')]
emit:
    weaver registry emit -r {{MODEL_DIR}}

# ================================
# LIVE CAPTURE AND ANALYSIS
# ================================

# Quick start: capture spans and save results
[group('capture')]
quick-capture:
    just capture-spans captured_telemetry.json 4317

# Capture spans from real application to analyze and generate registry
[group('capture')]
capture-spans output="spans.json" port="4317":
    @echo "Starting OTLP listener on port {{port}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be saved to {{CAPTURE_DIR}}/{{output}}"
    @echo "Will stop after {{DEFAULT_TIMEOUT}} seconds of inactivity"
    @echo "Press Ctrl+C to stop manually or use curl http://localhost:4320/stop"
    weaver registry live-check \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --format json \
        --output {{CAPTURE_DIR}}/{{output}} \
        --inactivity-timeout {{DEFAULT_TIMEOUT}} \
        --no-stream

# Capture spans with custom registry validation (for existing apps)
[group('capture')]
capture-validate registry output="analysis.json" port="4317":
    @echo "Starting span capture with validation against {{registry}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be saved to {{CAPTURE_DIR}}/{{output}}"
    weaver registry live-check \
        --registry {{registry}} \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --format json \
        --output {{CAPTURE_DIR}}/{{output}} \
        --inactivity-timeout {{DEFAULT_TIMEOUT}} \
        --no-stream

