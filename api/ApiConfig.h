#ifndef APICONFIG_H
#define APICONFIG_H

#include <QString>
#include <QSettings>
#include <QProcessEnvironment>

namespace Rep {

/**
 * Configuración del endpoint de la API.
 *
 * Orden de prioridad:
 *   1. Variable de entorno REP_API_URL   (p. ej. https://rep.colegio.edu/api)
 *   2. QSettings  "api/baseUrl"
 *   3. Valor por defecto http://localhost:8080/api
 */
class ApiConfig
{
public:
    static QString baseUrl() {
        const QString fromEnv = QProcessEnvironment::systemEnvironment().value("REP_API_URL");
        if (!fromEnv.isEmpty())
            return normalize(fromEnv);

        const QString fromSettings = QSettings().value("api/baseUrl").toString();
        if (!fromSettings.isEmpty())
            return normalize(fromSettings);

        return QStringLiteral("http://localhost:8080/api");
    }

    /** URL absoluta para una ruta de la API, p. ej. url("/auth/login"). */
    static QString url(const QString &path) {
        return baseUrl() + (path.startsWith('/') ? path : QLatin1Char('/') + path);
    }

private:
    static QString normalize(QString url) {
        while (url.endsWith('/'))
            url.chop(1);
        return url;
    }
};

} // namespace Rep

#endif // APICONFIG_H
