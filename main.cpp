#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "viewmodels/LoginViewModel.h"
#include "viewmodels/EstudianteViewModel.h"
#include "viewmodels/ProfesorViewModel.h"
#include "models/PreguntaModel.h"
#include "core/SessionManager.h"
#include "models/Enums.h"

// Note: TipoActividad is not used in C++ viewmodels yet, but registered for QML safety if needed.
// However, to avoid conflicts with Enums.h, we only register what's necessary.

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Rep::SessionManager &sessionManager = Rep::SessionManager::instance();
    Rep::LoginViewModel loginViewModel;
    Rep::EstudianteViewModel estudianteViewModel;
    Rep::ProfesorViewModel profesorViewModel;

    QQmlApplicationEngine engine;
    
    // Register types
    qmlRegisterType<Rep::PreguntaModel>("Rep", 1, 0, "PreguntaModel");
    qRegisterMetaType<Rep::ActividadConPreguntasDTO>("ActividadConPreguntasDTO");

    engine.rootContext()->setContextProperty("sessionManager", &sessionManager);
    engine.rootContext()->setContextProperty("loginViewModel", &loginViewModel);
    engine.rootContext()->setContextProperty("estudianteViewModel", &estudianteViewModel);
    engine.rootContext()->setContextProperty("profesorViewModel", &profesorViewModel);

    const QUrl url(QStringLiteral("qrc:/qt/qml/Rep/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
