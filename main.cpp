#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLoggingCategory>
#include <QDebug>
#include "viewmodels/LoginViewModel.h"
#include "viewmodels/EstudianteViewModel.h"
#include "viewmodels/ProfesorViewModel.h"
#include "viewmodels/ReportsViewModel.h"
#include "viewmodels/AdminViewModel.h"
#include "models/PreguntaModel.h"
#include "core/SessionManager.h"
#include "models/Enums.h"

#include "api/ApiConfig.h"

int main(int argc, char *argv[])
{
    QLoggingCategory::setFilterRules(
        "qt.qml.binding.removal.info=true\n"
        "qt.qml.engine.debug=true\n"
        "qt.qml.imports=true\n"
    );

    qDebug() << "=== APP INICIANDO ===";
    Rep::ApiConfig::setupSSL();
    qDebug() << "✓ SSL Configurado";
    
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

    Rep::ReportsViewModel reportsViewModel;
    qDebug() << "✓ ReportsViewModel creado";

    Rep::AdminViewModel adminViewModel;
    qDebug() << "✓ AdminViewModel creado";

    QQmlApplicationEngine engine;
    qDebug() << "✓ QQmlApplicationEngine creado";
    
    // Register types
    qmlRegisterType<Rep::PreguntaModel>("Rep", 1, 0, "PreguntaModel");
    
    // Register DTOs for signal/slot connections
    qRegisterMetaType<Rep::LoginResponse>("LoginResponse");
    qRegisterMetaType<Rep::MateriaDTO>("MateriaDTO");
    qRegisterMetaType<QList<Rep::MateriaDTO>>("QList<Rep::MateriaDTO>");
    qRegisterMetaType<Rep::ActividadDTO>("ActividadDTO");
    qRegisterMetaType<QList<Rep::ActividadDTO>>("QList<Rep::ActividadDTO>");
    qRegisterMetaType<Rep::ActividadConPreguntasDTO>("ActividadConPreguntasDTO");
    qRegisterMetaType<Rep::ResultadoActividadDTO>("ResultadoActividadDTO");
    qRegisterMetaType<Rep::ProfesorDashboardDTO>("ProfesorDashboardDTO");
    qRegisterMetaType<Rep::CursoDTO>("CursoDTO");
    qRegisterMetaType<QList<Rep::CursoDTO>>("QList<Rep::CursoDTO>");
    qRegisterMetaType<Rep::MateriaAsignadaDTO>("MateriaAsignadaDTO");
    qRegisterMetaType<QList<Rep::MateriaAsignadaDTO>>("QList<Rep::MateriaAsignadaDTO>");
    qRegisterMetaType<Rep::EstudianteSimplificadoDTO>("EstudianteSimplificadoDTO");
    qRegisterMetaType<QList<Rep::EstudianteSimplificadoDTO>>("QList<Rep::EstudianteSimplificadoDTO>");
    qRegisterMetaType<Rep::AsistenciaDTO>("AsistenciaDTO");
    qRegisterMetaType<QList<Rep::AsistenciaDTO>>("QList<Rep::AsistenciaDTO>");
    qRegisterMetaType<Rep::ReportePromedioDTO>("ReportePromedioDTO");
    qRegisterMetaType<QList<Rep::ReportePromedioDTO>>("QList<Rep::ReportePromedioDTO>");
    qRegisterMetaType<Rep::ReporteEntregaDTO>("ReporteEntregaDTO");
    qRegisterMetaType<QList<Rep::ReporteEntregaDTO>>("QList<Rep::ReporteEntregaDTO>");
    qRegisterMetaType<Rep::EstadisticaActividadDTO>("EstadisticaActividadDTO");
    
    qDebug() << "✓ Tipos registrados";

    engine.rootContext()->setContextProperty("sessionManager", &sessionManager);
    engine.rootContext()->setContextProperty("loginViewModel", &loginViewModel);
    engine.rootContext()->setContextProperty("estudianteViewModel", &estudianteViewModel);
    engine.rootContext()->setContextProperty("profesorViewModel", &profesorViewModel);
    engine.rootContext()->setContextProperty("reportsViewModel", &reportsViewModel);
    engine.rootContext()->setContextProperty("adminViewModel", &adminViewModel);
    qDebug() << "✓ Context properties configuradas";

    qDebug() << "⏳ Conectando objectCreationFailed...";
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
