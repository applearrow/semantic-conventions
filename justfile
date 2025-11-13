# Constants
REGISTRIES_DIR := './registries'
MODEL_DIR := './model/semantic-search'

@_:
    just --list

# Check semantic-search model with weaver
check:
    weaver registry check -r {{MODEL_DIR}}

# Check with future validation rules enabled (recommended for new registries)
check-future:
    weaver registry check -r {{MODEL_DIR}} --future

# Check with policy validation
check-policies:
    weaver registry check -r {{MODEL_DIR}} -p ./policies

# Check the full model directory
check-all:
    weaver registry check -r ./model

# Check with debug output
check-debug:
    weaver registry check -r {{MODEL_DIR}} --debug

# Generate artifacts for a specific target
generate target="markdown" output="semantic-search-registry":
    weaver registry generate -r {{MODEL_DIR}} {{target}} {{REGISTRIES_DIR}}/{{output}}

# Resolve the registry and output to stdout
resolve output="semantic-search-registry.yaml":
    weaver registry resolve -r {{MODEL_DIR}} -o {{REGISTRIES_DIR}}/{{output}}

# Resolve to JSON format
resolve-json output="resolved.json":
    weaver registry resolve -r {{MODEL_DIR}} -f json -o {{REGISTRIES_DIR}}/{{output}}

# Search the registry interactively
search:
    weaver registry search -r {{MODEL_DIR}}

# Search for specific term
search-term term:
    weaver registry search -r {{MODEL_DIR}} "{{term}}"

# Get registry statistics
stats:
    weaver registry stats -r {{MODEL_DIR}}

# Generate JSON schema
json-schema output="schema.json":
    weaver registry json-schema -o {{REGISTRIES_DIR}}/{{output}}

# Compare with baseline registry
diff baseline:
    weaver registry diff -r {{MODEL_DIR}} --baseline-registry {{baseline}}

# Update markdown files
update-markdown target markdown_dir="docs":
    weaver registry update-markdown -r {{MODEL_DIR}} --target {{target}} {{markdown_dir}}

# Emit example signals to OTLP receiver
emit:
    weaver registry emit -r {{MODEL_DIR}}

# Capture spans from real application to analyze and generate registry
capture-spans output="captured_spans.json" port="4317" timeout="30":
    @echo "Starting OTLP listener on port {{port}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be saved to {{REGISTRIES_DIR}}/{{output}}"
    @echo "Will stop after {{timeout}} seconds of inactivity"
    @echo "Press Ctrl+C to stop manually or use curl http://localhost:4320/stop"
    weaver registry live-check \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --format json \
        --output {{REGISTRIES_DIR}}/{{output}} \
        --inactivity-timeout {{timeout}} \
        --no-stream

# Capture spans with custom registry validation (for existing apps)
capture-validate registry output="analysis.json" port="4317" timeout="30":
    @echo "Starting span capture with validation against {{registry}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be saved to {{REGISTRIES_DIR}}/{{output}}"
    weaver registry live-check \
        --registry {{registry}} \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --format json \
        --output {{REGISTRIES_DIR}}/{{output}} \
        --inactivity-timeout {{timeout}} \
        --no-stream

# Quick start: capture spans for 60 seconds and save results
quick-capture:
    just capture-spans captured_telemetry.json 4317 60

