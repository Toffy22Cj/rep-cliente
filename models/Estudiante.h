#ifndef ESTUDIANTE_H
#define ESTUDIANTE_H

#include "Usuario.h"

namespace Rep {

struct Estudiante : public Usuario {
    long long cursoId;
    EstadoEstudiante estado;
};

} // namespace Rep

#endif // ESTUDIANTE_H
