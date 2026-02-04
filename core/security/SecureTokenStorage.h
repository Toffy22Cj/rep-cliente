#ifndef SECURETOKENSTORAGE_H
#define SECURETOKENSTORAGE_H

#include <QString>
#include <QDateTime>
#include <memory>
#include <QObject>
#include "ICredentialStore.h"

namespace Rep {

class SecureTokenStorage : public QObject
{
    Q_OBJECT
public:
    static SecureTokenStorage& instance();

    // Configure the storage backend (dependency injection)
    void setBackend(std::unique_ptr<Security::ICredentialStore> backend);

    // Token operations
    bool saveToken(const QString &token);
    QString getToken() const;
    bool deleteToken();
    bool hasToken() const;

    // Expiry handling (non-sensitive data stored in QSettings)
    bool isTokenExpired() const;
    QDateTime getExpirationTime() const;

private:
    SecureTokenStorage();
    std::unique_ptr<Security::ICredentialStore> m_backend;

    static constexpr const char *SERVICE_NAME = "RepEducativo";
    static constexpr const char *TOKEN_KEY = "auth_token";
    static constexpr const char *EXPIRY_KEY = "token_expiry";
};

} // namespace Rep

#endif // SECURETOKENSTORAGE_H
