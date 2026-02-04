#ifndef QTKEYCHAINCREDENTIALSTORE_H
#define QTKEYCHAINCREDENTIALSTORE_H

#include "ICredentialStore.h"
#include <QObject>

namespace Rep::Security {

class QtKeychainCredentialStore : public QObject, public ICredentialStore
{
    Q_OBJECT
public:
    explicit QtKeychainCredentialStore(QObject *parent = nullptr);
    ~QtKeychainCredentialStore() override = default;

    bool saveToken(const QString &service, const QString &key, const QString &token) override;
    QString loadToken(const QString &service, const QString &key) override;
    bool deleteToken(const QString &service, const QString &key) override;
};

} // namespace Rep::Security

#endif // QTKEYCHAINCREDENTIALSTORE_H
