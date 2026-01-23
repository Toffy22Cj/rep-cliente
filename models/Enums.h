#ifndef ENUMS_H
#define ENUMS_H

namespace Rep {

enum class Rol {
    ADMIN,
    PROFESOR,
    ESTUDIANTE
};

enum class TipoIdentificacion {
    CC,
    TI
};

enum class Sexo {
    MASCULINO,
    FEMENINO,
    OTRO
};

enum class EstadoProfesor {
    ACTIVO,
    RETIRADO
};

enum class EstadoEstudiante {
    ACTIVO,
    RETIRADO,
    GRADUADO,
    SUSPENDIDO
};

enum class TipoPregunta {
    OPCION_MULTIPLE,
    VERDADERO_FALSO,
    RESPUESTA_ABIERTA
};

} // namespace Rep

#endif // ENUMS_H
