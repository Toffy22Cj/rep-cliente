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
