#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "viewmodels/LoginViewModel.h"
#include "viewmodels/EstudianteViewModel.h"
#include "viewmodels/ProfesorViewModel.h"
#include "viewmodels/ReportsViewModel.h"
#include "viewmodels/AdminViewModel.h"
#include "models/PreguntaModel.h"
#include "api/ApiCliente.h"
#include "core/SessionManager.h"
#include "core/Sincronizacion.h"
#include "core/security/SecureTokenStorage.h"
#include "core/security/QtKeychainCredentialStore.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    // Necesarios para que QSettings use una ubicación estable (perfil de sesión, URL de API)
    QGuiApplication::setOrganizationName(QStringLiteral("REP"));
    QGuiApplication::setOrganizationDomain(QStringLiteral("rep.local"));
    QGuiApplication::setApplicationName(QStringLiteral("REP Cliente"));
    QGuiApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));

    // Estilo base sobre el que se aplica el tema propio (qml/theme/Theme.qml)
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // El token JWT se guarda en el llavero del sistema operativo
    Rep::SecureTokenStorage::instance().setBackend(
        std::make_unique<Rep::Security::QtKeychainCredentialStore>());

    Rep::SessionManager &sessionManager = Rep::SessionManager::instance();
    Rep::LoginViewModel loginViewModel;
    Rep::EstudianteViewModel estudianteViewModel;
    Rep::ProfesorViewModel profesorViewModel;
    Rep::ReportsViewModel reportsViewModel;
    Rep::AdminViewModel adminViewModel;
    Rep::ApiCliente apiCliente;

    QQmlApplicationEngine engine;
    qmlRegisterType<Rep::PreguntaModel>("Rep", 1, 0, "PreguntaModel");
    qRegisterMetaType<Rep::ActividadConPreguntasDTO>("ActividadConPreguntasDTO");

    QQmlContext *context = engine.rootContext();
    context->setContextProperty("sessionManager", &sessionManager);
    context->setContextProperty("loginViewModel", &loginViewModel);
    context->setContextProperty("estudianteViewModel", &estudianteViewModel);
    context->setContextProperty("profesorViewModel", &profesorViewModel);
    context->setContextProperty("reportsViewModel", &reportsViewModel);
    context->setContextProperty("adminViewModel", &adminViewModel);
    // Cliente genérico de la API para las páginas QML (archivos, preguntas, material)
    context->setContextProperty("api", &apiCliente);
    // Estado de conexión y envíos pendientes (modo sin conexión)
    context->setContextProperty("sincronizacion", &Rep::Sincronizacion::instance());

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Rep", "Main");
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
