#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLoggingCategory>
#include <QDebug>
#include "viewmodels/LoginViewModel.h"
#include "viewmodels/EstudianteViewModel.h"
#include "viewmodels/ProfesorViewModel.h"
#include "models/PreguntaModel.h"
#include "core/SessionManager.h"
#include "models/Enums.h"

int main(int argc, char *argv[])
{
    QLoggingCategory::setFilterRules(
        "qt.qml.binding.removal.info=true\n"
        "qt.qml.engine.debug=true\n"
        "qt.qml.imports=true\n"
    );

    qDebug() << "=== APP INICIANDO ===";
    
    QGuiApplication app(argc, argv);
    qDebug() << "✓ QGuiApplication creado";

    Rep::SessionManager &sessionManager = Rep::SessionManager::instance();
    qDebug() << "✓ SessionManager creado";
    
    Rep::LoginViewModel loginViewModel;
    qDebug() << "✓ LoginViewModel creado";
    
    Rep::EstudianteViewModel estudianteViewModel;
    qDebug() << "✓ EstudianteViewModel creado";
    
    Rep::ProfesorViewModel profesorViewModel;
    qDebug() << "✓ ProfesorViewModel creado";

    QQmlApplicationEngine engine;
    qDebug() << "✓ QQmlApplicationEngine creado";
    
    // Register types
    qmlRegisterType<Rep::PreguntaModel>("Rep", 1, 0, "PreguntaModel");
    qRegisterMetaType<Rep::ActividadConPreguntasDTO>("ActividadConPreguntasDTO");
    qDebug() << "✓ Tipos registrados";

    engine.rootContext()->setContextProperty("sessionManager", &sessionManager);
    engine.rootContext()->setContextProperty("loginViewModel", &loginViewModel);
    engine.rootContext()->setContextProperty("estudianteViewModel", &estudianteViewModel);
    engine.rootContext()->setContextProperty("profesorViewModel", &profesorViewModel);
    qDebug() << "✓ Context properties configuradas";

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { 
            qDebug() << "❌ ERROR: objectCreationFailed";
            QCoreApplication::exit(-1); 
        },
        Qt::QueuedConnection
    );

    qDebug() << "⏳ ANTES de cargar QML";
    engine.loadFromModule("Rep", "Main");
    qDebug() << "✓ DESPUÉS de cargar QML";

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "❌ ERROR: No se crearon objetos root";
        return -1;
    }
    
    qDebug() << "✓ App iniciada correctamente";
    return app.exec();
}
