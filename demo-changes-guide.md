# Cambios sugeridos para tu aplicación de demo

## RESUMEN DE RESULTADOS:
✅ **REGISTRY CREADO**: Se creó `/model/demo/registry.yaml` que define todos los atributos que usa tu app
✅ **ERRORES REDUCIDOS**: Los atributos ya no aparecen como "missing_attribute" (violation)
✅ **SOLO QUEDAN WARNINGS**: Ahora solo aparecen como "not_stable" (improvement) o "missing_namespace" 

## 1. Cambiar atributos deprecados:
# Antes:
resource_attributes = {
    "service.name": "o11y-demo",
    "deployment.environment": "dev",  # ❌ DEPRECADO
    "app": "o11y-demo"                # ❌ SIN NAMESPACE
}

# Después:
resource_attributes = {
    "service.name": "o11y-demo", 
    "deployment.environment.name": "dev",  # ✅ NUEVO ATRIBUTO
    "demo.app": "o11y-demo"                # ✅ CON NAMESPACE DEMO
}

## 2. Cambiar atributos de spans para usar namespacing:
# Antes:
span.set_attributes({
    "function.name": "process_data",        # ❌ NO ESTÁ EN REGISTRY
    "function.module": "__main__",         # ❌ NO ESTÁ EN REGISTRY  
    "args.0": str(data),                   # ❌ SIN NAMESPACE
    "args.1": str(multiplier),             # ❌ SIN NAMESPACE
    "result": str(result)                  # ❌ SIN NAMESPACE
})

# Después (usando el registry que creé):
span.set_attributes({
    "function.name": "process_data",        # ✅ DEFINIDO EN REGISTRY
    "function.module": "__main__",         # ✅ DEFINIDO EN REGISTRY
    "function.args.0": str(data),          # ✅ TEMPLATE ATTRIBUTE
    "function.args.1": str(multiplier),    # ✅ TEMPLATE ATTRIBUTE  
    "function.result": str(result)         # ✅ CON NAMESPACE
})

## 3. O alternativamente, usar atributos estándar existentes:
# Para casos más reales, podrías usar:
span.set_attributes({
    "code.function": "process_data",       # ✅ ATRIBUTO ESTÁNDAR
    "code.namespace": "__main__",          # ✅ ATRIBUTO ESTÁNDAR
    # Los args específicos seguirían necesitando el registry personalizado
    "function.args.0": str(data),
    "function.args.1": str(multiplier),
    "demo.operation.result": str(result)   # ✅ CON NAMESPACE DEMO
})

## 4. ESTADO ACTUAL CON EL REGISTRY:
Con el registry creado en `/model/demo/registry.yaml`, tu aplicación actual ya NO genera violaciones.
Los únicos "problemas" que quedan son:

✅ **SOLUCIONADO**: `function.name`, `function.module` → Ya están definidos, solo son "development" stability
✅ **SOLUCIONADO**: `args.0`, `args.1` → Ya están definidos como template attributes  
✅ **SOLUCIONADO**: `result` → Ya está definido, solo falta namespace
⚠️  **QUEDA**: `deployment.environment` → Aún deprecado, cambiar a `deployment.environment.name`
⚠️  **QUEDA**: `app` → Falta namespace, cambiar a `demo.app`

## 5. PARA ELIMINAR TODOS LOS WARNINGS:
Si quieres eliminar completamente todos los warnings, haz estos cambios mínimos en tu app:

```python
# Cambios mínimos para eliminar todos los warnings:
resource_attributes = {
    "service.name": "o11y-demo",
    "deployment.environment.name": "dev",  # Cambiar: .environment → .environment.name
    "demo.app": "o11y-demo"                # Cambiar: app → demo.app
}

# Los spans pueden quedar igual - ya están cubiertos por el registry
```