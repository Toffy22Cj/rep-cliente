# REP - Sistema de Gestión Educativa

## 📋 Descripción del Proyecto

REP es un sistema de gestión educativa que permite a profesores y estudiantes gestionar actividades académicas, exámenes, asistencia y calificaciones. El sistema está compuesto por:

- **Frontend**: Aplicación de escritorio desarrollada en **Qt 6.8 + QML**
- **Backend**: API REST desarrollada en **Spring Boot** (Java)

---

## 🏗️ Arquitectura del Sistema

### Ubicación de Proyectos

```
/home/carlos/Proyectos/
├── REP/                    # Backend (Spring Boot)
│   └── src/main/java/com/rep/
│       ├── controller/apis/    # APIs REST
│       ├── service/           # Lógica de negocio
│       ├── repositories/      # Acceso a datos
│       └── model/            # Entidades
│
└── Rep-cliente/Rep/       # Frontend (Qt + QML)
    ├── api/               # Servicios HTTP
    ├── models/            # Modelos de datos
    ├── viewmodels/        # Lógica de presentación
    └── qml/              # Interfaces de usuario
        └── pages/        # Páginas de la aplicación
```

### Flujo de Datos

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   QML UI    │ ◄─────► │  ViewModel   │ ◄─────► │   Service    │
│  (View)     │         │   (Logic)    │         │   (HTTP)     │
└─────────────┘         └──────────────┘         └───────┬──────┘
                                                          │
                                                          ▼
                                                  ┌──────────────┐
                                                  │ Backend API  │
                                                  │ (Spring Boot)│
                                                  └──────────────┘
```

---

## 🌐 APIs del Backend

### URL Base
```
http://localhost:8080/api
```

### Autenticación

#### POST `/auth/login`
```json
Request:
{
  "identificacion": "string",
  "password": "string"
}

Response:
{
  "token": "string",
  "usuario": {
    "id": 1,
    "nombre": "string",
    "correo": "string",
    "rol": "PROFESOR | ESTUDIANTE"
  }
}
```

### APIs de Profesor

#### GET `/profesor/dashboard`
**Headers**: `Authorization: Bearer {token}`
```json
Response:
{
  "totalActividades": 7,
  "actividadesRecientes": 2,
  "cursosAsignados": 1
}
```

#### GET `/profesor/materias`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "nombre": "Matemáticas"
  }
]
```

#### GET `/profesor/cursos`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "nombre": null,
    "grado": 8,
    "grupo": "A",
    "cantidadEstudiantes": 25
  }
]
```

#### GET `/profesor/estudiantes/curso/{cursoId}`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "nombre": "Juan Pérez",
    "identificacion": "123456",
    "correo": "juan@example.com"
  }
]
```

#### GET `/actividades?materiaId={id}&cursoId={id}`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "titulo": "Examen Parcial",
    "tipo": "EXAMEN",
    "descripcion": "...",
    "fechaHoraEntrega": "2026-01-30",
    "duracionMinutos": 60,
    "profesorMateria": {
      "materia": {
        "nombre": "Matemáticas"
      }
    }
  }
]
```

#### POST `/actividades`
**Headers**: `Authorization: Bearer {token}`
```json
Request:
{
  "titulo": "string",
  "tipo": "EXAMEN | QUIZ | TALLER | TAREA",
  "descripcion": "string",
  "fechaEntrega": "2026-01-30",
  "duracionMinutos": 60,
  "materiaId": 1,
  "cursoId": 1
}

Response:
{
  "id": 9,
  "titulo": "...",
  ...
}
```

#### GET `/profesor/asistencia?cursoId={id}&materiaId={id}&fecha=YYYY-MM-DD`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "estudiante": {
      "id": 1,
      "nombre": "Juan Pérez"
    },
    "asistio": true,
    "observaciones": ""
  }
]
```

#### POST `/profesor/asistencia?cursoId={id}&materiaId={id}&fecha=YYYY-MM-DD`
**Headers**: `Authorization: Bearer {token}`
```json
Request: [
  {
    "estudianteId": 1,
    "asistio": true,
    "observaciones": ""
  }
]

Response: [...]  // Lista de asistencias guardadas
```

#### PUT `/actividades/{id}`
**Headers**: `Authorization: Bearer {token}`
```json
Request:
{
  "titulo": "string",
  "tipo": "EXAMEN | QUIZ | TALLER | TAREA",
  "descripcion": "string",
  "fechaEntrega": "2026-01-30",
  "duracionMinutos": 60,
  "materiaId": 1,
  "cursoId": 1
}

Response: true | false
```

#### GET `/profesor/actividades/{id}/respuestas`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "estudianteId": 101,
    "nombreEstudiante": "Ana Garcia",
    "nota": 4.5,
    "fechaEntrega": "2026-01-25T14:30:00",
    "calificada": true
  }
]
```

#### POST `/profesor/respuestas/{id}/calificar?nota={nota}`
**Headers**: `Authorization: Bearer {token}`
```json
// Empty Body
Response: 200 OK
```

### APIs de Estudiante

#### GET `/estudiante/{id}/materias`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "nombre": "Matemáticas"
  }
]
```

#### GET `/estudiante/{id}/actividades`
**Headers**: `Authorization: Bearer {token}`
```json
Response: [
  {
    "id": 1,
    "titulo": "Tarea 1",
    "tipo": "TAREA",
    "materiaNombre": "Matemáticas",
    "cursoNombre": "8A"
  }
]
```

#### GET `/actividades/{id}/preguntas`
**Headers**: `Authorization: Bearer {token}`
```json
Response: {
  "id": 1,
  "titulo": "Examen Final",
  "preguntas": [
    {
      "id": 10,
      "enunciado": "¿Pregunta 1?",
      "tipo": "MULTIPLE_CHOICE",
      "opciones": [...]
    }
  ]
}
```

#### POST `/estudiante/{id}/actividades/{actId}/resolver`
**Headers**: `Authorization: Bearer {token}`
```json
Request:
{
  "actividadId": 1,
  "estudianteId": 1,
  "fechaEntrega": "2026-01-25",
  "duracionMinutos": 45,
  "respuestas": [
    { "preguntaId": 10, "opcionId": 5 },
    { "preguntaId": 11, "respuestaAbierta": "Respuesta texto" }
  ]
}

Response:
{
  "nota": 5.0,
  "resultadosPreguntas": [...]
}
```

### APIs de Actividades

#### POST `/api/preguntas`
**Headers**: `Authorization: Bearer {token}`
```json
Request:
{
  "actividadId": 1,
  "enunciado": "¿Cuánto es 2+2?",
  "tipo": "MULTIPLE_CHOICE | OPEN",
  "opciones": [
    {
      "texto": "4",
      "esCorrecta": true
    },
    {
      "texto": "5",
      "esCorrecta": false
    }
  ]
}
```

---

## 📁 Estructura del Frontend (Qt/QML)

### Organización de Archivos

```
Rep-cliente/Rep/
├── CMakeLists.txt                 # Configuración del proyecto
├── main.cpp                       # Punto de entrada
│
├── api/                           # Capa de Servicios HTTP
│   ├── ApiConfig.h               # URL base del backend
│   ├── AuthService.cpp/h         # Servicio de autenticación
│   ├── ProfesorService.cpp/h     # Servicio de profesor
│   └── EstudianteService.cpp/h   # Servicio de estudiante
│
├── core/
│   └── SessionManager.h          # Gestión de sesión/token
│
├── models/                        # Modelos de Datos
│   ├── ActividadModel.h          # Modelo para lista de actividades
│   ├── MateriaModel.h            # Modelo para lista de materias
│   ├── CursoModel.h              # Modelo para lista de cursos
│   ├── PreguntaModel.cpp/h       # Modelo para preguntas
│   ├── StudentDTOs.h             # DTOs del estudiante
│   └── ProfesorDTOs.h            # DTOs del profesor
│
├── viewmodels/                    # ViewModels (Lógica de UI)
│   ├── LoginViewModel.cpp/h
│   ├── ProfesorViewModel.cpp/h
│   └── EstudianteViewModel.cpp/h
│
└── qml/                           # Interfaces de Usuario
    ├── Main.qml                  # Ventana principal
    ├── components/               # Componentes reutilizables
    │   ├── StatCard.qml
    │   └── DatePicker.qml
    └── pages/                    # Páginas de la aplicación
        ├── LoginPage.qml
        ├── TeacherDashboard.qml
        ├── StudentDashboard.qml
        ├── CoursesPage.qml
        ├── AttendancePage.qml
        ├── ActivityManagementPage.qml
        ├── ActivityResolutionPage.qml
        ├── QuestionEditorPage.qml
        ├── GradingPage.qml
        ├── ReportsPage.qml
        └── StudentsPage.qml
```

### Componentes Principales

#### 1. **Services** (`api/`)
Manejan la comunicación HTTP con el backend.

**Ejemplo**: `ProfesorService.cpp`
```cpp
void ProfesorService::fetchMaterias(const QString &token) {
    QUrl url(ApiConfig::baseUrl() + "/profesor/materias");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        // Parsear JSON y emitir señal
        emit materiasAsignadasFetched(materias);
    });
}
```

#### 2. **Models** (`models/`)
Modelos de datos para QML `ListView`/`ComboBox`.

**Ejemplo**: `ActividadModel.h`
```cpp
enum Roles {
    IdRole,
    TituloRole,
    TipoRole,
    DuracionRole,
    MateriaRole
};

QHash<int, QByteArray> roleNames() const override {
    return {
        {IdRole, "id"},
        {TituloRole, "titulo"},
        {TipoRole, "tipo"},
        {DuracionRole, "duracion"},
        {MateriaRole, "materia"}
    };
}
```

#### 3. **ViewModels** (`viewmodels/`)
Exponen datos y comandos a QML.

**Ejemplo**: `ProfesorViewModel.h`
```cpp
class ProfesorViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(ActividadModel* actividadModel READ actividadModel CONSTANT)
    Q_PROPERTY(MateriaModel* materiaModel READ materiaModel CONSTANT)
    
public:
    Q_INVOKABLE void loadMaterias();
    Q_INVOKABLE void loadActividades(long long materiaId, long long cursoId);
    Q_INVOKABLE void createActividad(...);
    
signals:
    void actividadCreada(long long id);
    void errorOccurred(const QString &error);
};
```

#### 4. **QML Pages** (`qml/pages/`)
Interfaces de usuario.

**Ejemplo**: Uso de ViewModel en QML
```qml
Page {
    Component.onCompleted: {
        profesorViewModel.loadMaterias()
        profesorViewModel.loadCursos()
    }
    
    ListView {
        model: profesorViewModel.actividadModel
        delegate: ItemDelegate {
            text: model.titulo  // 'titulo' viene del role
            onClicked: console.log(model.id)
        }
    }
    
    Connections {
        target: profesorViewModel
        function onActividadCreada(id) {
            console.log("Actividad creada:", id)
        }
    }
}
```

---

## 🔄 Flujo de Trabajo: Crear una Actividad

### 1. Usuario llena el formulario (QML)
```qml
Button {
    onClicked: {
        profesorViewModel.createActividad(
            tituloField.text,
            tipoCombo.currentText,
            descField.text,
            fechaField.text,
            parseInt(duracionField.text),
            materiaId,
            cursoId
        )
    }
}
```

### 2. ViewModel procesa (C++)
```cpp
void ProfesorViewModel::createActividad(...) {
    ActividadCreateDTO dto;
    dto.titulo = titulo;
    dto.tipo = tipo;
    // ...
    
    m_service->crearActividad(dto, SessionManager::instance().token());
}
```

### 3. Service envía HTTP (C++)
```cpp
void ProfesorService::crearActividad(const ActividadCreateDTO &dto, const QString &token) {
    QUrl url(ApiConfig::baseUrl() + "/actividades");
    QJsonObject json;
    json["titulo"] = dto.titulo;
    // ...
    
    QNetworkReply *reply = m_networkManager->post(createRequest(url, token), 
                                                    QJsonDocument(json).toJson());
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        QJsonObject response = QJsonDocument::fromJson(reply->readAll()).object();
        emit actividadCreada(response["id"].toLongLong());
    });
}
```

### 4. Backend procesa (Spring Boot)
```java
@PostMapping("/actividades")
public ResponseEntity<?> crearActividad(@RequestBody ActividadCreateDTO dto, 
                                        @AuthenticationPrincipal Usuario usuario) {
    ProfesorMateria pm = profesorMateriaRepository.findByProfesorIdAndMateriaIdAndCursoId(...);
    
    Actividad actividad = new Actividad();
    actividad.setTitulo(dto.getTitulo());
    actividad.setProfesorMateria(pm);
    // ...
    
    Actividad nueva = actividadRepository.save(actividad);
    return ResponseEntity.ok(ActividadDTO.fromEntity(nueva));
}
```

### 5. ViewModel notifica a QML
```cpp
// Signal emitida automáticamente
emit actividadCreada(id);
```

### 6. QML actualiza la UI
```qml
Connections {
    target: profesorViewModel
    function onActividadCreada(id) {
        // Recargar la lista
        refreshActividades()
    }
}
```

---

## 🛠️ Cómo Agregar una Nueva Funcionalidad

### Ejemplo: Agregar "Eliminar Actividad"

#### 1. Backend (Spring Boot)
```java
// En ActividadApi.java
@DeleteMapping("/actividades/{id}")
public ResponseEntity<Void> eliminarActividad(@PathVariable Long id, 
                                               @AuthenticationPrincipal Usuario usuario) {
    validacionService.validarProfesorActividad(usuario.getId(), id);
    actividadService.eliminarActividad(id);
    return ResponseEntity.noContent().build();
}
```

#### 2. Service (Frontend C++)
```cpp
// En ProfesorService.h
void eliminarActividad(long long id, const QString &token);

signals:
    void actividadEliminada(long long id);

// En ProfesorService.cpp
void ProfesorService::eliminarActividad(long long id, const QString &token) {
    QUrl url(ApiConfig::baseUrl() + QString("/actividades/%1").arg(id));
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(url, token));
    
    connect(reply, &QNetworkReply::finished, [this, reply, id]() {
        if (reply->error() == QNetworkReply::NoError) {
            emit actividadEliminada(id);
        }
    });
}
```

#### 3. ViewModel
```cpp
// En ProfesorViewModel.h
Q_INVOKABLE void deleteActividad(long long id);

// En ProfesorViewModel.cpp
void ProfesorViewModel::deleteActividad(long long id) {
    m_service->eliminarActividad(id, SessionManager::instance().token());
}

// En constructor, conectar señal
connect(m_service, &ProfesorService::actividadEliminada, this, [this](long long id) {
    // Recargar el modelo o remover el elemento
    // ...
});
```

#### 4. QML
```qml
Button {
    text: "🗑️ Eliminar"
    onClicked: {
        profesorViewModel.deleteActividad(model.id)
    }
}
```

---

## 🐛 Debugging y Solución de Problemas

### Problemas Comunes

#### 1. "QML Component is not ready"
**Causa**: Archivo QML no está en `CMakeLists.txt`
**Solución**: Agregar el archivo a la lista `QML_FILES` en `CMakeLists.txt` y reconstruir.

#### 2. "ReferenceError: xxx is not defined" en QML
**Causa**: El role del modelo no está definido en `roleNames()`
**Solución**: Agregar el role al modelo C++.

#### 3. Lista vacía en ComboBox/ListView
**Causas**:
- El modelo no se está poblando correctamente
- La señal del Service no está conectada al ViewModel
- El JSON del backend no coincide con el parsing del frontend

**Debug**: Agregar `qDebug() << "Datos recibidos:" << json;` en el Service.

#### 4. CORS o 401 Unauthorized
**Causa**: Token no se está enviando o está expirado
**Solución**: Verificar `SessionManager` y headers de las requests.

---

## 📝 Convenciones de Código

### Nomenclatura

- **C++ Classes**: `PascalCase` (ej. `ProfesorViewModel`)
- **C++ Functions**: `camelCase` (ej. `loadMaterias()`)
- **QML Files**: `PascalCase.qml` (ej. `TeacherDashboard.qml`)
- **QML Functions**: `camelCase` (ej. `refreshActividades()`)
- **Model Roles**: `camelCase` (ej. `"nombreEstudiante"`)

### Estructura de Commits
```
feat: Agregar página de reportes
fix: Corregir carga de asistencia vacía
refactor: Simplificar lógica de auto-refresh
docs: Actualizar documentación de APIs
```

---

## 🚀 Ejecución del Proyecto

### Backend (Spring Boot)
```bash
cd /home/carlos/Proyectos/REP
./mvnw spring-boot:run
```
El servidor se ejecutará en `http://localhost:8080`

### Frontend (Qt)
```bash
cd /home/carlos/Proyectos/Rep-cliente/Rep
mkdir build && cd build
cmake ..
make
./appRep
```

---

## 📚 Recursos Adicionales

### Código de Referencia
- **Backend APIs**: `/home/carlos/Proyectos/REP/src/main/java/com/rep/controller/apis/`
- **DTOs Backend**: `/home/carlos/Proyectos/REP/src/main/java/com/rep/dto/`
- **Services Frontend**: `/home/carlos/Proyectos/Rep-cliente/Rep/api/`
- **ViewModels**: `/home/carlos/Proyectos/Rep-cliente/Rep/viewmodels/`
- **QML Pages**: `/home/carlos/Proyectos/Rep-cliente/Rep/qml/pages/`

### Documentación Oficial
- [Qt QML Documentation](https://doc.qt.io/qt-6/qmlfirststeps.html)
- [Spring Boot REST](https://spring.io/guides/gs/rest-service/)
- [QNetworkAccessManager](https://doc.qt.io/qt-6/qnetworkaccessmanager.html)

---

## ✅ Checklist para Nuevas Features

- [ ] Crear endpoint en backend (`ActividadApi.java`, etc.)
- [ ] Probar endpoint con Postman/curl
- [ ] Crear método en Service frontend (`ProfesorService.cpp`)
- [ ] Conectar señal en ViewModel (`ProfesorViewModel.cpp`)
- [ ] Exponer método Q_INVOKABLE si es necesario
- [ ] Actualizar Model si hay nuevos datos (`ActividadModel.h`)
- [ ] Crear/Actualizar QML Page
- [ ] Agregar archivo QML a `CMakeLists.txt` si es nuevo
- [ ] Rebuild del proyecto
- [ ] Probar flujo completo

---

**Última actualización**: 2026-01-23
**Versión**: 1.0
