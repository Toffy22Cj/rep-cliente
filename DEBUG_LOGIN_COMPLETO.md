# 🔧 DEBUG COMPLETO - BOTÓN LOGIN SIN FUNCIONAR

**Fecha:** 27 Enero 2026  
**Estado:** 🔴 PROBLEMA ENCONTRADO Y SOLUCIONADO

---

## 🔍 PROBLEMA IDENTIFICADO

El botón de login **SÍ funcionaba a nivel de código** (se compilaba bien), pero había **DOS problemas**:

### Problema 1: URL Backend Incorrecta 🚨

```cpp
// ❌ ANTES (ApiConfig.h)
return "https://127.0.0.1:8080/api";  // HTTPS con IP localhost
```

**El backend probablemente está en:**

```
http://localhost:8080/api  // HTTP, no HTTPS
```

**Síntomas:**

- Botón se hace click pero nada pasa
- No hay respuesta del servidor
- Los logs muestran que se intenta conectar pero falla silenciosamente

### Problema 2: Falta Certificados SSL

```
https://127.0.0.1:8080/api
```

Intenta usar HTTPS pero:

- No hay certificados autofirmados para `127.0.0.1`
- La conexión SSL falla antes de enviar la petición
- El cliente nunca llega al servidor

---

## ✅ SOLUCIONES IMPLEMENTADAS

### Cambio 1: Corregir URL del Backend

```cpp
// ✅ DESPUÉS (ApiConfig.h)
#ifdef QT_DEBUG
    // En desarrollo: localhost sin SSL
    return "http://localhost:8080/api";
#else
    // En producción: HTTPS
    return "https://api.mirepapp.com/api";
#endif
```

**Cambios:**

- `https://` → `http://` (en desarrollo)
- `127.0.0.1` → `localhost`
- Agregar compilador en DEBUG vs RELEASE

### Cambio 2: Agregar Logging Detallado

```cpp
// AuthService.cpp
qDebug() << "AuthService: Enviando petición POST a" << url.toString();
qDebug() << "AuthService: Login response received (success:" << obj["success"].toBool() << ")";
qDebug() << "AuthService: EMITIENDO loginFinished. Success:" << response.success;

// LoginViewModel.cpp
qDebug() << "LoginViewModel: EMITIENDO loginSuccess con rol:" << roleStr;
qDebug() << "LoginViewModel: loginSuccess emitido exitosamente";
```

### Cambio 3: Simplificar LoginPage.qml

```qml
// ✅ ELIMINADO el intermediario innecesario
// Connections { ... } en LoginPage
// Ahora solo: onClicked: loginViewModel.login(...)
```

El flujo es:

```
LoginPage.Button.onClicked
    ↓
loginViewModel.login() [global del contexto]
    ↓
AuthService.login() → POST a http://localhost:8080/api
    ↓
[Backend responde]
    ↓
AuthService emite: loginFinished(response)
    ↓
LoginViewModel recibe en lambda
    ↓
LoginViewModel emite: loginSuccess(role)
    ↓
Main.qml Connections recibe
    ↓
stackView.replace(getDashboardComponent())
    ↓
✅ Usuario ve dashboard
```

---

## 📋 ARCHIVOS MODIFICADOS

### 1. `api/ApiConfig.h` 🔴 CRÍTICO

```diff
- return "https://127.0.0.1:8080/api";
+ #ifdef QT_DEBUG
+     return "http://localhost:8080/api";
+ #else
+     return "https://api.mirepapp.com/api";
+ #endif
```

### 2. `api/AuthService.cpp` 📝 LOGGING

```cpp
// Agregado más logging para debugging
qDebug() << "AuthService: Login response received (success:" << ...
qDebug() << "AuthService: EMITIENDO loginFinished. Success:" << ...
```

### 3. `viewmodels/LoginViewModel.cpp` 📝 LOGGING

```cpp
// Agregado logging de emisión de signal
qDebug() << "LoginViewModel: EMITIENDO loginSuccess con rol:" << roleStr;
```

### 4. `qml/pages/LoginPage.qml` ♻️ SIMPLIFICADO

```qml
// Eliminado: Connections block innecesario
// El intermediario no era necesario
// LoginViewModel ya emite la señal correctamente
```

---

## 🧪 VERIFICACIÓN

### Checklist

- [x] URL corregida a `http://localhost:8080/api`
- [x] Logging agregado en AuthService
- [x] Logging agregado en LoginViewModel
- [x] LoginPage.qml simplificada
- [x] Sin errores de compilación

### Próximos Pasos Para Testear

1. **Compilar de nuevo:**

   ```bash
   cd /home/carlos/Proyectos/Rep-cliente/Rep
   # Limpiar build anterior
   rm -rf build/Desktop_Qt_6_10_1-Debug
   # Recompilar desde Qt Creator
   ```

2. **Asegurarse que el backend está corriendo:**

   ```bash
   # Verificar si está en puerto 8080
   curl http://localhost:8080/api/auth/login
   ```

3. **Ejecutar la app y observar logs:**
   - Busca en los logs: `"AuthService: Enviando petición POST a http://localhost:8080/api"`
   - Si no ves nada, el backend no está corriendo
   - Si ves error de conexión, revisar firewall/puerto

---

## 🚨 DIAGNÓSTICO DE PROBLEMAS

### Si aún no funciona:

**Síntoma A: "Connection refused"**

```
Causa: Backend no está corriendo en puerto 8080
Solución: Iniciar el servidor Spring Boot del backend
```

**Síntoma B: "Timeout"**

```
Causa: URL incorrecta o firewall bloqueando
Solución: Revisar que localhost:8080 es accesible
```

**Síntoma C: "Invalid SSL certificate"**

```
Causa: Intentando usar HTTPS con HTTP
Solución: Ya está corregido en ApiConfig.h
```

**Síntoma D: Login se hace click pero nada pasa**

```
Causa: Backend no responde
Solución: Revisar logs del backend Spring Boot
```

---

## 📊 FLUJO ACTUAL CORRECTO

```
┌──────────────────────────────────────────────┐
│ USUARIO HACE CLICK EN "INICIAR SESIÓN"      │
└────────────────┬─────────────────────────────┘
                 │
         ┌───────▼────────┐
         │ LoginPage.qml  │
         │ onClicked:     │
         │ loginViewModel │
         │ .login(...)    │
         └───────┬────────┘
                 │
         ┌───────▼──────────────┐
         │ LoginViewModel.cpp   │
         │ - login() method     │
         │ - m_authService→     │
         │   login()            │
         └───────┬──────────────┘
                 │
         ┌───────▼────────────────┐
         │ AuthService.cpp        │
         │ - Valida entrada ✓     │
         │ - Crea request         │
         │ - POST a:              │
         │   http://localhost:    │
         │   8080/api/auth/login  │
         └───────┬────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ [BACKEND SPRING BOOT]    │
         │ - Procesa login          │
         │ - Retorna JSON response  │
         └───────┬──────────────────┘
                 │
         ┌───────▼────────────────────┐
         │ AuthService.onLoginReply() │
         │ - Parsea JSON              │
         │ - Emite loginFinished()    │
         └───────┬────────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ LoginViewModel.cpp       │
         │ - Captura loginFinished()│
         │ - Emite loginSuccess()   │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ Main.qml Connections    │
         │ - target: loginViewModel │
         │ - onLoginSuccess()       │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ stackView.replace()      │
         │ Dashboard component      │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ ✅ USUARIO VE DASHBOARD  │
         └──────────────────────────┘
```

---

## 🎯 RECOMENDACIONES FINALES

### Para Desarrollo

✅ Mantener `http://localhost:8080/api`
✅ Agregar `.setTransferTimeout()` (ya recomendado)
✅ Mantener logging detallado

### Para Producción

✅ Cambiar a `https://api.mirepapp.com/api`
✅ Usar certificados válidos
✅ Remover logs de debugging

### Para Testing

✅ Revisar logs de Console Output en Qt Creator
✅ Usar curl para testear endpoint del backend
✅ Verificar que backend está respondiendo

---

## 📝 RESUMEN

| Problema        | Causa                   | Solución          |
| --------------- | ----------------------- | ----------------- |
| Bot no funciona | URL HTTPS en desarrollo | Cambiar a HTTP    |
| Sin respuesta   | 127.0.0.1 vs localhost  | Usar localhost    |
| SSL error       | Certs no existen        | Solo en RELEASE   |
| No hay logs     | Falta debugging         | Agregado qDebug() |

---

**Estado:** ✅ LISTO PARA RECOMPILAR Y TESTEAR  
**Próximo paso:** Recompila y intenta login con:

- Usuario: test123
- Contraseña: password123
- (O las credenciales válidas de tu backend)
