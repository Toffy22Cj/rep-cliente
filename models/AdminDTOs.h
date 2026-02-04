#ifndef ADMINDTOS_H
#define ADMINDTOS_H

#include <QString>
#include <QList>

namespace Rep {

struct UsuarioDTO {
    long long id;
    QString nombre;
    QString correo;
    QString identificacion; // Required for creation
    QString rol; // "ADMIN", "PROFESOR", "ESTUDIANTE"
    bool activo;
    QString password; // Optional, for updates
};

struct CursoAdminDTO {
    long long id;
    int grado;
    QString grupo;
};

struct MateriaAdminDTO {
    long long id;
    QString nombre;
};

struct AsignacionDTO {
    long long id;
    long long profesorId;
    QString profesorNombre;
    long long materiaId;
    QString materiaNombre;
    long long cursoId;
    QString cursoNombre;
};

} // namespace Rep

#endif // ADMINDTOS_H
