# Arquitectura del cliente REP

```
QML (pages/, components/, theme/)      ← presentación, sin lógica de red
        │ propiedades / Q_INVOKABLE / señales
ViewModels (viewmodels/)               ← estado de pantalla, orquestación
        │
Servicios API (api/*Service)           ← un servicio por área funcional
        │ HttpClient::jsonRequest / errorMessage
HttpClient + ApiConfig                  ← peticiones, autenticación, errores, URL
        │
SessionManager + SecureTokenStorage     ← sesión (JWT en el llavero del sistema)
```

## Configuración del servidor

| Prioridad | Origen | Ejemplo |
|-----------|--------|---------|
| 1 | Variable de entorno `REP_API_URL` | `REP_API_URL=https://rep.colegio.edu/api ./appRep` |
| 2 | `QSettings` clave `api/baseUrl` | — |
| 3 | Valor por defecto | `http://localhost:8080/api` |

## Sesión

- El token se guarda en el llavero del sistema (QtKeychain). El perfil básico (id,
  nombre, rol) se guarda en `QSettings` para restaurar la sesión al reiniciar.
- La sesión expira según la claim `exp` del JWT; un 401 del servidor en cualquier
  petición autenticada cierra la sesión y devuelve al login.

## Sistema de diseño

- Tokens en `qml/theme/Theme.qml` (`Theme.primary`, `Theme.spacingM`, `Theme.radiusL`…).
- Reglas: no usar colores hexadecimales en las páginas; usar `PageHeader` como cabecera,
  `Card` para superficies, `AppButton`/`AppTextField` para acciones y formularios.
- Para añadir una página nueva: crear el `.qml` en `qml/pages/`, registrarlo en
  `QML_FILES` de `CMakeLists.txt` e importar `Rep` y `"../components"`.

## Compilación

Requisitos: Qt ≥ 6.8 (Quick, QuickControls2, Network) y QtKeychain para Qt 6.

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/ruta/a/Qt/6.8/gcc_64
cmake --build build -j
```

La lógica (red, sesión, modelos y ViewModels) se compila como biblioteca estática
`repcore`; `appRep` solo añade `main.cpp` y los QML. Así las pruebas enlazan el mismo
código que la aplicación.

## Pruebas

```bash
cmake -S . -B build -DREP_BUILD_TESTS=ON
cmake --build build -j
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure
```

| Suite | Qué cubre |
|---|---|
| `tst_preguntamodel` | Respuestas, notificación de cambios (autoguardado), preguntas sin responder |
| `tst_almacenlocal` | Caché por clave, borradores que sobreviven a limpiar la caché, escritura atómica |
| `tst_httpclient` | Mensajes `ApiError` del servidor, token Bearer, respaldo sin conexión de los GET |
| `tst_sincronizacion` | Cola de entregas: servidor que se apaga y vuelve, rechazo sin reintento, persistencia |

`tests/ServidorFalso.h` levanta un servidor HTTP local y un almacén de credenciales en
memoria (las pruebas no tocan el llavero ni los datos reales: `QStandardPaths` en modo
prueba).

## Funcionamiento sin conexión

- `AlmacenLocal`: última respuesta de cada consulta y archivos descargados, por usuario.
- `Sincronizacion`: estado de conexión y cola persistente de envíos que se reintenta al
  reconectar (banner en `Main.qml`).
- Borradores de actividades (`borradores/actividad-<id>.json`): respuestas y hora de
  inicio; el temporizador se ancla a esa hora.
