#ifndef HTTPCLIENT_H
#define HTTPCLIENT_H

#include <QLoggingCategory>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QString>
#include <QUrl>

/**
 * Categoría de log de la capa de red. Silenciosa por defecto; para depurar:
 *   QT_LOGGING_RULES="rep.api.debug=true" ./appRep
 */
Q_DECLARE_LOGGING_CATEGORY(lcApi)

namespace Rep {

/**
 * Utilidades HTTP compartidas por todos los servicios de la API.
 *
 * Centraliza la construcción de peticiones autenticadas y la interpretación de
 * errores, que antes estaban duplicadas en cada servicio.
 */
namespace HttpClient {

/**
 * Gestor de red compartido por toda la aplicación (reutiliza conexiones HTTP y
 * actualiza el estado de conexión de Sincronizacion con cada respuesta).
 */
QNetworkAccessManager *red();

/**
 * Cuerpo de una respuesta GET con respaldo sin conexión:
 *  - Respuesta correcta: devuelve el cuerpo y lo guarda en el almacén local.
 *  - Sin conexión con el servidor: devuelve la última copia guardada, si existe.
 * Devuelve false si no hay datos (el error se obtiene con errorMessage()).
 */
bool leerConRespaldo(QNetworkReply *reply, QByteArray &cuerpo);

/** Petición JSON con cabecera Authorization: Bearer (si hay token). */
QNetworkRequest jsonRequest(const QUrl &url, const QString &token);

/** Petición JSON para una ruta relativa a ApiConfig::baseUrl(). */
QNetworkRequest jsonRequest(const QString &apiPath, const QString &token);

/** Código HTTP de la respuesta (0 si no hubo respuesta del servidor). */
int httpStatus(const QNetworkReply *reply);

/**
 * Mensaje legible para el usuario a partir de una respuesta fallida.
 * Usa el campo "message"/"mensaje" del cuerpo JSON del backend cuando existe.
 *
 * Si la petición iba autenticada y el servidor responde 401 (token caducado o
 * cuenta desactivada) se cierra la sesión local para volver al login.
 */
QString errorMessage(QNetworkReply *reply);

} // namespace HttpClient
} // namespace Rep

#endif // HTTPCLIENT_H
