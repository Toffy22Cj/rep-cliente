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

static QString rutaBorrador(long long actividadId)
{
    const QString dir = directorioUsuario() + "/borradores";
    QDir().mkpath(dir);
    return dir + "/actividad-" + QString::number(actividadId) + ".json";
}

void guardarBorrador(long long actividadId, const QByteArray &datos)
{
    QSaveFile f(rutaBorrador(actividadId));
    if (f.open(QIODevice::WriteOnly)) {
        f.write(datos);
        f.commit(); // escritura atómica: un corte de luz no deja el borrador a medias
    }
}

std::optional<QByteArray> leerBorrador(long long actividadId)
{
    QFile f(rutaBorrador(actividadId));
    if (!f.open(QIODevice::ReadOnly))
        return std::nullopt;
    return f.readAll();
}

void eliminarBorrador(long long actividadId)
{
    QFile::remove(rutaBorrador(actividadId));
}

} // namespace Rep::AlmacenLocal
