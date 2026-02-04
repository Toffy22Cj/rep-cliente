#ifndef APICONFIG_H
#define APICONFIG_H

#include <QSslConfiguration>
#include <QSslSocket>
#include <QSslCipher>

namespace Rep
{

    class ApiConfig
    {
    public:
        static QString baseUrl()
        {
#ifdef QT_DEBUG
            // En desarrollo: localhost sin SSL (el backend no tiene certificados)
            return "http://localhost:8080/api";
#else
            // En producción: servidor real con HTTPS
            return "https://api.mirepapp.com/api";
#endif
        }

        static void setupSSL()
        {
            // Configurar SSL para mayor seguridad
            QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();

            // Usar TLS 1.2 o superior
            sslConfig.setProtocol(QSsl::TlsV1_2OrLater);

// Verificar certificados del servidor
// En producción DEBE ser VerifyPeer
#ifdef QT_DEBUG
            sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone); // Para desarrollo local sin cert validos
#else
            sslConfig.setPeerVerifyMode(QSslSocket::VerifyPeer);
#endif

            // Aplicar configuración global
            QSslConfiguration::setDefaultConfiguration(sslConfig);
        }

        static int requestTimeout()
        {
            return 30000; // 30 segundos
        }
    };

} // namespace Rep

#endif // APICONFIG_H
