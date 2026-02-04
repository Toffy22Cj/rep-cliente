# Guía de Debugging del Login - Paso a Paso

## Problemas Identificados y Solucionados

### 1. **Error: `qt.core.qobject.connect: QObject::connect(QObject, Unknown): invalid nullptr parameter`**

- **Causa Raíz**: Las Connections en Main.qml se creaban ANTES de que `loginViewModel` estuviera disponible
- **Solución Aplicada**: Cambiar a `Component.onCompleted` que se ejecuta después de que el componente está completamente listo

### 2. **URL Incorrecta en ApiConfig.h**

- **Antes**: `https://127.0.0.1:8080/api` (HTTPS + IP)
- **Después**: `http://localhost:8080/api` (HTTP + localhost en DEBUG)
- **Por qué**: El backend local corre en HTTP, no HTTPS

## Cambios Realizados

### ✓ qml/Main.qml

```qml
Component.onCompleted: {
    console.log("Main.qml Component.onCompleted iniciado")

    if (loginViewModel !== undefined) {
        loginViewModel.loginSuccess.connect(handleLoginSuccess)
        console.log("✓ Conexión establecida: loginViewModel.loginSuccess")
    }

    if (sessionManager !== undefined) {
        sessionManager.sessionChanged.connect(handleSessionChanged)
        console.log("✓ Conexión establecida: sessionManager.sessionChanged")
    }
}
```

**Ventajas**:

- ✓ Se ejecuta DESPUÉS de que los context properties están disponibles
- ✓ No genera errores de nullptr
- ✓ Más control sobre el flujo de inicialización
- ✓ Mejor visibilidad en logs

### ✓ qml/pages/LoginPage.qml

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

### ✓ api/ApiConfig.h

```cpp
#ifdef QT_DEBUG
    return "http://localhost:8080/api";
#else
    return "https://api.mirepapp.com/api";
#endif
```

### ✓ api/AuthService.cpp

- Agregado logging detallado en login() y onReplyFinished()
- Logs muestran: solicitud, respuesta, tokens, roles

### ✓ viewmodels/LoginViewModel.cpp

- Agregado logging cuando emite loginSuccess
- Logs muestran: usuario, rol, éxito de autenticación

## Flujo de Ejecución Esperado (con logs)

```
1. Aplicación inicia (main.cpp)
   ✓ Tipos registrados
   ✓ Context properties configuradas

2. QML Engine carga Main.qml
   ✓ Component.onCompleted de Main.qml
   ✓ Conexión establecida: loginViewModel.loginSuccess
   ✓ Conexión establecida: sessionManager.sessionChanged

3. Main.qml crea LoginPage
   ✓ Component.onCompleted de LoginPage.qml
   ✓ Conexión establecida: LoginPage → loginViewModel.loginSuccess

4. Usuario ingresa credenciales y hace click en "Iniciar Sesión"
   QML: Iniciar Sesión clickeado
   QML: Identificación: [usuario]
   QML: Longitud pass: [num]

5. LoginViewModel.login() se ejecuta
   AuthService: Enviando petición POST a http://localhost:8080/api/auth/login
   AuthService: Body: {"usuario":"[user]","password":"[pass]"}

6. Backend responde
   AuthService: Login response received
   AuthService: Status Code: 200
   AuthService: Token recibido: [token]
   AuthService: Rol: ESTUDIANTE/PROFESOR/ADMIN

7. LoginViewModel emite loginSuccess
   LoginViewModel: EMITIENDO loginSuccess con rol: [ROLE]
   LoginViewModel: loginSuccess emitido exitosamente

8. Main.qml recibe loginSuccess
   Main.qml: Login OK, rol: [ROLE]
   → stackView.replace(getDashboardComponent())

9. Dashboard se muestra
   ✓ Login completado exitosamente
```

## Pasos para Probar

### Paso 1: Recompilar

```bash
cd /home/carlos/Proyectos/Rep-cliente/Rep
cmake --build . --target all --parallel 4
```

**Verificar**:

- ✓ Sin errores de compilación
- ✓ Sin warnings críticos
- ✓ El ejecutable `appRep` existe en `build/Desktop_Qt_6_10_1-Debug/`

### Paso 2: Asegurar Backend Corriendo

```bash
# En otra terminal, verificar que el backend está en puerto 8080
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"test","password":"123456"}'
```

**Esperar**: Respuesta JSON del backend (sin error de conexión rechazada)

### Paso 3: Ejecutar Aplicación

```bash
cd /home/carlos/Proyectos/Rep-cliente/Rep/build/Desktop_Qt_6_10_1-Debug/
./appRep
```

**Verificar en la consola** (deben aparecer estos logs sin "❌"):

```
✓ Component.onCompleted iniciado
✓ loginViewModel definido: true
✓ sessionManager definido: true
✓ Conexión establecida: loginViewModel.loginSuccess
✓ Conexión establecida: sessionManager.sessionChanged
✓ LoginPage.qml Component.onCompleted
✓ LoginPage: Conexión establecida
```

### Paso 4: Ingreso Prueba de Login

1. Esperar a que se cargue la ventana de login
2. Ingresar en "Identificación": `test` (mínimo 3 caracteres)
3. Ingresar en "Contraseña": `123456` (mínimo 6 caracteres)
4. Hacer click en "Iniciar Sesión"

**Verificar en consola**:

```
QML: Iniciar Sesión clickeado
QML: Identificación: test
QML: Longitud pass: 6
AuthService: Enviando petición POST a http://localhost:8080/api/auth/login
AuthService: Login response received (success: true)
AuthService: EMITIENDO loginFinished. Success: true
LoginViewModel: EMITIENDO loginSuccess con rol: ESTUDIANTE
LoginViewModel: loginSuccess emitido exitosamente
Main.qml: Login OK, rol: ESTUDIANTE
→ Dashboard se muestra
```

## Árbol de Decisión para Debugging

### ¿Qué pasa si sigue sin funcionar?

#### Error: `invalid nullptr parameter`

- ✓ **Solucionado**: El cambio a `Component.onCompleted` debe eliminar este error
- Si persiste: Reinicia Qt Creator, limpia `build/` y recompila

#### Login sin respuesta (no pasa nada al hacer click)

- Verificar logs:
  - ❌ No aparece "QML: Iniciar Sesión clickeado"
    → El botón no está conectado. Revisar onClick en LoginPage.qml
  - ❌ Aparece pero no llega a AuthService
    → El método login() no se ejecuta. Verificar LoginViewModel.cpp
  - ✓ Aparecen logs de AuthService
    → Ir a "Backend no responde"

#### Backend no responde (`Connection refused` o timeout)

- Verificar:
  ```bash
  netstat -an | grep 8080
  # o
  lsof -i :8080
  ```

  - ❌ Puerto 8080 no está abierto → Backend no está corriendo
  - ✓ Está abierto → Verificar logs de Spring Boot

#### Login con credenciales inválidas

- Backend devuelve JSON con `success: false`
- Expected logs:
  ```
  AuthService: Login response received (success: false)
  LoginViewModel: EMITIENDO loginSuccess CON ESTADO FALLIDO
  ```
- Verificar credenciales del backend

#### Login exitoso pero no llega a Dashboard

- Logs muestran: "Main.qml: Login OK, rol: ESTUDIANTE"
- Pero Dashboard no aparece
- Verificar:
  - Que exista `qml/pages/StudentDashboard.qml`
  - Que `getDashboardComponent()` retorne el componente correcto
  - Que `stackView.replace()` funcione (revisar StackView setup)

## Checklist Final

- [ ] Cambios en Main.qml (Component.onCompleted con logging)
- [ ] Cambios en LoginPage.qml (Component.onCompleted)
- [ ] ApiConfig.h con HTTP/localhost
- [ ] AuthService.cpp con logging detallado
- [ ] LoginViewModel.cpp con logging
- [ ] Backend corriendo en http://localhost:8080
- [ ] Recompilación sin errores
- [ ] Prueba de login con credenciales válidas
- [ ] Logs muestran toda la cadena de ejecución
- [ ] Dashboard se muestra correctamente

## Próximos Pasos si Todo Funciona

1. ✅ Remover logs de DEBUG
2. ✅ Implementar timeout en AuthService (5 segundos)
3. ✅ Mejora de UI: mostrar spinner mientras se procesa
4. ✅ Test end-to-end de todas las páginas
5. ✅ Implementar refresh de token
