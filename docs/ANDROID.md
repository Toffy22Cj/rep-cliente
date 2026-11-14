# App Android (estudiante y profesor)

La misma base de código del cliente de escritorio compila para Android. La lógica
(`repcore`: red, sesión, caché sin conexión, cola de envíos, descubrimiento del
servidor) es la misma; en el teléfono se carga la interfaz táctil `qml/movil/`.

| Rol | Pestañas |
|---|---|
| Estudiante | Actividades (resolver con temporizador y autoguardado, ver resultado), Notas (por periodo, PDF), Horario, Material |
| Profesor | Hoy (clases del día, entregas por revisar), Asistencia (Presente/Tarde/Excusa/Falta; **sin conexión se guarda y se envía al reconectar**), Calificar (actividades → entregas → nota y «Guardar y siguiente»), Horario; Material y Perfil en el menú |
| Administrador | La app indica usar el escritorio o el panel web |

## Conexión con el servidor

Igual que en escritorio: el teléfono busca el servidor en la red Wi-Fi del colegio, en
la red propia del servidor o por Bluetooth PAN, con o sin internet, y lo sigue si cambia
de IP. Se puede escribir la dirección a mano en «Servidor › Cambiar».

- Android permite enviar broadcast UDP y recibir la respuesta directa del servidor sin
  permisos especiales, que es lo que usa la búsqueda. Los anuncios pasivos por broadcast
  (puerto 47801) normalmente no llegan sin `MulticastLock`; no hacen falta.
- El servidor habla HTTP en la red local, por eso el manifiesto permite tráfico sin
  cifrar (`android/res/xml/network_security_config.xml`).
- El token se guarda en el almacenamiento privado de la app (`ArchivoPrivadoCredentialStore`);
  en Android no se usa QtKeychain (opción CMake `REP_USAR_KEYCHAIN=OFF` por defecto).

## Compilar el APK

Requisitos (los instala usted y acepta sus licencias):

- Qt 6.8 para **Android arm64-v8a** y Qt 6.8 de escritorio (herramientas de host),
  desde el instalador de Qt o `aqt`.
- Android SDK (platform 34, build-tools 34) y **NDK r26b (26.1.10909125)**, p. ej. con
  Android Studio › SDK Manager.
- JDK 17.

Con Qt Creator: abra `CMakeLists.txt`, elija el kit «Android Qt 6.8 arm64-v8a» y
compile; el APK queda en `build/.../android-build/build/outputs/apk/`.

Por línea de órdenes:

```bash
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/26.1.10909125
~/Qt/6.8.3/android_arm64_v8a/bin/qt-cmake -S . -B build-android -G Ninja \
    -DQT_HOST_PATH=$HOME/Qt/6.8.3/gcc_64 -DCMAKE_BUILD_TYPE=Release \
    -DANDROID_SDK_ROOT=$ANDROID_SDK_ROOT -DANDROID_NDK_ROOT=$ANDROID_NDK_ROOT
cmake --build build-android --target apk
```

El APK de depuración queda en
`build-android/android-build/build/outputs/apk/debug/android-build-debug.apk`; instálelo
con `adb install` o copiándolo al teléfono. Para publicar, firme el APK
(`QT_ANDROID_SIGN_APK` / Qt Creator › Build Android APK › Sign package).

Datos del paquete: `co.rep.movil`, mínimo Android 9 (API 28), objetivo API 34
(`CMakeLists.txt`, sección Android).

## Probar la interfaz móvil en el escritorio

```bash
REP_MOVIL=1 ./build/appRep
```

Abre la interfaz del teléfono en una ventana de 400×820 contra el mismo servidor.

## Estado

La interfaz móvil se probó en escritorio a tamaño de teléfono contra el servidor con
datos demo (estudiante, profesor, administrador) y la lógica compartida con las pruebas
QtTest. La compilación del APK no se pudo hacer en el entorno de desarrollo (requiere
aceptar las licencias del SDK de Android): compílelo con los pasos anteriores.
