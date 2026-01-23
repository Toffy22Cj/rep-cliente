cmake_minimum_required(VERSION 3.16)

project(Rep VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appRep
    main.cpp
    api/AuthService.h api/AuthService.cpp
    api/EstudianteService.h api/EstudianteService.cpp
    api/ProfesorService.h api/ProfesorService.cpp
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
    models/PreguntaModel.h models/PreguntaModel.cpp
    viewmodels/LoginViewModel.h viewmodels/LoginViewModel.cpp
    viewmodels/EstudianteViewModel.h viewmodels/EstudianteViewModel.cpp
    viewmodels/ProfesorViewModel.h viewmodels/ProfesorViewModel.cpp
)

qt_add_qml_module(appRep
    URI Rep
    QML_FILES
        qml/Main.qml
        qml/pages/LoginPage.qml
        qml/pages/StudentDashboard.qml
        qml/pages/ActivityResolutionPage.qml
        qml/pages/TeacherDashboard.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appRep PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appRep
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
