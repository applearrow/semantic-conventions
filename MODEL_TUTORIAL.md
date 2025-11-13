# OpenTelemetry Semantic Conventions Model Structure Tutorial

## Understanding the YAML Model Architecture

This tutorial explains how the OpenTelemetry semantic conventions YAML model is structured and how different files work together.

### File Structure Overview

The semantic conventions follow a specific file organization pattern:

```
model/{area}/
├── registry.yaml    # Attribute definitions only
├── common.yaml      # Attribute groups for reuse
├── spans.yaml       # Span definitions
├── metrics.yaml     # Metric definitions
├── events.yaml      # Event definitions
└── entities.yaml    # Entity definitions
```

## Key Concepts

### 1. Registry Files (`registry.yaml`)

**Purpose**: Registry files are "dictionaries" that define individual attributes that can be reused across multiple contexts.

**Content**: Contains ONLY attribute definitions with `type: attribute_group` and `id` starting with `registry.` prefix.

**Important**: Registry files are **passive** - they don't reference other files. Other files reference them.

#### Example:
```yaml
groups:
  - id: registry.code
    type: attribute_group
    brief: These attributes provide context about source code
    attributes:
      - id: code.function.name
        type: string
        brief: Function name
      - id: code.namespace  
        type: string
        brief: Namespace containing the code
```

### 2. Common Files (`common.yaml`)

**Purpose**: Group related attributes from the registry into reusable collections.

**Content**: Creates attribute groups that reference (`ref:`) attributes from registry files.

#### Example:
```yaml
groups:
  - id: code
    type: attribute_group
    brief: Source code context attributes
    attributes:
      - ref: code.function.name     # References registry attribute
      - ref: code.namespace         # References registry attribute
        requirement_level: recommended
```

### 3. Implementation Files (`spans.yaml`, `metrics.yaml`, etc.)

**Purpose**: Define actual telemetry signals (spans, metrics, events) that use the attribute groups.

**Content**: Use `extends:` to inherit attribute groups or `ref:` to reference individual attributes.

#### Example:
```yaml
groups:
  - id: span.function.execution
    type: span
    extends: code                   # Inherits all attributes from 'code' group
    brief: Span representing function execution
```

## The Connection Flow

The connection works in **one direction only**:

```
registry.yaml → common.yaml → spans/metrics/events.yaml
     ↑              ↑                    ↑
  Defines        Groups              Uses/Extends
 attributes    attributes           attribute groups
```

### Step-by-Step Flow:

1. **Registry defines**: `code.function.name`, `code.namespace`
2. **Common groups**: Creates `code` group that references both attributes
3. **Spans use**: `extends: code` to inherit all attributes in the group

## Why This Structure?

### Benefits:

1. **Reusability**: Attributes defined once, used everywhere
2. **Consistency**: Same attribute has same definition across all contexts  
3. **Maintainability**: Changes in registry automatically propagate
4. **Organization**: Clear separation of concerns
5. **Validation**: Centralized attribute definitions prevent conflicts

### Example in Practice:

```yaml
# registry.yaml - Passive definitions
- id: code.function.name
  type: string
  brief: "Function name"
- id: code.namespace  
  type: string
  brief: "Code namespace"

# common.yaml - Groups for reuse
- id: code
  attributes:
    - ref: code.function.name
    - ref: code.namespace

# spans.yaml - Active usage
- id: span.function.call
  type: span
  extends: code  # Gets both function.name AND namespace
```

## Common Questions

### Q: Should registry.yaml reference spans or metrics?
**A**: NO. Registry files are passive. They only define attributes. Other files reference the registry.

### Q: How do I know if my registry structure is correct?
**A**: If your registry.yaml contains only `attribute_group` types with attribute definitions, it's correct.

### Q: Can I define spans in registry.yaml?
**A**: NO. Registry files are exclusively for attributes. Spans go in `spans.yaml`.

### Q: How do I add a new attribute to existing spans?
**A**: 
1. Add attribute to `registry.yaml`
2. Add reference in `common.yaml` (if grouping)  
3. Spans that `extend` the group automatically get the new attribute

### Q: Do I have to explicitly declare the names I use for my spans?
**A**: Not necessarily. Span names are set programmatically in your application code using the OpenTelemetry SDK. However, if you want to define semantic conventions for span names (for consistency and documentation), you can define them in your `spans.yaml` file with the `span_name` property.

### Q: What's the difference between span names and span IDs?
**A**: Span names are human-readable identifiers that describe what the span represents (e.g., "HTTP GET /users"). Span IDs in the YAML model are technical identifiers used to reference span definitions in semantic conventions (e.g., `http.server.request`).

### Q: Can I use custom attributes that aren't in any registry?
**A**: Yes, you can use custom attributes in your application. However, for better observability and consistency, it's recommended to define them in a registry file, especially if they'll be used across multiple spans or applications.

### Q: How do I handle high-cardinality attributes?
**A**: High-cardinality attributes (like user IDs, request IDs) should be marked with `requirement_level: opt_in` in the registry and used carefully in metrics to avoid cardinality explosion. Consider using them only in spans or as opt-in attributes.

## Best Practices

1. **Always define attributes in registry first**
2. **Use meaningful group names in common.yaml**
3. **Set appropriate requirement levels** (`required`, `recommended`, `opt_in`)
4. **Follow naming conventions** (lowercase, dot-separated)
5. **Add clear documentation** with `brief` and `note` fields
6. **Include realistic examples**

## Validation

The structure is validated by policies that ensure:
- Registry attributes follow naming conventions
- No circular references exist
- Stability requirements are met
- Required fields are present

Run validation with:
```bash
make check-policies
```

This architecture ensures that OpenTelemetry semantic conventions remain consistent, maintainable, and reusable across the entire ecosystem.