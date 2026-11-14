cmake_minimum_required(VERSION 3.16)

project(Rep VERSION 0.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 Network)
option(REP_BUILD_TESTS "Compilar las pruebas automáticas (QtTest/CTest)" ON)
# QtKeychain: almacenamiento seguro del token en el llavero del sistema.
# Si está instalado fuera de las rutas estándar, use -DCMAKE_PREFIX_PATH=<ruta>.
find_package(Qt6Keychain REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

set(HEADERS
    api/ApiConfig.h
    api/HttpClient.h
    api/ApiCliente.h
    api/AuthService.h
    api/EstudianteService.h
    api/ProfesorService.h
    api/AdminService.h
    core/SessionManager.h
    core/AlmacenLocal.h
    core/Sincronizacion.h
    core/security/ICredentialStore.h
    core/security/SecureTokenStorage.h
    core/security/QtKeychainCredentialStore.h
    models/Enums.h
    models/Usuario.h
    models/Profesor.h
    models/Estudiante.h
    models/AuthDTOs.h
    models/AdminDTOs.h
    models/StudentDTOs.h
    models/ProfesorDTOs.h
    models/MateriaModel.h
    models/ActividadModel.h
    models/PreguntaModel.h
    models/CursoModel.h
    viewmodels/LoginViewModel.h
    viewmodels/EstudianteViewModel.h
    viewmodels/ProfesorViewModel.h
    viewmodels/ReportsViewModel.h
    viewmodels/AdminViewModel.h
)

set(SOURCES
    api/HttpClient.cpp
    api/ApiCliente.cpp
    api/AuthService.cpp
    api/EstudianteService.cpp
    api/ProfesorService.cpp
    api/AdminService.cpp
    core/AlmacenLocal.cpp
    core/Sincronizacion.cpp
    core/security/SecureTokenStorage.cpp
    core/security/QtKeychainCredentialStore.cpp
    models/PreguntaModel.cpp
    viewmodels/LoginViewModel.cpp
    viewmodels/EstudianteViewModel.cpp
    viewmodels/ProfesorViewModel.cpp
    viewmodels/ReportsViewModel.cpp
    viewmodels/AdminViewModel.cpp
)

# Lógica de la aplicación (red, sesión, modelos, ViewModels) en una biblioteca que
# enlazan tanto la aplicación como las pruebas automáticas.
qt_add_library(repcore STATIC ${HEADERS} ${SOURCES})
target_include_directories(repcore PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(repcore PUBLIC Qt6::Quick Qt6::Network qt6keychain)

qt_add_executable(appRep main.cpp)

target_compile_definitions(appRep PRIVATE PROJECT_VERSION_STRING="${PROJECT_VERSION}")

# Tokens de diseño accesibles con "import Rep" como singleton Theme
set_source_files_properties(qml/theme/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

set(QML_FILES
    qml/Main.qml
    qml/theme/Theme.qml
    qml/components/Adjunto.qml
    qml/components/ApiRequests.qml
    qml/components/AppButton.qml
    qml/components/AppTabButton.qml
    qml/components/AppTextField.qml
    qml/components/Avatar.qml
    qml/components/Badge.qml
    qml/components/BannerConexion.qml
    qml/components/Toast.qml
    qml/components/SelectorPeriodo.qml
    qml/components/ResultadoActividad.qml
    qml/components/Card.qml
    qml/components/DatePicker.qml
    qml/components/EmptyState.qml
    qml/components/PageHeader.qml
    qml/components/StatCard.qml
    qml/components/UserChip.qml
    qml/pages/LoginPage.qml
    qml/pages/StudentDashboard.qml
    qml/pages/ActivityResolutionPage.qml
    qml/pages/TeacherDashboard.qml
    qml/pages/ActivityManagementPage.qml
    qml/pages/AttendancePage.qml
    qml/pages/QuestionEditorPage.qml
    qml/pages/GradingPage.qml
    qml/pages/CoursesPage.qml
    qml/pages/StudentsPage.qml
    qml/pages/ReportsPage.qml
    qml/pages/AdminDashboard.qml
    qml/pages/UserManagementPage.qml
    qml/pages/CourseManagementPage.qml
    qml/pages/SubjectManagementPage.qml
    qml/pages/AssignmentsManagementPage.qml
    qml/pages/MaterialPage.qml
    qml/pages/PerfilPage.qml
    qml/pages/RegistroPage.qml
    qml/pages/PeriodosPage.qml
    qml/pages/MisNotasPage.qml
    qml/pages/PlanillaNotasPage.qml
)

qt_add_qml_module(appRep
    URI Rep
    VERSION 1.0
    QML_FILES ${QML_FILES}
)

set_target_properties(appRep PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRep
    PRIVATE repcore Qt6::Quick Qt6::QuickControls2 Qt6::Network qt6keychain
)

if(REP_BUILD_TESTS)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    enable_testing()
    add_subdirectory(tests)
endif()

include(GNUInstallDirs)
install(TARGETS appRep
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
