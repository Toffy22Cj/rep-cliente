#ifndef AUTHDTOS_H
#define AUTHDTOS_H

#include <QString>
#include "Enums.h"

namespace Rep {

struct AuthUsuarioDTO {
    long long id = 0;
    QString nombre;
    QString apellido;
    QString correo;
    QString identificacion;
    Rol rol = Rol::ESTUDIANTE;
    bool debeCambiarContrasena = false; // contraseña provisional: cambiarla antes de seguir
};

struct LoginRequest {
    QString identificacion;
    QString password;
};

struct LoginResponse {
    AuthUsuarioDTO usuario;
    QString token;
    QString mensaje;
    bool success = false;
};

} // namespace Rep

#endif // AUTHDTOS_H
