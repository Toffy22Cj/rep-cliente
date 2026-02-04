# ✅ RESUMEN DE CAMBIOS - SOLUCIÓN DEL ERROR DE NULLPTR EN LOGIN

## 🎯 Problema Original

El botón "Iniciar Sesión" no funcionaba con el error:

```
qt.core.qobject.connect: QObject::connect(QObject, Unknown): invalid nullptr parameter
```

## ✅ Causa Raíz Identificada

Las **Connections** en Main.qml se creaban durante la inicialización de QML, **ANTES** de que `loginViewModel` fuera disponible como context property.

Qt 6 evaluaba `target: loginViewModel` cuando `loginViewModel` aún no existía → **nullptr**

## 🔧 Soluciones Aplicadas

### 1️⃣ qml/Main.qml - Cambio Principal

```qml
// ❌ ANTES (causaba nullptr):
Connections {
    target: typeof loginViewModel !== 'undefined' ? loginViewModel : null
    enabled: target !== null
    function onLoginSuccess(role) { ... }
}

// ✅ DESPUÉS (seguro):
Component.onCompleted: {
    console.log("Main.qml Component.onCompleted iniciado")
    if (loginViewModel !== undefined) {
        loginViewModel.loginSuccess.connect(handleLoginSuccess)
        console.log("✓ Conexión establecida: loginViewModel.loginSuccess")
    }
}
```

**Por qué funciona**: `Component.onCompleted` se ejecuta DESPUÉS de que el componente está completamente listo y todos los context properties están disponibles.

### 2️⃣ qml/pages/LoginPage.qml - Conexión Segura

```qml
Component.onCompleted: {
    console.log("LoginPage.qml Component.onCompleted")
    if (loginViewModel !== undefined && loginViewModel.loginSuccess !== undefined) {
        loginViewModel.loginSuccess.connect(function(role) {
            console.log("LoginPage: loginSuccess conectado, rol:", role)
            root.loginSuccess()
        })
        console.log("✓ LoginPage: Conexión establecida")
    }
}
```

### 3️⃣ api/ApiConfig.h - URL Correcta ✓ (ya hecho)

```cpp
#ifdef QT_DEBUG
    return "http://localhost:8080/api";
#else
    return "https://api.mirepapp.com/api";
#endif
```

### 4️⃣ api/AuthService.cpp - Logging ✓ (ya hecho)

- Logs detallados de las peticiones POST

### 5️⃣ viewmodels/LoginViewModel.cpp - Logging ✓ (ya hecho)

- Logs cuando emite la señal loginSuccess

## 📋 Pasos para Probar (3 minutos)

### Paso 1: Recompila

```bash
cd /home/carlos/Proyectos/Rep-cliente/Rep
cmake --build . --target all --parallel 4
```

- ✓ Espera: Sin errores de compilación

### Paso 2: Asegura Backend Corriendo

Abre otra terminal:

```bash
# Verifica que el backend está en puerto 8080
curl http://localhost:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"usuario":"test","password":"123456"}'
```

- ✓ Espera: Respuesta JSON del backend (no error de conexión)

### Paso 3: Ejecuta Aplicación

```bash
cd /home/carlos/Proyectos/Rep-cliente/Rep/build/Desktop_Qt_6_10_1-Debug/
./appRep
```

### Paso 4: Prueba Login

1. Ingresa identificación: `test` (3+ caracteres)
2. Ingresa contraseña: `123456` (6+ caracteres)
3. Haz click en "Iniciar Sesión"

**Verifica en consola** (debe aparecer sin errores):

```
✓ Main.qml Component.onCompleted iniciado
✓ loginViewModel definido: true
✓ sessionManager definido: true
✓ Conexión establecida: loginViewModel.loginSuccess
✓ Conexión establecida: sessionManager.sessionChanged
✓ LoginPage.qml Component.onCompleted
✓ LoginPage: Conexión establecida
QML: Iniciar Sesión clickeado
AuthService: Enviando petición POST a http://localhost:8080/api/auth/login
AuthService: Login response received (success: true)
LoginViewModel: EMITIENDO loginSuccess con rol: ESTUDIANTE
Main.qml: Login OK, rol: ESTUDIANTE
→ Dashboard se muestra
```

## 🚨 Si Algo Falla Aún

### Error: `invalid nullptr parameter` persiste

1. Limpia el build:
   ```bash
   rm -rf /home/carlos/Proyectos/Rep-cliente/Rep/build
   ```
2. Recompila desde cero
3. Asegura que estés usando Qt Creator (no qmake manual)

### Login no responde (no aparecen logs)

- Verifica que `loginViewModel.login()` se ejecute correctamente
- Abre la consola de Qt Creator: View → Output Panes → Application Output

### Backend retorna error

```bash
curl http://localhost:8080/api/auth/login -v
```

- Si falla conexión: Backend no está corriendo
- Si retorna 401: Credenciales inválidas
- Si retorna 500: Error en el backend

### Logs no muestran "✓" sino "❌"

- Significa que `loginViewModel` o `sessionManager` no se pasaron correctamente
- Verifica que main.cpp tenga:
  ```cpp
  engine.rootContext()->setContextProperty("loginViewModel", &loginViewModel);
  engine.rootContext()->setContextProperty("sessionManager", &sessionManager);
  ```

## 📚 Documentación Generada

Para debugging paso a paso:

- **[DEBUG_PASO_A_PASO.md](DEBUG_PASO_A_PASO.md)** - Guía completa con árbol de decisión

## 🎓 Concepto Aprendido

En Qt/QML, las conexiones dinámicas deben hacerse en:

- ✓ `Component.onCompleted` - Los context properties ya existen
- ❌ Durante la construcción del componente - Los context properties NO existen aún

Este patrón se puede aplicar a todos los archivos QML que usen context properties de C++.

## ✅ Checklist

- [ ] Recompilaste sin errores
- [ ] Backend está corriendo en port 8080
- [ ] Ejecutaste la app y viste logs de Component.onCompleted
- [ ] Intentaste login con credenciales válidas
- [ ] Viste los logs de AuthService y LoginViewModel
- [ ] El dashboard se mostró correctamente
- [ ] Probaste logout y volvió al login

---

**Si todo funciona:** Elimina los logs `console.log()` de producción y continúa con el plan de mejoras (PLAN_MEJORAS.md)

**Si persisten problemas:** Revisa DEBUG_PASO_A_PASO.md para troubleshooting avanzado
