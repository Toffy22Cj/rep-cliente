#ifndef APICLIENTE_H
#define APICLIENTE_H

#include <QHash>
#include <QSet>
#include <QNetworkAccessManager>
#include <QObject>
#include <QUrl>
#include <QVariant>

namespace Rep {

/**
 * Cliente de la API para QML (propiedad de contexto "api").
 *
 * Peticiones JSON genéricas identificadas por un id (las respuestas llegan por las
 * señales `respuesta`/`fallo`), además de descarga de archivos con caché local y
 * subida multipart. Usa el token de la sesión y el tratamiento de errores de
 * HttpClient (mensaje y código del backend, cierre de sesión ante 401).
 *
 * Las rutas pueden ser relativas a la API ("/materiales") o las URLs que devuelve el
 * backend ("/api/materiales/3/archivo").
 */
class ApiCliente : public QObject
{
    Q_OBJECT
public:
    explicit ApiCliente(QObject *parent = nullptr);

    Q_INVOKABLE int get(const QString &ruta);
    Q_INVOKABLE int post(const QString &ruta, const QVariant &cuerpo);
    Q_INVOKABLE int put(const QString &ruta, const QVariant &cuerpo);
    Q_INVOKABLE int eliminar(const QString &ruta);

    /** Sube un archivo local (campo "file") con campos de formulario adicionales. */
    Q_INVOKABLE int subir(const QString &ruta, const QUrl &archivoLocal, const QVariantMap &campos = {});

    /** Descarga (o reutiliza de la caché) y emite `archivoListo` con la URL local. */
    Q_INVOKABLE void descargar(const QString &ruta);

    /** Descarga y abre el archivo con la aplicación predeterminada del sistema. */
    Q_INVOKABLE void abrir(const QString &ruta);

    /** Formatea un tamaño en bytes (p. ej. "1,2 MB"). */
    Q_INVOKABLE static QString tamanoLegible(qint64 bytes);

    /** URL absoluta en el servidor para una ruta de la API. */
    static QUrl urlServidor(const QString &ruta);

signals:
    void respuesta(int id, const QVariant &datos);
    void fallo(int id, const QString &mensaje, const QString &codigo);
    void archivoListo(const QString &ruta, const QUrl &urlLocal);
    void archivoFallo(const QString &ruta, const QString &mensaje);

private:
    int enviar(const QByteArray &metodo, const QString &ruta, const QVariant &cuerpo);
    void atender(int id, class QNetworkReply *reply);

    QNetworkAccessManager *m_red;
    int m_siguienteId = 1;
    QHash<QString, QUrl> m_cache;
    QSet<QString> m_abrirAlDescargar;
    QSet<QString> m_descargando; // evita descargas simultáneas del mismo archivo
};

} // namespace Rep

#endif // APICLIENTE_H
