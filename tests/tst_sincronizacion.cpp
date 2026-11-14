#include "ServidorFalso.h"
#include "core/SessionManager.h"
#include "core/Sincronizacion.h"

#include <QSettings>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QtTest>

using namespace Rep;

/*
 * Cola persistente de envíos: lo que se entrega sin conexión se guarda en disco y se
 * envía al volver el servidor; un rechazo del servidor no se reintenta.
 */
class TstSincronizacion : public QObject
{
    Q_OBJECT

    static void borrarCola()
    {
        QFile::remove(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                      + "/sin-conexion/pendientes-77.json");
    }

private slots:
    void cleanupTestCase() { borrarCola(); }

    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
        QCoreApplication::setApplicationName(QStringLiteral("rep-pruebas"));
        SecureTokenStorage::instance().setBackend(std::make_unique<AlmacenMemoria>());
        borrarCola(); // pruebas aisladas: sin restos de ejecuciones anteriores
        AuthUsuarioDTO u;
        u.id = 77;
        u.nombre = QStringLiteral("Prueba");
        u.rol = Rol::ESTUDIANTE;
        // Token con exp lejano (cabecera.payload.firma; la firma no se valida en el cliente)
        const QByteArray payload = QByteArray("{\"sub\":\"x\",\"exp\":4102444800}").toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
        SessionManager::instance().setSession(u, "e30." + QString::fromLatin1(payload) + ".firma");
        QVERIFY(SessionManager::instance().isAuthenticated());
    }

    void encolaYEnviaAlReconectar()
    {
        auto &sinc = Sincronizacion::instance();
        ServidorFalso s;
        s.responder(200, R"({"nota":4.5})");
        QSignalSpy completado(&sinc, &Sincronizacion::envioCompletado);

        sinc.encolar("POST", QUrl(s.base() + "/estudiante/77/actividades/4/resolver"), R"({"respuestas":[]})",
                     QStringLiteral("Entrega de la actividad 4"));
        QCOMPARE(sinc.pendientes(), 1);
        sinc.reintentarAhora();
        QVERIFY(completado.wait(5000));
        QCOMPARE(completado.first().at(0).toString(), QStringLiteral("Entrega de la actividad 4"));
        QCOMPARE(sinc.pendientes(), 0);
        QCOMPARE(s.peticiones.size(), 1);
        QCOMPARE(s.peticiones.first().metodo, QByteArray("POST"));
        QCOMPARE(s.peticiones.first().cuerpo, QByteArray(R"({"respuestas":[]})"));
        QVERIFY(s.peticiones.first().autorizacion.startsWith("Bearer "));
    }

    void sinServidorQuedaEnLaColaYSeEnviaCuandoVuelve()
    {
        auto &sinc = Sincronizacion::instance();
        quint16 puerto;
        QString url;
        {
            ServidorFalso apagado;
            puerto = apagado.puerto();
            url = apagado.base() + "/estudiante/77/actividades/5/resolver";
        } // el servidor se apaga

        sinc.encolar("POST", QUrl(url), R"({"respuestas":[1]})", QStringLiteral("Entrega de la actividad 5"));
        sinc.reintentarAhora();
        QTRY_VERIFY_WITH_TIMEOUT(!sinc.enLinea(), 5000);
        QCOMPARE(sinc.pendientes(), 1); // se conserva para reintentar

        ServidorFalso vuelve(puerto);
        QVERIFY(vuelve.puerto() == puerto);
        vuelve.responder(200, R"({"nota":3.0})");
        QSignalSpy completado(&sinc, &Sincronizacion::envioCompletado);
        sinc.reintentarAhora();
        QVERIFY(completado.wait(5000));
        QCOMPARE(sinc.pendientes(), 0);
        QVERIFY(sinc.enLinea());
        QCOMPARE(vuelve.peticiones.first().cuerpo, QByteArray(R"({"respuestas":[1]})"));
    }

    void rechazoDelServidorNoSeReintenta()
    {
        auto &sinc = Sincronizacion::instance();
        ServidorFalso s;
        s.responder(409, R"({"code":"ACTIVIDAD_NO_DISPONIBLE","message":"La actividad ya cerró"})");
        QSignalSpy rechazado(&sinc, &Sincronizacion::envioRechazado);
        sinc.encolar("POST", QUrl(s.base() + "/z"), "{}", QStringLiteral("Tardía"));
        sinc.reintentarAhora();
        QVERIFY(rechazado.wait(5000));
        QCOMPARE(rechazado.last().at(1).toString(), QStringLiteral("La actividad ya cerró"));
        QCOMPARE(sinc.pendientes(), 0);
        QCOMPARE(s.peticiones.size(), 1);
    }

    void encolarPeticionDesdeQmlArmaUrlYCuerpo()
    {
        auto &sinc = Sincronizacion::instance();
        ServidorFalso s;
        s.responder(200, "[]");
        QSettings().setValue("api/baseUrl", s.base());
        QSignalSpy completado(&sinc, &Sincronizacion::envioCompletado);
        // Lo que hace la asistencia móvil sin conexión
        const QVariantList cuerpo{QVariantMap{{"estudianteId", 5}, {"estado", "RETARDO"}}};
        sinc.encolarPeticion("post", "/profesor/asistencia?cursoId=1&materiaId=1&fecha=2026-11-14", cuerpo,
                             QStringLiteral("Asistencia"));
        sinc.reintentarAhora();
        QVERIFY(completado.wait(5000));
        QCOMPARE(s.peticiones.first().metodo, QByteArray("POST"));
        QCOMPARE(s.peticiones.first().ruta, QByteArray("/api/profesor/asistencia?cursoId=1&materiaId=1&fecha=2026-11-14"));
        QVERIFY(s.peticiones.first().cuerpo.contains("\"estado\":\"RETARDO\""));
        QSettings().remove("api/baseUrl");
    }

    void laColaPersisteEnDisco()
    {
        auto &sinc = Sincronizacion::instance();
        sinc.encolar("POST", QUrl("http://127.0.0.1:1/api/x"), "{}", QStringLiteral("Persistente"));
        const QString archivo = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                                + "/sin-conexion/pendientes-77.json";
        QFile f(archivo);
        QVERIFY(f.open(QIODevice::ReadOnly));
        QVERIFY(f.readAll().contains("Persistente"));
    }
};

QTEST_GUILESS_MAIN(TstSincronizacion)
#include "tst_sincronizacion.moc"
