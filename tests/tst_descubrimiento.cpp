#include "ServidorFalso.h"
#include "core/Descubrimiento.h"
#include "core/SessionManager.h"
#include "core/Sincronizacion.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QUdpSocket>
#include <QtTest>

using namespace Rep;

/* Servidor UDP falso que responde a las búsquedas como lo hace el backend. */
class RespondedorFalso : public QObject
{
public:
    QString id = QStringLiteral("11111111-2222-3333-4444-555555555555");
    QString nombre = QStringLiteral("REP del colegio");
    int puertoHttp = 8080;
    int busquedas = 0;
    QUdpSocket socket;

    RespondedorFalso()
    {
        socket.bind(QHostAddress::LocalHost, 0);
        connect(&socket, &QUdpSocket::readyRead, this, [this]() {
            while (socket.hasPendingDatagrams()) {
                QByteArray d(int(socket.pendingDatagramSize()), 0);
                QHostAddress origen;
                quint16 puerto;
                socket.readDatagram(d.data(), d.size(), &origen, &puerto);
                if (!d.contains("buscar")) continue;
                ++busquedas;
                const QJsonObject r{{"rep", "servidor"}, {"v", 1}, {"id", id}, {"nombre", nombre},
                                    {"version", "1.0.0"}, {"puerto", puertoHttp}};
                socket.writeDatagram(QJsonDocument(r).toJson(QJsonDocument::Compact), origen, puerto);
            }
        });
    }
};

class TstDescubrimiento : public QObject
{
    Q_OBJECT
    RespondedorFalso *respondedor = nullptr;

    static void limpiarServidor()
    {
        QSettings s;
        s.remove("api/baseUrl");
        s.remove("api/servidorId");
        s.remove("api/servidorNombre");
    }

private slots:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
        QCoreApplication::setOrganizationName(QStringLiteral("rep-pruebas"));
        QCoreApplication::setApplicationName(QStringLiteral("descubrimiento"));
        qputenv("REP_API_URL", QByteArray()); // no debe interferir
        qunsetenv("REP_API_URL");
        respondedor = new RespondedorFalso;
        QSettings().setValue("red/puertoDescubrimiento", respondedor->socket.localPort());
        QSettings().setValue("red/puertoAnuncio", 47998); // aislado de servidores reales (47801)
        limpiarServidor();
    }

    void cleanupTestCase()
    {
        limpiarServidor();
        QSettings().remove("red");
        delete respondedor;
    }

    void normalizaDireccionesEscritasAMano()
    {
        QCOMPARE(Descubrimiento::normalizarDireccion("192.168.1.10"), QStringLiteral("http://192.168.1.10:8080"));
        QCOMPARE(Descubrimiento::normalizarDireccion(" servidor:9000/api "), QStringLiteral("http://servidor:9000"));
        QCOMPARE(Descubrimiento::normalizarDireccion("http://10.0.0.5:8080/"), QStringLiteral("http://10.0.0.5:8080"));
        QCOMPARE(Descubrimiento::normalizarDireccion("https://rep.colegio.edu"), QStringLiteral("https://rep.colegio.edu"));
        QVERIFY(Descubrimiento::normalizarDireccion("").isEmpty());
        QVERIFY(Descubrimiento::normalizarDireccion("ftp://x").isEmpty());
    }

    void sinServidorConfiguradoEligeElUnicoQueEncuentra()
    {
        auto &d = Descubrimiento::instance();
        limpiarServidor();
        QVERIFY(!d.configurado());
        QSignalSpy fin(&d, &Descubrimiento::busquedaTerminada);
        d.iniciar();
        QVERIFY(fin.wait(5000));
        QCOMPARE(d.servidores().size(), 1);
        const QVariantMap s = d.servidores().first().toMap();
        QCOMPARE(s.value("nombre").toString(), respondedor->nombre);
        QVERIFY(s.value("local").toBool()); // respondió por localhost
        QCOMPARE(s.value("url").toString(), QStringLiteral("http://localhost:8080"));
        // Elegido solo
        QVERIFY(d.configurado());
        QCOMPARE(d.servidorId(), respondedor->id);
        QCOMPARE(d.servidorUrl(), QStringLiteral("http://localhost:8080"));
    }

    void siElServidorCambiaDeDireccionSeReconectaYMueveLosPendientes()
    {
        auto &d = Descubrimiento::instance();
        auto &sinc = Sincronizacion::instance();
        // Estado: servidor guardado en el puerto 8080 con un envío pendiente hacia él
        SecureTokenStorage::instance().setBackend(std::make_unique<AlmacenMemoria>());
        AuthUsuarioDTO u;
        u.id = 91;
        u.nombre = QStringLiteral("Prueba");
        SessionManager::instance().setSession(u, QStringLiteral("e30.e30.x"));
        sinc.encolar("POST", QUrl("http://localhost:8080/api/estudiante/91/actividades/1/resolver"), "{}",
                     QStringLiteral("Entrega"));

        // El servidor vuelve en otro puerto (en una red real: otra IP)
        respondedor->puertoHttp = 9090;
        QSignalSpy reconectado(&d, &Descubrimiento::reconectado);
        d.reconectar();
        QVERIFY(reconectado.wait(5000));
        QCOMPARE(d.servidorUrl(), QStringLiteral("http://localhost:9090"));
        QCOMPARE(QSettings().value("api/baseUrl").toString(), QStringLiteral("http://localhost:9090/api"));

        QFile cola(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/sin-conexion/pendientes-91.json");
        QVERIFY(cola.open(QIODevice::ReadOnly));
        const QByteArray contenido = cola.readAll();
        QVERIFY(contenido.contains("localhost:9090/api/estudiante/91"));
        QVERIFY(!contenido.contains("localhost:8080"));
        cola.close();
        cola.remove();
    }

    void otroServidorNoReemplazaAlGuardado()
    {
        auto &d = Descubrimiento::instance();
        const QString antes = d.servidorUrl();
        respondedor->id = QStringLiteral("99999999-0000-0000-0000-000000000000"); // otro colegio
        respondedor->puertoHttp = 7070;
        QSignalSpy reconectado(&d, &Descubrimiento::reconectado);
        QSignalSpy fin(&d, &Descubrimiento::busquedaTerminada);
        d.reconectar();
        QVERIFY(fin.wait(5000));
        QCOMPARE(reconectado.count(), 0);
        QCOMPARE(d.servidorUrl(), antes);
    }

    void probarDireccionEscritaAMano()
    {
        auto &d = Descubrimiento::instance();
        ServidorFalso http;
        http.responder(200, R"({"rep":"servidor","id":"aaaa","nombre":"Servidor manual","version":"1.0.0","puerto":0})");
        QSignalSpy probada(&d, &Descubrimiento::direccionProbada);
        d.probarDireccion(QStringLiteral("127.0.0.1:%1").arg(http.puerto()));
        QVERIFY(probada.wait(5000));
        QVERIFY(probada.first().at(0).toBool());
        QCOMPARE(d.servidorNombre(), QStringLiteral("Servidor manual"));
        QCOMPARE(d.servidorUrl(), QStringLiteral("http://127.0.0.1:%1").arg(http.puerto()));
        QCOMPARE(http.peticiones.first().ruta, QByteArray("/api/public/servidor"));

        // Una dirección que no es REP no cambia nada
        ServidorFalso otro;
        otro.responder(200, R"({"hola":"mundo"})");
        probada.clear();
        d.probarDireccion(QStringLiteral("127.0.0.1:%1").arg(otro.puerto()));
        QVERIFY(probada.wait(5000));
        QVERIFY(!probada.first().at(0).toBool());
        QCOMPARE(d.servidorNombre(), QStringLiteral("Servidor manual"));
    }
};

QTEST_GUILESS_MAIN(TstDescubrimiento)
#include "tst_descubrimiento.moc"
