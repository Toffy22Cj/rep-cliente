#ifndef SERVIDORFALSO_H
#define SERVIDORFALSO_H

#include "core/security/ICredentialStore.h"

#include <QHash>
#include <QQueue>
#include <QTcpServer>
#include <QTcpSocket>

/*
 * Utilidades de prueba: un servidor HTTP mínimo que responde, en orden, las respuestas
 * encoladas (estado + cuerpo JSON) y registra las peticiones recibidas; y un almacén de
 * credenciales en memoria en lugar del llavero del sistema.
 */
class ServidorFalso : public QObject
{
    Q_OBJECT
public:
    struct Respuesta { int estado; QByteArray cuerpo; };
    struct Peticion { QByteArray metodo; QByteArray ruta; QByteArray autorizacion; QByteArray cuerpo; };

    /** puerto 0 = uno libre; un puerto concreto simula que el mismo servidor vuelve. */
    explicit ServidorFalso(quint16 puerto = 0, QObject *parent = nullptr) : QObject(parent)
    {
        connect(&m_servidor, &QTcpServer::newConnection, this, &ServidorFalso::atender);
        m_servidor.listen(QHostAddress::LocalHost, puerto);
    }

    quint16 puerto() const { return m_servidor.serverPort(); }
    QString base() const { return QStringLiteral("http://127.0.0.1:%1/api").arg(puerto()); }
    void responder(int estado, const QByteArray &cuerpo) { m_respuestas.enqueue({estado, cuerpo}); }
    void cerrar() { m_servidor.close(); }
    QList<Peticion> peticiones;

private slots:
    void atender()
    {
        while (QTcpSocket *s = m_servidor.nextPendingConnection()) {
            connect(s, &QTcpSocket::readyRead, this, [this, s]() { leer(s); });
            connect(s, &QTcpSocket::disconnected, s, &QObject::deleteLater);
        }
    }

private:
    void leer(QTcpSocket *s)
    {
        QByteArray &buf = m_buffers[s];
        buf += s->readAll();
        const int fin = buf.indexOf("\r\n\r\n");
        if (fin < 0) return;
        const QList<QByteArray> lineas = buf.left(fin).split('\n');
        int largo = 0;
        Peticion p;
        const QList<QByteArray> primera = lineas.first().trimmed().split(' ');
        p.metodo = primera.value(0);
        p.ruta = primera.value(1);
        for (const QByteArray &l : lineas) {
            const QByteArray t = l.trimmed();
            if (t.toLower().startsWith("content-length:")) largo = t.mid(15).trimmed().toInt();
            if (t.toLower().startsWith("authorization:")) p.autorizacion = t.mid(14).trimmed();
        }
        if (buf.size() < fin + 4 + largo) return; // cuerpo incompleto
        p.cuerpo = buf.mid(fin + 4, largo);
        m_buffers.remove(s);
        peticiones.append(p);

        const Respuesta r = m_respuestas.isEmpty() ? Respuesta{200, "{}"} : m_respuestas.dequeue();
        s->write("HTTP/1.1 " + QByteArray::number(r.estado) + " X\r\nContent-Type: application/json\r\n"
                 "Content-Length: " + QByteArray::number(r.cuerpo.size()) + "\r\nConnection: close\r\n\r\n" + r.cuerpo);
        s->disconnectFromHost();
    }

    QTcpServer m_servidor;
    QQueue<Respuesta> m_respuestas;
    QHash<QTcpSocket *, QByteArray> m_buffers;
};

class AlmacenMemoria : public Rep::Security::ICredentialStore
{
public:
    bool saveToken(const QString &s, const QString &k, const QString &t) override { m_datos[s + k] = t; return true; }
    QString loadToken(const QString &s, const QString &k) override { return m_datos.value(s + k); }
    bool deleteToken(const QString &s, const QString &k) override { m_datos.remove(s + k); return true; }
private:
    QHash<QString, QString> m_datos;
};

#endif // SERVIDORFALSO_H
