#ifndef PROFESORDTOS_H
#define PROFESORDTOS_H

#include <QString>
#include <QDateTime>
#include <QList>

namespace Rep {

struct CursoDTO {
    long long id;
    QString nombre;
    int grado;
    QString grupo;
};

struct MateriaAsignadaDTO {
    long long id;
    QString nombre;
    QList<CursoDTO> cursos;
};

struct ProfesorDashboardDTO {
    int totalEstudiantes;
    int actividadesActivas;
    int entregasPendientes;
    QList<MateriaAsignadaDTO> materias;
};

struct RespuestaEstudianteSimplificadaDTO {
    long long id;
    long long estudianteId;
    QString nombreEstudiante;
    float nota;
    QDateTime fechaEntrega;
    bool calificada;
};

struct EstudianteSimplificadoDTO {
    long long id;
    QString nombre;
    QString identificacion;
    QString correo;
};

struct AsistenciaDTO {
    long long estudianteId;
    QString nombreEstudiante;
    QString estado;        // "PRESENTE" | "NO_INGRESO" | "EXCUSA"
    QString tipoExcusa;    // Opcional, solo si estado == "EXCUSA"
    QString observacion;   // Texto libre (era "observaciones")
};

struct ActividadCreateDTO {
    QString titulo;
    QString tipo; // e.g., "EXAMEN", "QUIZ", "TALLER"
    QString descripcion;
    QDate fechaEntrega;
    int duracionMinutos;
    long long materiaId;
    long long cursoId;
};

struct OpcionRequestDTO {
    QString texto;
    bool esCorrecta;
};

struct PreguntaRequestDTO {
    long long actividadId;
    QString enunciado;
    QString tipo;
    QList<OpcionRequestDTO> opciones;
};

struct ReportePromedioDTO {
    QString estudianteNombre;
    float promedio;
};

struct ReporteEntregaDTO {
    long long respuestaId; // 0 if not submitted
    long long estudianteId;
    QString estudianteNombre;
    QString estado; // "ENTREGADO", "PENDIENTE"
    QDateTime fechaEntrega;
    bool calificada;
    float nota;
};

struct EstadisticaActividadDTO {
    double promedio;
    double notaMinima;
    double notaMaxima;
    int totalEntregas;
    int totalEstudiantes;
};

} // namespace Rep

#endif // PROFESORDTOS_H
