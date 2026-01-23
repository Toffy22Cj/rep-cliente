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

} // namespace Rep

#endif // PROFESORDTOS_H
