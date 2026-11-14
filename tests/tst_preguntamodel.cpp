#include "models/PreguntaModel.h"

#include <QSignalSpy>
#include <QtTest>

using namespace Rep;

/* Modelo de preguntas que usa la pantalla de resolución de actividades. */
class TstPreguntaModel : public QObject
{
    Q_OBJECT

    static QList<PreguntaDTO> preguntas()
    {
        PreguntaDTO multiple;
        multiple.id = 10;
        multiple.enunciado = QStringLiteral("¿2 + 2?");
        multiple.tipo = QStringLiteral("OPCION_MULTIPLE");
        multiple.opciones = {OpcionDTO{100, "3", false, false, {}, {}}, OpcionDTO{101, "4", true, false, {}, {}}};
        PreguntaDTO abierta;
        abierta.id = 11;
        abierta.enunciado = QStringLiteral("Explique");
        abierta.tipo = QStringLiteral("RESPUESTA_ABIERTA");
        return {multiple, abierta};
    }

private slots:
    void exponeLosDatosPorRol()
    {
        PreguntaModel m;
        m.setQuestions(preguntas());
        QCOMPARE(m.rowCount(), 2);
        QCOMPARE(m.data(m.index(0), PreguntaModel::EnunciadoRole).toString(), QStringLiteral("¿2 + 2?"));
        QCOMPARE(m.data(m.index(0), PreguntaModel::OpcionesRole).toList().size(), 2);
        // La solución no debe depender del cliente: el modelo solo transporta lo recibido
        QVERIFY(!m.data(m.index(5), PreguntaModel::EnunciadoRole).isValid());
    }

    void seleccionarYResponderNotificaCambios()
    {
        PreguntaModel m;
        m.setQuestions(preguntas());
        QSignalSpy cambios(&m, &QAbstractItemModel::dataChanged);
        m.selectOpcion(0, 101);
        m.setRespuestaAbierta(1, QStringLiteral("Mi respuesta"));
        QCOMPARE(cambios.count(), 2); // dispara el autoguardado del borrador
        QCOMPARE(m.data(m.index(0), PreguntaModel::OpcionSeleccionadaIdRole).toLongLong(), 101LL);
        QCOMPARE(m.questions().at(1).respuestaAbierta, QStringLiteral("Mi respuesta"));
    }

    void cuentaLasPreguntasSinResponder()
    {
        PreguntaModel m;
        m.setQuestions(preguntas());
        QCOMPARE(m.sinResponder(), 2);
        m.selectOpcion(0, 100);
        QCOMPARE(m.sinResponder(), 1);
        m.setRespuestaAbierta(1, QStringLiteral("   ")); // solo espacios no cuenta
        QCOMPARE(m.sinResponder(), 1);
        m.setRespuestaAbierta(1, QStringLiteral("Texto"));
        QCOMPARE(m.sinResponder(), 0);
    }

    void indicesFueraDeRangoNoRompen()
    {
        PreguntaModel m;
        m.setQuestions(preguntas());
        m.selectOpcion(7, 1);
        m.setRespuestaAbierta(-1, QStringLiteral("x"));
        QCOMPARE(m.sinResponder(), 2);
    }
};

QTEST_GUILESS_MAIN(TstPreguntaModel)
#include "tst_preguntamodel.moc"
