#ifndef PROFESOR_H
#define PROFESOR_H

#include "Usuario.h"

namespace Rep {

struct Profesor : public Usuario {
    EstadoProfesor estado;
};

} // namespace Rep

#endif // PROFESOR_H
