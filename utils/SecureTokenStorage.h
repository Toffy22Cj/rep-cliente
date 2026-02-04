#ifndef SECURETOKENSTORAGE_H
#define SECURETOKENSTORAGE_H

#include <QString>
#include <QObject>

namespace Rep {

class SecureTokenStorage
{
public:
    static void saveToken(const QString &token);
    static QString getToken();
    static void deleteToken();
    static bool hasToken();
    static bool isTokenExpired();
};

} // namespace Rep

#endif // SECURETOKENSTORAGE_H
