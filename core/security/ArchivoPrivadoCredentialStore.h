#ifndef ARCHIVOPRIVADOCREDENTIALSTORE_H
#define ARCHIVOPRIVADOCREDENTIALSTORE_H

#include "ICredentialStore.h"
#include <QString>

namespace Rep {
namespace Security {

/**
 * Guarda el token en el almacenamiento privado de la aplicación (solo lectura/escritura
 * del propio usuario del sistema). En Android cada app tiene su propio espacio aislado,
 * que es el mecanismo de protección de la plataforma; se usa allí en lugar de QtKeychain.
 */
class ArchivoPrivadoCredentialStore : public ICredentialStore
{
public:
    bool saveToken(const QString &service, const QString &key, const QString &token) override;
    QString loadToken(const QString &service, const QString &key) override;
    bool deleteToken(const QString &service, const QString &key) override;

private:
    static QString ruta(const QString &service, const QString &key);
};

} // namespace Security
} // namespace Rep

#endif // ARCHIVOPRIVADOCREDENTIALSTORE_H
