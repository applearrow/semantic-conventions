# Constants
REGISTRIES_DIR := './registries'
MODEL_DIR := './model/semantic-search'
CAPTURE_DIR := './captured'
DEFAULT_TIMEOUT := '60'

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
generate target="markdown":
    weaver registry generate -r {{MODEL_DIR}} {{target}} {{REGISTRIES_DIR}}

# Resolve the registry and output to stdout
[group('generation')]
resolve:
    weaver registry resolve -r {{MODEL_DIR}} -o {{REGISTRIES_DIR}}

# Resolve to JSON format
[group('generation')]
resolve-json:
    weaver registry resolve -r {{MODEL_DIR}} -f json -o {{REGISTRIES_DIR}}

# Generate JSON schema
[group('generation')]
json-schema:
    weaver registry json-schema -o {{REGISTRIES_DIR}}

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
update-docs markdown_dir="docs":
    weaver registry update-markdown --registry ./model --templates templates --target markdown --future -D registry_base_url=/docs/registry/ {{markdown_dir}}

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
    just capture-spans 4317

# Capture spans from real application to analyze and generate registry
[group('capture')]
capture-spans port="4317":
    @echo "Starting OTLP listener on port {{port}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be streamed to console"
    @echo "Will stop after {{DEFAULT_TIMEOUT}} seconds of inactivity"
    @echo "Press Ctrl+C to stop manually or use curl http://localhost:4320/stop"
    weaver registry live-check \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --inactivity-timeout {{DEFAULT_TIMEOUT}}

# Capture spans and save analysis to files
[group('capture')]
capture-spans-to-file port="4317":
    @echo "Starting OTLP listener on port {{port}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be saved to {{CAPTURE_DIR}}"
    @echo "Will stop after {{DEFAULT_TIMEOUT}} seconds of inactivity"
    @echo "Press Ctrl+C to stop manually or use curl http://localhost:4320/stop"
    weaver registry live-check \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --output {{CAPTURE_DIR}} \
        --inactivity-timeout {{DEFAULT_TIMEOUT}} \
        --no-stream

# Capture spans with custom registry validation (for existing apps)
[group('capture')]
capture-validate registry port="4317":
    @echo "Starting span capture with validation against {{registry}}..."
    @echo "Send your application spans to localhost:{{port}}"
    @echo "Analysis will be streamed to console"
    weaver registry live-check \
        --registry {{registry}} \
        --input-source otlp \
        --otlp-grpc-port {{port}} \
        --admin-port 4320 \
        --inactivity-timeout {{DEFAULT_TIMEOUT}}

# Stop the active capture process
[group('capture')]
stop-capture:
    @echo "Stopping active capture process..."
    curl -X POST http://localhost:4320/stop

# ================================
# SDK LAG FILTERING
# ================================

# Filter known SDK lag violations from analysis results
[group('analysis')]
filter-sdk-lag analysis_file:
    @echo "Filtering known SDK lag violations from {{analysis_file}}..."
    ./scripts/filter_violations.sh {{analysis_file}}

