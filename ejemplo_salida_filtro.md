# Ejemplo de salida del filtro de SDK lag

## Salida en consola al ejecutar `just filter-sdk-lag spans_analysis.json`:

```
🚀 Filtrando violations conocidas del SDK lag...
📄 Input: spans_cliente_0.59b0.json

🔍 ANÁLISIS DE VIOLATIONS FILTRADO
==================================================
📊 Total violations: 15
🚨 Issues reales: 3 (requieren atención inmediata)
⏳ SDK lag conocido: 11 (esperado)
❓ Deprecados desconocidos: 1 (revisar)

💡 ATENCIÓN REQUERIDA: 4 violations

🔴 ACCIÓN INMEDIATA:
   - Fix 3 real violations in your application code

🟡 REVISAR:
   - Check 1 deprecated attributes not in known SDK lag list

✅ Filtrado completado!
📊 Ver resultados detallados:
   jq '.summary' spans_cliente_0.59b0_filtered.json

🔍 Ver solo violations reales:
   jq '.filtered_results.real_violations' spans_cliente_0.59b0_filtered.json

⏳ Ver SDK lag conocido:
   jq '.filtered_results.sdk_lag_violations' spans_cliente_0.59b0_filtered.json
```

## Contenido del archivo `*_filtered.json`:

```json
{
  "summary": {
    "total_violations": 15,
    "real_issues": 3,
    "known_sdk_lag": 11,
    "unknown_deprecated": 1,
    "attention_needed": 4
  },
  "filtered_results": {
    "real_violations": [
      {
        "type": "missing_attribute",
        "attribute": "service.version",
        "message": "Required attribute missing",
        "severity": "error"
      },
      {
        "type": "invalid_value",
        "attribute": "http.method",
        "message": "Invalid HTTP method value",
        "severity": "error"
      }
    ],
    "sdk_lag_violations": [
      {
        "type": "deprecated_attribute",
        "attribute": "deployment.environment",
        "message": "Replaced by deployment.environment.name",
        "replacement": "deployment.environment.name",
        "category": "known_sdk_lag"
      },
      {
        "type": "deprecated_attribute", 
        "attribute": "db.statement",
        "message": "Replaced by db.query.text",
        "replacement": "db.query.text",
        "category": "known_sdk_lag"
      }
    ],
    "unknown_deprecated": [
      {
        "type": "deprecated_attribute",
        "attribute": "some.new.deprecated.attr",
        "message": "Recently deprecated attribute",
        "category": "unknown_deprecated"
      }
    ]
  },
  "recommendations": {
    "immediate_action": [
      {
        "type": "fix_violations",
        "count": 3,
        "message": "Fix 3 real violations in your application code"
      }
    ],
    "monitor": [
      {
        "type": "check_new_deprecated", 
        "count": 1,
        "message": "Check 1 deprecated attributes not in known SDK lag list"
      }
    ],
    "sdk_updates": [
      {
        "type": "sdk_lag",
        "message": "SDK lag detected in 2 areas: deployment, database",
        "areas": {
          "deployment": [
            {"attribute": "deployment.environment", "replacement": "deployment.environment.name"}
          ],
          "database": [
            {"attribute": "db.statement", "replacement": "db.query.text"}
          ]
        },
        "total_count": 11
      }
    ]
  }
}
```

## Interpretación de resultados:

### ✅ **violations SDK lag conocido (11)**: 
- Son **esperadas** y **normales**
- El SDK aún no actualizó estos atributos
- **No requieren acción** de tu parte
- Ejemplos: `deployment.environment`, `db.statement`, etc.

### 🚨 **violations reales (3)**:
- **Requieren atención inmediata**
- Son problemas en tu código de aplicación
- Ejemplos: atributos faltantes, valores inválidos

### ❓ **violations deprecadas desconocidas (1)**:
- Atributos deprecados no en nuestra lista conocida
- Podrían ser **nuevos** o **específicos** de tu SDK
- **Revisar** si necesitan acción

### 💡 **Flujo recomendado**:
1. **Enfócate** en las 4 violations que requieren atención (reales + desconocidas)
2. **Ignora** las 11 de SDK lag conocido
3. **Monitorea** si las desconocidas se vuelven comunes (agregar a la lista)