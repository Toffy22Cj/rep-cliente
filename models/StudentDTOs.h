#ifndef STUDENTDTOS_H
#define STUDENTDTOS_H

#include <QString>
#include <QDateTime>
#include <QDate>
#include <QList>
#include "Enums.h"

namespace Rep {

struct MateriaDTO {
    long long id;
    QString nombre;
};

struct OpcionDTO {
    long long id;
    QString texto;
    bool esCorrecta;
    bool archivoDisponible;
    QString nombreArchivo;
    QString archivoUrl;
};

struct PreguntaDTO {
    long long id;
    QString enunciado;
    QString tipo;
    QList<OpcionDTO> opciones;
    bool archivoDisponible;
    QString nombreArchivo;
    QString archivoUrl;
    // UI State / Response management
    long long opcionSeleccionadaId = 0;
    QString respuestaAbierta;
};

struct ActividadDTO {
    long long id;
    int duracionMinutos;
    QString titulo;
    QString tipo; // e.g., "EXAMEN", "QUIZ", "TALLER"
    QString descripcion;
    QDate fechaEntrega;
    QDateTime fechaCreacion;
    long long profesorId;
    long long materiaId;
    QString materiaNombre;
    long long cursoId;
    QString cursoNombre;
};

struct ActividadConPreguntasDTO {
    long long id;
    QString titulo;
    QString descripcion;
    QList<PreguntaDTO> preguntas;
};

struct RespuestaPreguntaDTO {
    long long preguntaId;
    long long opcionId;
    QString respuestaAbierta;
    QString archivoAdjunto;
    QString nombreArchivo;
};

struct ActividadResueltaDTO {
    long long actividadId;
    long long estudianteId;
    QDateTime fechaEntrega;
    QList<RespuestaPreguntaDTO> respuestas;
    int duracionMinutos;
    QString observaciones;
};

struct ResultadoPreguntaDTO {
    long long preguntaId;
    bool esCorrecta;
    QString retroalimentacion;
};

struct ResultadoActividadDTO {
    long long actividadId;
    long long estudianteId;
    float nota;
    QList<ResultadoPreguntaDTO> resultadosPreguntas;
    QString observaciones;
    QString nombreEstudiante;
    QString fechaEntrega;
};

} // namespace Rep

#endif // STUDENTDTOS_H
