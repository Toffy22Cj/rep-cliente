cmake_minimum_required(VERSION 3.16)

project(Rep VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

set(HEADERS
    api/ApiConfig.h
    api/AuthService.h
    api/EstudianteService.h
    api/ProfesorService.h
    core/SessionManager.h
    models/Enums.h
    models/Usuario.h
    models/Profesor.h
    models/Estudiante.h
    models/AuthDTOs.h
    models/StudentDTOs.h
    models/ProfesorDTOs.h
    models/MateriaModel.h
    models/ActividadModel.h
    models/PreguntaModel.h
    models/CursoModel.h
    viewmodels/LoginViewModel.h
    viewmodels/EstudianteViewModel.h
    viewmodels/ProfesorViewModel.h
)

set(SOURCES
    main.cpp
    api/AuthService.cpp
    api/EstudianteService.cpp
    api/ProfesorService.cpp
    models/PreguntaModel.cpp
    viewmodels/LoginViewModel.cpp
    viewmodels/EstudianteViewModel.cpp
    viewmodels/ProfesorViewModel.cpp
)

qt_add_executable(appRep
    ${HEADERS}
    ${SOURCES}
)

set(QML_FILES
    qml/Main.qml
    qml/pages/LoginPage.qml
    qml/pages/StudentDashboard.qml
    qml/pages/ActivityResolutionPage.qml
    qml/pages/TeacherDashboard.qml
    qml/pages/ActivityManagementPage.qml
    qml/pages/AttendancePage.qml
    qml/pages/QuestionEditorPage.qml
    qml/pages/GradingPage.qml
    qml/components/StatCard.qml
    qml/pages/CoursesPage.qml
    qml/pages/ReportsPage.qml
    qml/components/DatePicker.qml
)

qt_add_qml_module(appRep
    URI Rep
    QML_FILES
        ${QML_FILES}
)

set_target_properties(appRep PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRep
    PRIVATE Qt6::Quick Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appRep
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
