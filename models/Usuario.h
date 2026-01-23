#ifndef USUARIO_H
#define USUARIO_H

#include <QString>
#include <QDateTime>
#include <QDate>
#include "Enums.h"

namespace Rep {

struct Usuario {
    long long id;
    QString nombre;
    QString correo;
    QString identificacion;
    TipoIdentificacion tipoIdentificacion;
    Rol rol;
    int edad;
    QDateTime creadoEn;
    QDate fechaIngreso;
    bool activo;
    Sexo sexo;
};

} // namespace Rep

#endif // USUARIO_H
