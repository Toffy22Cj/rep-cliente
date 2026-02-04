#ifndef ICREDENTIALSTORE_H
#define ICREDENTIALSTORE_H

#include <QString>

namespace Rep {
namespace Security {

class ICredentialStore {
public:
    virtual ~ICredentialStore() = default;

    virtual bool saveToken(const QString &service, const QString &key, const QString &token) = 0;
    virtual QString loadToken(const QString &service, const QString &key) = 0;
    virtual bool deleteToken(const QString &service, const QString &key) = 0;
};

} // namespace Security
} // namespace Rep

#endif // ICREDENTIALSTORE_H
