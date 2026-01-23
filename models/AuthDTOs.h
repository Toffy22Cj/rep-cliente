#ifndef AUTHDTOS_H
#define AUTHDTOS_H

#include <QString>
#include "Enums.h"

namespace Rep {

struct AuthUsuarioDTO {
    long long id;
    QString nombre;
    QString correo;
    QString identificacion;
    Rol rol;
};

struct LoginRequest {
    QString identificacion;
    QString password;
};

struct LoginResponse {
    AuthUsuarioDTO usuario;
    QString token;
    QString mensaje;
    bool success;
};

} // namespace Rep

#endif // AUTHDTOS_H
