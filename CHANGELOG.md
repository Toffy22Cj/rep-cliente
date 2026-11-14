# Changelog — REP Cliente (Qt 6 / QML)

## [1.1.0] — 2026-11-14
### Nuevo
- **App Android** para estudiante y profesor (`qml/movil/`, `android/`, `docs/ANDROID.md`):
  navegación inferior por rol; actividades con resolución y resultado, notas por
  periodo, horario, material; profesor: clases de hoy, asistencia táctil con guardado
  sin conexión, calificación móvil con «Guardar y siguiente». `REP_MOVIL=1` la abre en
  escritorio.
- **Horario de clases**: gestión del administrador (`HorarioPage`, sin cruces) y
  «Mi horario» para estudiante y profesor (`VistaHorario`, resalta la clase en curso).
- `Sincronizacion.encolarPeticion` para encolar desde QML cualquier envío sin conexión.
- `ArchivoPrivadoCredentialStore` y opción `REP_USAR_KEYCHAIN` (desactivada en Android).
- `PageHeader` compacto en pantallas estrechas.

## [1.0.0] — 2026-11-14
### Nuevo
- **Descubrimiento del servidor** (`core/Descubrimiento`, propiedad `descubrimiento`):
  busca servidores REP por broadcast en todas las redes del equipo, multicast y
  localhost; escucha sus anuncios; la primera vez usa el único que encuentre; si el
  servidor cambia de IP lo sigue por su id y mueve la cola de envíos pendientes.
- Inicio de sesión: indicador del servidor en uso y selector (`SelectorServidor`) con
  los encontrados y dirección escrita a mano (validada contra `/api/public/servidor`).
- Contraseña provisional: tras el login se abre "Cambie su contraseña" sin poder salir
  hasta cambiarla.
- Pruebas: `tst_descubrimiento` (búsqueda, elección automática, reconexión por id,
  otro servidor no reemplaza al guardado, dirección manual).
- Iconos de la aplicación (`empaquetado/recursos`).

## [0.5.1] — 2026-11-14
### Corregido
- **Mi perfil** no abría desde el menú de usuario (ruta relativa a `components/`).
  El panel del profesor ahora tiene menú de usuario y "Mi perfil" en el menú lateral.
- Las actividades ya entregadas mostraban "Resolver" y el servidor negaba el acceso.

### Nuevo
- Panel del estudiante: "✔ Hecho" con la nota, "Ver resultado", "Continuar" en las
  empezadas, "Vencida" y "Enviada · se sincronizará" sin conexión.
- Resultado de la actividad (`ResultadoActividad`): nota, observaciones y, si el
  profesor lo permite, la respuesta del estudiante y la correcta por pregunta.
- Profesor: opción "Mostrar las respuestas correctas al estudiante después de entregar"
  al crear o editar una actividad y en el menú de cada actividad.
- Editor de preguntas: estado "✔ todo guardado" / "hay una pregunta sin guardar",
  botón "Listo", avisos al guardar o eliminar y confirmación al salir con una pregunta
  sin guardar.

## [0.5.0] — 2026-11-13
### Nuevo
- **Evaluación con temporizador**: cuenta regresiva anclada a la primera apertura,
  envío automático al terminar (se encola sin conexión), aviso de preguntas sin
  responder y modo pantalla completa.
- **Autoguardado**: las respuestas y la hora de inicio se guardan en disco en cada
  cambio (escritura atómica); al reabrir se recuperan y el reloj no se reinicia.
- **Periodos académicos**: pantalla de administración y selector de periodo en
  "Mis notas" y en la planilla (columnas por periodo y nota final ponderada).
- **Asistencia**: botonera Presente/Retardo/Excusa/Ausente, conteo y "Todos presentes".
- **Pruebas automáticas** (QtTest + CTest, `tests/`): modelo de preguntas, almacén local,
  contrato de errores y respaldo sin conexión, cola de sincronización con servidor
  falso. `ctest --test-dir build --output-on-failure`.
- CI en GitHub Actions (Qt 6.8.3 + QtKeychain + ctest).

### Cambiado
- La lógica se compila como biblioteca `repcore` enlazada por la app y las pruebas
  (opción `REP_BUILD_TESTS`, activa por defecto).
- Las listas de estudiantes muestran el nombre completo.

## [0.4.0] — 2026-11-13
### Nuevo
- **Mi perfil** (todos los roles, desde el menú del usuario): datos personales, cambio de
  contraseña con requisitos visibles y borrado de los datos guardados sin conexión.
- **Mis notas** (estudiante): promedio y desempeño por materia, estado de cada actividad,
  faltas, detalle de la corrección y boletín en PDF.
- **Planilla de notas** (profesor): estudiantes × actividades con promedios, desempeño,
  faltas y exportación a Excel/PDF; la cabecera de cada actividad abre su calificación.
- **Calificar** rediseñada en vista dividida, con "Guardar y siguiente".
- **Actividades**: por materia y curso reales (antes curso fijo 1), crear, editar (antes no
  guardaba), duplicar con preguntas, publicar/ocultar, eliminar y estadísticas.
- **Usuarios** (admin): alta de usuarios, edición sin reactivar cuentas, cambio de curso,
  filtro "Por activar" para solicitudes del registro público, eliminación.
- **Solicitar cuenta** de estudiante desde el inicio de sesión.
- Asistencia: accesos a los días ya registrados; Estudiantes: exportar CSV.
- **Sin conexión**: banner de estado, caché persistente por usuario de consultas y
  archivos (`AlmacenLocal`, revalidación con `ETag`), cola persistente de entregas que se
  envía sola al reconectar (`Sincronizacion`), avisos (`Toast`).

## [0.3.0] — 2026-11-13
### Nuevo
- **Material de estudio** (`MaterialPage`): el profesor publica archivos por materia y
  curso y los elimina; el estudiante los ve, filtra por materia y abre. Accesos desde el
  menú lateral del profesor y la cabecera del estudiante.
- **Adjuntos en preguntas**: el editor permite adjuntar imágenes, PDF, documentos, audio
  o vídeo; las imágenes se ven en línea al resolver la actividad y el resto se abre con la
  aplicación del sistema (componente `Adjunto`).
- `ApiCliente` (propiedad de contexto `api`): peticiones JSON genéricas, descarga con
  caché local y escritura atómica, subida multipart. `ApiRequests.qml` lo envuelve con
  callbacks para las páginas.

### Corregido
- **Las preguntas creadas no se mostraban**: la lista del editor era un marcador de
  posición (`model: 0`). Ahora se cargan del servidor, con opciones, respuesta correcta,
  adjunto y botón de eliminar.
- El editor solo admitía 2 opciones y no gestionaba verdadero/falso; ahora 2–5 opciones
  con selección de la correcta, verdadero/falso y respuesta abierta, con validación.
- Tipo de actividad "TAREA" eliminado del formulario (el servidor no lo admite).
- Opción de menú "Configuración" sin pantalla sustituida por "Material de estudio".

## [0.2.1] — 2026-11-13
- Dashboard del profesor: aviso cuando no tiene materias asignadas, con instrucciones.
- Logs de red en la categoría `rep.api`, silenciosa por defecto
  (`QT_LOGGING_RULES="rep.api.debug=true"` para depurar).
- Compatible con el nuevo formato de errores del backend (`ApiError` con `code` y
  `message`): se muestra el mensaje del servidor, p. ej. «La tarjeta de identidad (TI)
  debe tener exactamente 10 dígitos (tiene 6)».

## [0.2.0] — 2026-11-12 · Refactorización, corrección de errores y rediseño

### Seguridad
- El JWT ya no se escribe en el log (antes se volcaba la respuesta completa del login).
- Cierre automático de sesión cuando el servidor responde 401 a una petición autenticada
  (token caducado o cuenta desactivada).
- La validez de la sesión se calcula a partir de la claim `exp` del propio JWT.

### Errores corregidos
- **Actividades del estudiante no se cargaban** al abrir el dashboard: un único indicador
  `isLoading` hacía que la segunda carga (actividades) se descartara tras iniciar la de
  materias. Ahora se cuentan las peticiones pendientes.
- **Sesión restaurada rota**: al reiniciar se recuperaba el token pero no el usuario
  (id sin inicializar, rol por defecto). Se persiste el perfil básico (no sensible).
- **Login correcto que volvía al login** si el llavero del sistema no estaba disponible
  (la expiración solo se guardaba si el llavero funcionaba).
- **Asistencia vacía al entrar**: la carga solo se disparaba si los combos cambiaban con
  la página abierta. Además la fecha por defecto usaba UTC (por la noche proponía el día
  siguiente en Colombia).
- **Asignaciones sin botón Volver** (el usuario quedaba atrapado en la pantalla).
- **Temporizador falso** "Tiempo: 10:00" en la resolución de actividades (eliminado).
- Duración enviada al entregar una actividad: antes fija en 10 min, ahora la real.
- Dashboard del profesor ocupaba solo ~600 px por un bucle de layout.
- Mensajes de error genéricos de Qt sustituidos por el mensaje del servidor o un texto
  claro por código HTTP (sin conexión, 403, 404, 409, 429, 5xx…).

### Arquitectura
- `api/HttpClient`: construcción de peticiones y tratamiento de errores compartidos por
  todos los servicios (antes duplicado en cada uno).
- `api/ApiConfig`: URL configurable con `REP_API_URL` o `QSettings` (`api/baseUrl`);
  se eliminaron las URLs `http://localhost:8080` fijas de `EstudianteService`.
- `SessionManager`: conversión de roles centralizada, perfil persistido, iniciales.
- `main.cpp`: sin reglas de logging de depuración; nombre de organización/aplicación
  para `QSettings`.
- `CMakeLists.txt`: sin entradas duplicadas ni rutas del sistema fijas.

### Rediseño de la interfaz
- **Sistema de diseño** `qml/theme/Theme.qml` (singleton, `import Rep`): colores,
  tipografía, espaciado, radios y animaciones. Ninguna página usa ya colores
  hexadecimales directamente.
- **Componentes reutilizables** en `qml/components/`: `PageHeader`, `UserChip`,
  `Avatar`, `Card`, `AppButton` (primary/secondary/danger/ghost), `AppTextField`,
  `AppTabButton`, `Badge`, `EmptyState`, `StatCard`.
- Paleta global aplicada a todos los controles estándar.
- Nuevos: pantalla de login a dos columnas, dashboards de administrador y estudiante
  (filtro por materia, tarjetas de actividad, estado vacío), cabecera unificada con
  menú de usuario en todas las páginas, transiciones entre pantallas, búsqueda de
  usuarios funcional.
- Eliminada la tarjeta "Configuración" del panel de administración, que no tenía
  ninguna pantalla asociada.

### Verificación
- Compilación completa (C++ y QML) y recorrido automático de todas las pantallas con
  los tres roles contra el backend real (H2): sin errores ni advertencias de QML.
