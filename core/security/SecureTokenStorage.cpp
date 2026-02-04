#include "SecureTokenStorage.h"
#include <QSettings>
#include <QDebug>

namespace Rep {

SecureTokenStorage& SecureTokenStorage::instance()
{
    static SecureTokenStorage inst;
    return inst;
}

SecureTokenStorage::SecureTokenStorage() : QObject(nullptr)
{
}

void SecureTokenStorage::setBackend(std::unique_ptr<Security::ICredentialStore> backend)
{
    m_backend = std::move(backend);
    qDebug() << "SecureTokenStorage backend set.";
}

bool SecureTokenStorage::saveToken(const QString &token)
{
    if (!m_backend) {
        qWarning() << "SecureTokenStorage: No backend configured! Token NOT saved securely.";
        return false;
    }

    if (m_backend->saveToken(SERVICE_NAME, TOKEN_KEY, token)) {
        // Save expiry in standard settings (it's not sensitive)
        // Default expiry: 24 hours from now
        QSettings settings;
        settings.setValue(EXPIRY_KEY, QDateTime::currentDateTime().addSecs(86400));
        qDebug() << "SecureTokenStorage: Token saved successfully.";
        return true;
    }

    qCritical() << "SecureTokenStorage: Failed to save token to backend.";
    return false;
}

QString SecureTokenStorage::getToken() const
{
    if (!m_backend) {
        qWarning() << "SecureTokenStorage: No backend configured! Cannot retrieve token.";
        return QString();
    }
    return m_backend->loadToken(SERVICE_NAME, TOKEN_KEY);
}

bool SecureTokenStorage::deleteToken()
{
    if (!m_backend) {
        qWarning() << "SecureTokenStorage: No backend configured!";
        return false;
    }

    if (m_backend->deleteToken(SERVICE_NAME, TOKEN_KEY)) {
        QSettings settings;
        settings.remove(EXPIRY_KEY);
        qDebug() << "SecureTokenStorage: Token deleted.";
        return true;
    }
    return false;
}

bool SecureTokenStorage::hasToken() const
{
    return !getToken().isEmpty();
}

bool SecureTokenStorage::isTokenExpired() const
{
    QSettings settings;
    QVariant expiry = settings.value(EXPIRY_KEY);
    if (!expiry.isValid()) return true; // Treat missing expiry as expired

    QDateTime expiryDate = expiry.toDateTime();
    return QDateTime::currentDateTime() > expiryDate;
}

QDateTime SecureTokenStorage::getExpirationTime() const
{
    QSettings settings;
    return settings.value(EXPIRY_KEY).toDateTime();
}

} // namespace Rep
