# 🛠️ RECOMENDACIONES TÉCNICAS ESPECÍFICAS

## 1. IMPLEMENTACIÓN RÁPIDA DE HTTPS (Semana 1)

### Paso 1: Actualizar ApiConfig.h

```cpp
// api/ApiConfig.h
#ifndef APICONFIG_H
#define APICONFIG_H

#include <QString>
#include <QSslConfiguration>

namespace Rep {

class ApiConfig
{
public:
    static QString baseUrl() {
        #ifdef QT_DEBUG
            // En desarrollo: localhost con certificado autofirmado
            return "https://127.0.0.1:8080/api";
        #else
            // En producción: servidor real
            return "https://api.mirepapp.com/api";
        #endif
    }

    static void setupSSL() {
        // Configurar SSL para mayor seguridad
        QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();

        // Usar TLS 1.2 o superior
        sslConfig.setProtocol(QSsl::TlsV1_2OrLater);

        // Verificar certificados del servidor
        sslConfig.setPeerVerifyMode(QSslSocket::VerifyPeer);

        // Usar ciphers seguros
        QList<QSslCipher> ciphers = sslConfig.ciphers();
        // Filtrar ciphers débiles si es necesario
        sslConfig.setCiphers(ciphers);

        // Aplicar configuración global
        QSslConfiguration::setDefaultConfiguration(sslConfig);
    }

    static int requestTimeout() {
        return 30000;  // 30 segundos
    }
};

} // namespace Rep

#endif // APICONFIG_H
```

### Paso 2: Crear BaseService para evitar duplicación

```cpp
// api/BaseService.h
#ifndef BASESERVICE_H
#define BASESERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QSslError>

namespace Rep {

class BaseService : public QObject
{
    Q_OBJECT

protected:
    BaseService(QObject *parent = nullptr);
    virtual ~BaseService();

    // Método protegido para crear requests
    QNetworkRequest createRequest(const QUrl &url, const QString &token);

    // Método para configurar manager
    void setupNetworkManager();

    // Manejo centralizado de errores SSL
    void handleSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);

    QNetworkAccessManager *m_networkManager;

private:
    void onSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);
};

} // namespace Rep

#endif // BASESERVICE_H
```

```cpp
// api/BaseService.cpp
#include "BaseService.h"
#include "ApiConfig.h"
#include <QNetworkRequest>
#include <QSslSocket>
#include <QDebug>

namespace Rep {

BaseService::BaseService(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
    setupNetworkManager();
}

BaseService::~BaseService() = default;

void BaseService::setupNetworkManager()
{
    ApiConfig::setupSSL();

    // Conectar errores SSL
    connect(m_networkManager, &QNetworkAccessManager::sslErrors,
            this, &BaseService::onSslErrors);
}

QNetworkRequest BaseService::createRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);

    // Content type
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Authorization token
    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }

    // User agent
    request.setHeader(QNetworkRequest::UserAgentHeader, "RepClient/0.1");

    // Timeout
    request.setTransferTimeout(ApiConfig::requestTimeout());

    return request;
}

void BaseService::onSslErrors(QNetworkReply *reply, const QList<QSslError> &errors)
{
    // IMPORTANTE: En producción, NUNCA ignorar errores SSL
    for (const QSslError &error : errors) {
        qCritical() << "SSL Error:" << error.errorString();
    }

    #ifdef QT_DEBUG
        // En desarrollo, puedes permitir certificados autofirmados
        // PERO SOLO PARA TESTING
        qWarning() << "SSL errors ignored in DEBUG mode. This is NOT safe for production!";
        reply->ignoreSslErrors();
    #else
        // En producción, RECHAZAR SIEMPRE
        reply->abort();
    #endif
}

} // namespace Rep
```

### Paso 3: Actualizar AuthService para usar BaseService

```cpp
// api/AuthService.h
#ifndef AUTHSERVICE_H
#define AUTHSERVICE_H

#include "BaseService.h"
#include "../models/AuthDTOs.h"

namespace Rep {

class AuthService : public BaseService
{
    Q_OBJECT
public:
    explicit AuthService(QObject *parent = nullptr);

    // Validar entrada
    void login(const QString &identificacion, const QString &password);

signals:
    void loginFinished(const LoginResponse &response);
    void errorOccurred(const QString &error);

private slots:
    void onLoginReply(QNetworkReply *reply);

private:
    bool validateInput(const QString &identificacion, const QString &password);
};

} // namespace Rep

#endif // AUTHSERVICE_H
```

```cpp
// api/AuthService.cpp
#include "AuthService.h"
#include "ApiConfig.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QDebug>
#include <QRegularExpression>

namespace Rep {

AuthService::AuthService(QObject *parent)
    : BaseService(parent)
{
}

bool AuthService::validateInput(const QString &identificacion, const QString &password)
{
    // Validar no vacío
    if (identificacion.isEmpty() || password.isEmpty()) {
        emit errorOccurred("Identificación y contraseña son requeridas");
        return false;
    }

    // Validar longitud
    if (identificacion.length() < 3 || identificacion.length() > 50) {
        emit errorOccurred("Identificación debe tener entre 3 y 50 caracteres");
        return false;
    }

    if (password.length() < 6 || password.length() > 128) {
        emit errorOccurred("Contraseña debe tener entre 6 y 128 caracteres");
        return false;
    }

    // Validar formato de identificación (ej: números y guiones)
    QRegularExpression idRegex("^[a-zA-Z0-9-]+$");
    if (!idRegex.match(identificacion).hasMatch()) {
        emit errorOccurred("Identificación contiene caracteres inválidos");
        return false;
    }

    return true;
}

void AuthService::login(const QString &identificacion, const QString &password)
{
    // Validar entrada
    if (!validateInput(identificacion, password)) {
        return;
    }

    QUrl url(ApiConfig::baseUrl() + "/auth/login");
    QNetworkRequest request = createRequest(url, "");

    QJsonObject json;
    json["identificacion"] = identificacion;
    json["password"] = password;

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(json).toJson());

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onLoginReply(reply);
    });
}

void AuthService::onLoginReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Network error:" << reply->errorString();
        emit errorOccurred("Error de conexión: " + reply->errorString());
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);

    if (!doc.isObject()) {
        qWarning() << "Invalid JSON response";
        emit errorOccurred("Respuesta inválida del servidor");
        return;
    }

    QJsonObject obj = doc.object();

    // Validar campos requeridos
    if (!obj.contains("success") || !obj.contains("token")) {
        qWarning() << "Missing required fields in response";
        emit errorOccurred("Respuesta del servidor incompleta");
        return;
    }

    LoginResponse response;
    response.success = obj["success"].toBool();
    response.mensaje = obj["mensaje"].toString();
    response.token = obj["token"].toString();

    // Validar token
    if (response.success && response.token.isEmpty()) {
        qWarning() << "Login successful but token is empty";
        emit errorOccurred("Token no recibido");
        return;
    }

    // Parsear usuario si existe
    if (obj.contains("usuario") && obj["usuario"].isObject()) {
        QJsonObject userObj = obj["usuario"].toObject();

        if (!userObj.contains("id") || !userObj.contains("rol")) {
            qWarning() << "Usuario object missing required fields";
            emit errorOccurred("Datos de usuario incompletos");
            return;
        }

        response.usuario.id = userObj["id"].toVariant().toLongLong();
        response.usuario.nombre = userObj["nombre"].toString();
        response.usuario.correo = userObj["correo"].toString();
        response.usuario.identificacion = userObj["identificacion"].toString();

        QString rolStr = userObj["rol"].toString().trimmed().toUpper();

        if (rolStr == "ADMIN")
            response.usuario.rol = Rol::ADMIN;
        else if (rolStr == "PROFESOR")
            response.usuario.rol = Rol::PROFESOR;
        else
            response.usuario.rol = Rol::ESTUDIANTE;
    }

    emit loginFinished(response);
}

} // namespace Rep
```

---

## 2. ALMACENAMIENTO SEGURO DE TOKENS

### 2. SISTEMA DE ALMACENAMIENTO SEGURO (Moderno & Abstracto)

En lugar de acoplar la aplicación directamente a una librería específica, se recomienda definir una interfaz `ICredentialStore` e inyectar la implementación. Esto permite cambiar entre `QtKeychain`, `libsecret` nativo, o implementaciones específicas de plataforma (Windows Credential Manager, Apple Keychain) sin afectar al resto de la app.

**Definición de la Interfaz:**

```cpp
// core/security/ICredentialStore.h
#pragma once
#include <QString>
#include <QDateTime>
#include <expected> // C++23 o custom result type

namespace Rep::Security {

class ICredentialStore {
public:
    virtual ~ICredentialStore() = default;

    virtual bool saveToken(const QString &service, const QString &key, const QString &token) = 0;
    virtual QString loadToken(const QString &service, const QString &key) = 0;
    virtual bool deleteToken(const QString &service, const QString &key) = 0;
};

}
```

**Implementación Recomendada (Wrapper):**

Aunque existen librerías como `QtKeychain`, para proyectos modernos se sugiere un wrapper que permita soporte futuro de **Biometría** (TouchID/Windows Hello) que librerías antiguas no siempre soportan bien.

Para esta fase, `QtKeychain` sigue siendo la opción más estable cross-platform para Qt, pero debe ser usada **detrás de la interfaz**:

```cmake
# CMakeLists.txt
find_package(Qt6Keychain REQUIRED)
target_link_libraries(appRep PRIVATE qt6keychain)
```

**Implementar:**

```cpp
// core/security/SecureTokenStorage.h
// Implementación concreta usando la interfaz
#ifndef SECURETOKENSTORAGE_H
#define SECURETOKENSTORAGE_H

#include <QString>
#include <QDateTime>
#include <memory>
#include "ICredentialStore.h"

namespace Rep {

class SecureTokenStorage
{
public:
    // Singleton con Dependency Injection (Service Locator pattern simplificado para Qt)
    static SecureTokenStorage& instance();
    
    // Configurar el backend de almacenamiento (llamar al inicio)
    void setBackend(std::unique_ptr<Security::ICredentialStore> backend);

    bool saveToken(const QString &token);
    QString getToken() const;
    bool deleteToken();
    bool hasToken() const;

    // Validar expiración
    bool isTokenExpired() const;

    // Obtener fecha de expiración
    QDateTime getExpirationTime() const;

    // Guardar refresh token
    bool saveRefreshToken(const QString &refreshToken);
    QString getRefreshToken() const;

private:
    SecureTokenStorage() = default;
    std::unique_ptr<Security::ICredentialStore> m_backend;
    
    static constexpr const char *SERVICE_NAME = "RepEducativo";
    static constexpr const char *TOKEN_KEY = "auth_token";
    static constexpr const char *REFRESH_KEY = "refresh_token";
    static constexpr const char *EXPIRY_KEY = "token_expiry";
};

} // namespace Rep

#endif // SECURETOKENSTORAGE_H
```

```cpp
// core/SecureTokenStorage.cpp
#include "SecureTokenStorage.h"
#include <QSettings>
#include <QDateTime>
#include <QDebug>
#include <QCoreApplication>

// Note: QKeychain headers are no longer directly included here,
// as the implementation now relies on the ICredentialStore interface.

namespace Rep {

SecureTokenStorage& SecureTokenStorage::instance()
{
    static SecureTokenStorage inst;
    return inst;
}

void SecureTokenStorage::setBackend(std::unique_ptr<Security::ICredentialStore> backend)
{
    m_backend = std::move(backend);
}

SecureTokenStorage::SecureTokenStorage() = default;

bool SecureTokenStorage::saveToken(const QString &token)
{
    if (!m_backend) {
        qWarning() << "Secure storage backend not initialized!";
        return false;
    }

    if (m_backend->saveToken(SERVICE_NAME, TOKEN_KEY, token)) {
         // También guardar fecha de expiración (sin sensibilidad)
        QSettings settings;
        settings.setValue("token_expiry", QDateTime::currentDateTime().addSecs(86400).toString(Qt::ISODate));
        qDebug() << "Token saved securely via backend";
        return true;
    }
    return false;
}

QString SecureTokenStorage::getToken() const
{
    job.setAutoDelete(false);
    job.setKey(TOKEN_KEY);

    QEventLoop loop;
    QObject::connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        qWarning() << "Failed to retrieve token";
        return "";
    }

    return job.textData();
}

bool SecureTokenStorage::deleteToken()
{
    QKeychain::DeletePasswordJob job(SERVICE_NAME);
    job.setAutoDelete(false);
    job.setKey(TOKEN_KEY);

    QEventLoop loop;
    QObject::connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        qCritical() << "Failed to delete token";
        return false;
    }

    QSettings settings;
    settings.remove("token_expiry");

    qDebug() << "Token deleted securely";
    return true;
}

bool SecureTokenStorage::hasToken() const
{
    return !getToken().isEmpty();
}

bool SecureTokenStorage::isTokenExpired() const
{
    QSettings settings;
    QString expiryStr = settings.value("token_expiry", "").toString();

    if (expiryStr.isEmpty()) {
        return true;  // Sin fecha de expiración = expirado
    }

    QDateTime expiry = QDateTime::fromString(expiryStr, Qt::ISODate);
    return QDateTime::currentDateTime() > expiry;
}

QDateTime SecureTokenStorage::getExpirationTime() const
{
    QSettings settings;
    QString expiryStr = settings.value("token_expiry", "").toString();
    return QDateTime::fromString(expiryStr, Qt::ISODate);
}

bool SecureTokenStorage::saveRefreshToken(const QString &refreshToken)
{
    QKeychain::WritePasswordJob job(SERVICE_NAME);
    job.setAutoDelete(false);
    job.setKey(REFRESH_KEY);
    job.setTextData(refreshToken);

    QEventLoop loop;
    QObject::connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    return job.error() == QKeychain::NoError;
}

QString SecureTokenStorage::getRefreshToken() const
{
    QKeychain::ReadPasswordJob job(SERVICE_NAME);
    job.setAutoDelete(false);
    job.setKey(REFRESH_KEY);

    QEventLoop loop;
    QObject::connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        return "";
    }

    return job.textData();
}

} // namespace Rep
```

---

## 3. ACTUALIZAR SessionManager

```cpp
// core/SessionManager.h
#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include "../models/AuthDTOs.h"

namespace Rep {

class SessionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY sessionChanged)
    Q_PROPERTY(QString token READ token NOTIFY sessionChanged)
    Q_PROPERTY(bool isTokenExpired READ isTokenExpired NOTIFY sessionChanged)
    // ... otros properties ...

public:
    static SessionManager& instance() {
        static SessionManager inst;
        return inst;
    }

    bool isAuthenticated() const;
    QString token() const;
    bool isTokenExpired() const;
    bool refreshTokenIfNeeded();  // NUEVO

    void setSession(const AuthUsuarioDTO &user, const QString &token, const QString &refreshToken = "");
    Q_INVOKABLE void logout();

signals:
    void sessionChanged();
    void tokenRefreshed();
    void sessionExpired();

private:
    SessionManager();
};

} // namespace Rep

#endif // SESSIONMANAGER_H
```

---

## 4. CREAR LOGGER SEGURO

```cpp
// core/Logger.h
#ifndef LOGGER_H
#define LOGGER_H

#include <QString>
#include <QFile>
#include <QDateTime>

namespace Rep {

enum class LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL };

class Logger
{
public:
    static Logger& instance();

    // Log con nivel
    static void log(LogLevel level, const QString &category, const QString &message);

    // Atajos convenientes
    static void debug(const QString &category, const QString &message)
        { log(LogLevel::DEBUG, category, message); }

    static void info(const QString &category, const QString &message)
        { log(LogLevel::INFO, category, message); }

    static void warning(const QString &category, const QString &message)
        { log(LogLevel::WARNING, category, message); }

    static void error(const QString &category, const QString &message)
        { log(LogLevel::ERROR, category, message); }

    static void critical(const QString &category, const QString &message)
        { log(LogLevel::CRITICAL, category, message); }

private:
    Logger();
    QFile m_logFile;
    void rotateLogsIfNeeded();
};

} // namespace Rep

#endif // LOGGER_H
```

---

## 5. TESTING CON GOOGLE TEST

### CMakeLists.txt - Agregar Tests

```cmake
# Agregar al final de CMakeLists.txt

enable_testing()

# Tests
if(NOT WIN32)
    find_package(GTest REQUIRED)

    set(TEST_SOURCES
        tests/AuthServiceTest.cpp
        tests/ValidationUtilsTest.cpp
    )

    add_executable(rep_tests ${TEST_SOURCES})
    target_link_libraries(rep_tests PRIVATE GTest::GTest GTest::Main)

    add_test(NAME RepTests COMMAND rep_tests)
endif()
```

### Ejemplo de Test

```cpp
// tests/AuthServiceTest.cpp
#include <gtest/gtest.h>
#include "../api/AuthService.h"

namespace Rep {

class AuthServiceTest : public ::testing::Test {
protected:
    AuthService authService;
};

TEST_F(AuthServiceTest, LoginWithValidCredentials) {
    // Arrange
    QString identificacion = "test123";
    QString password = "password123";

    // Act & Assert
    // Nota: Esto requeriría un mock del network
    // EXPECT_CALL(mockNetwork, post).Times(1);
}

TEST_F(AuthServiceTest, RejectEmptyIdentification) {
    // El servicio debería rechazar vacíos
}

TEST_F(AuthServiceTest, RejectWeakPassword) {
    // El servicio debería rechazar < 6 caracteres
}

} // namespace Rep
```

---

## CHECKLIST DE IMPLEMENTACIÓN FASE 1

- [ ] Actualizar ApiConfig.h con HTTPS
- [ ] Crear BaseService
- [ ] Actualizar AuthService
- [ ] Crear SecureTokenStorage
- [ ] Actualizar SessionManager
- [ ] Crear Logger
- [ ] Crear Interfaz `ICredentialStore`
- [ ] Implementar Backend `QtKeychainCredentialStore`
- [ ] Actualizar SecureTokenStorage para usar inyección
- [ ] Pruebas manuales de HTTPS
- [ ] Pruebas de validación de entrada
- [ ] Documentar cambios
