#include "AlmacenLocal.h"
#include "SessionManager.h"

#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>

namespace Rep::AlmacenLocal {

QString directorioUsuario()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/sin-conexion/";
    const long long id = SessionManager::instance().userId();
    const QString dir = base + (id > 0 ? QString::number(id) : QStringLiteral("anonimo"));
    QDir().mkpath(dir + "/datos");
    return dir;
}

static QString rutaDe(const QString &clave)
{
    const QByteArray hash = QCryptographicHash::hash(clave.toUtf8(), QCryptographicHash::Sha1).toHex();
    return directorioUsuario() + "/datos/" + QString::fromLatin1(hash) + ".json";
}

void guardar(const QString &clave, const QByteArray &datos)
{
    QSaveFile f(rutaDe(clave));
    if (f.open(QIODevice::WriteOnly)) {
        f.write(datos);
        f.commit();
    }
}

std::optional<QByteArray> leer(const QString &clave)
{
    QFile f(rutaDe(clave));
    if (!f.open(QIODevice::ReadOnly))
        return std::nullopt;
    return f.readAll();
}

QDateTime fechaDe(const QString &clave)
{
    return QFileInfo(rutaDe(clave)).lastModified();
}

qint64 tamanoUsuario()
{
    qint64 total = 0;
    QDirIterator it(directorioUsuario(), QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        total += it.fileInfo().size();
    }
    return total;
}

void borrarUsuario()
{
    const QString dir = directorioUsuario();
    QDir(dir + "/datos").removeRecursively();
    QDir(dir + "/archivos").removeRecursively();
    QFile::remove(dir + "/archivos.json");
}

} // namespace Rep::AlmacenLocal
