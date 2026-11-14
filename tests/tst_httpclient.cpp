#include "ServidorFalso.h"
#include "api/HttpClient.h"
#include "core/AlmacenLocal.h"
#include "core/SessionManager.h"
#include "core/Sincronizacion.h"

#include <QNetworkReply>
#include <QStandardPaths>
#include <QtTest>

using namespace Rep;

/*
 * Contrato de errores con el backend (ApiError: code/message) y respaldo sin conexión
 * de las consultas GET.
 */
class TstHttpClient : public QObject
{
    Q_OBJECT

    QNetworkReply *get(const QString &url, const QString &token = {})
    {
        QNetworkReply *r = HttpClient::red()->get(HttpClient::jsonRequest(QUrl(url), token));
        QSignalSpy fin(r, &QNetworkReply::finished);
        fin.wait(5000);
        return r;
    }

private slots:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
        QCoreApplication::setApplicationName(QStringLiteral("rep-pruebas"));
        SecureTokenStorage::instance().setBackend(std::make_unique<AlmacenMemoria>());
        AlmacenLocal::borrarUsuario();
    }

    void usaElMensajeDelServidor()
    {
        ServidorFalso s;
        s.responder(409, R"({"status":409,"code":"PERIODO_SOLAPADO","message":"Las fechas se cruzan con otro periodo"})");
        QNetworkReply *r = get(s.base() + "/x");
        QCOMPARE(HttpClient::httpStatus(r), 409);
        QCOMPARE(HttpClient::errorMessage(r), QStringLiteral("Las fechas se cruzan con otro periodo"));
        r->deleteLater();
    }

    void mensajePorEstadoSiNoHayCuerpo()
    {
        ServidorFalso s;
        s.responder(403, "");
        QNetworkReply *r = get(s.base() + "/x");
        QCOMPARE(HttpClient::errorMessage(r), QStringLiteral("No tiene permisos para realizar esta acción."));
        r->deleteLater();
    }

    void enviaElTokenComoBearer()
    {
        ServidorFalso s;
        s.responder(200, "{}");
        get(s.base() + "/perfil", QStringLiteral("abc.def.ghi"))->deleteLater();
        QCOMPARE(s.peticiones.size(), 1);
        QCOMPARE(s.peticiones.first().autorizacion, QByteArray("Bearer abc.def.ghi"));
    }

    void sinConexionUsaLaUltimaCopia()
    {
        ServidorFalso s;
        const QString url = s.base() + "/estudiante/5/notas";
        s.responder(200, R"({"promedioGeneral":4.2})");
        QByteArray cuerpo;
        QNetworkReply *r = get(url);
        QVERIFY(HttpClient::leerConRespaldo(r, cuerpo));
        QCOMPARE(cuerpo, QByteArray(R"({"promedioGeneral":4.2})"));
        r->deleteLater();

        s.cerrar(); // el servidor se apaga
        cuerpo.clear();
        r = get(url);
        QVERIFY(Sincronizacion::esSinConexion(r));
        QVERIFY(HttpClient::leerConRespaldo(r, cuerpo));
        QCOMPARE(cuerpo, QByteArray(R"({"promedioGeneral":4.2})"));
        QVERIFY(!Sincronizacion::instance().enLinea());
        r->deleteLater();
    }

    void unErrorDelServidorNoEsFaltaDeConexion()
    {
        ServidorFalso s;
        s.responder(500, R"({"message":"falló"})");
        QNetworkReply *r = get(s.base() + "/x");
        QVERIFY(!Sincronizacion::esSinConexion(r));
        QByteArray cuerpo;
        QVERIFY(!HttpClient::leerConRespaldo(r, cuerpo));
        r->deleteLater();
    }
};

QTEST_GUILESS_MAIN(TstHttpClient)
#include "tst_httpclient.moc"
