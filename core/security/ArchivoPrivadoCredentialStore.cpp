#include "ArchivoPrivadoCredentialStore.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QStandardPaths>

namespace Rep {
namespace Security {

QString ArchivoPrivadoCredentialStore::ruta(const QString &service, const QString &key)
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/credenciales";
    QDir().mkpath(dir);
    QFile::setPermissions(dir, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
    const QByteArray nombre = QCryptographicHash::hash((service + '/' + key).toUtf8(), QCryptographicHash::Sha1).toHex();
    return dir + '/' + QString::fromLatin1(nombre);
}

bool ArchivoPrivadoCredentialStore::saveToken(const QString &service, const QString &key, const QString &token)
{
    QSaveFile f(ruta(service, key));
    if (!f.open(QIODevice::WriteOnly))
        return false;
    f.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    f.write(token.toUtf8());
    return f.commit();
}

QString ArchivoPrivadoCredentialStore::loadToken(const QString &service, const QString &key)
{
    QFile f(ruta(service, key));
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return QString::fromUtf8(f.readAll());
}

bool ArchivoPrivadoCredentialStore::deleteToken(const QString &service, const QString &key)
{
    const QString r = ruta(service, key);
    return !QFile::exists(r) || QFile::remove(r);
}

} // namespace Security
} // namespace Rep
