@_:
    just --list

# Check semantic-search model with weaver
check:
    weaver registry check -r ./model/semantic-search

# Check with future validation rules enabled (recommended for new registries)
check-future:
    weaver registry check -r ./model/semantic-search --future

# Check with policy validation
check-policies:
    weaver registry check -r ./model/semantic-search -p ./policies

# Check the full model directory
check-all:
    weaver registry check -r ./model

# Check with debug output
check-debug:
    weaver registry check -r ./model/semantic-search --debug

# Generate artifacts for a specific target
generate target="markdown" output="semantic-search-registry":
    weaver registry generate -r ./model/semantic-search {{target}} {{output}}

# Resolve the registry and output to stdout
resolve output="semantic-search-registry.yaml":
    weaver registry resolve -r ./model/semantic-search -o {{output}}

# Resolve to JSON format
resolve-json output="resolved.json":
    weaver registry resolve -r ./model/semantic-search -f json -o {{output}}

# Search the registry interactively
search:
    weaver registry search -r ./model/semantic-search

# Search for specific term
search-term term:
    weaver registry search -r ./model/semantic-search "{{term}}"

# Get registry statistics
stats:
    weaver registry stats -r ./model/semantic-search

# Generate JSON schema
json-schema output="schema.json":
    weaver registry json-schema -o {{output}}

# Compare with baseline registry
diff baseline:
    weaver registry diff -r ./model/semantic-search --baseline-registry {{baseline}}

# Update markdown files
update-markdown target markdown_dir="docs":
    weaver registry update-markdown -r ./model/semantic-search --target {{target}} {{markdown_dir}}

# Emit example signals to OTLP receiver
emit:
    weaver registry emit -r ./model/semantic-search

# Live check conformance (starts OTLP listener)
live-check:
    weaver registry live-check -r ./model/semantic-search
