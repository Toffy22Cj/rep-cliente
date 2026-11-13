#ifndef ALMACENLOCAL_H
#define ALMACENLOCAL_H

#include <QByteArray>
#include <QDateTime>
#include <QString>
#include <optional>

namespace Rep {

/**
 * Almacenamiento local por usuario para trabajar sin conexión.
 *
 * Guarda la última respuesta correcta de cada consulta (clave = ruta + parámetros) en
 * <AppDataLocation>/sin-conexion/<usuario>/. Cada usuario tiene su propio directorio y
 * puede borrarlo desde su perfil.
 */
namespace AlmacenLocal {

QString directorioUsuario();
void guardar(const QString &clave, const QByteArray &datos);
std::optional<QByteArray> leer(const QString &clave);
QDateTime fechaDe(const QString &clave);
/** Tamaño total ocupado por el usuario actual (datos + archivos). */
qint64 tamanoUsuario();
/** Borra los datos sin conexión del usuario actual (no la cola de envíos pendientes). */
void borrarUsuario();

} // namespace AlmacenLocal
} // namespace Rep

#endif // ALMACENLOCAL_H
