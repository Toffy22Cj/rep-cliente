#include "core/AlmacenLocal.h"

#include <QStandardPaths>
#include <QtTest>

using namespace Rep;

/* Almacén local por usuario: caché sin conexión y borradores de actividades. */
class TstAlmacenLocal : public QObject
{
    Q_OBJECT
private slots:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true); // no toca los datos reales del usuario
        QCoreApplication::setApplicationName(QStringLiteral("rep-pruebas"));
        AlmacenLocal::borrarUsuario();
    }

    void guardaYLeePorClave()
    {
        AlmacenLocal::guardar(QStringLiteral("/api/estudiante/5/notas"), "{\"a\":1}");
        const auto leido = AlmacenLocal::leer(QStringLiteral("/api/estudiante/5/notas"));
        QVERIFY(leido.has_value());
        QCOMPARE(*leido, QByteArray("{\"a\":1}"));
        QVERIFY(!AlmacenLocal::leer(QStringLiteral("/otra/ruta")).has_value());
        QVERIFY(AlmacenLocal::fechaDe(QStringLiteral("/api/estudiante/5/notas")).isValid());
        QVERIFY(AlmacenLocal::tamanoUsuario() > 0);
    }

    void borradoresSobrevivenALimpiarLaCache()
    {
        AlmacenLocal::guardar(QStringLiteral("/api/materiales"), "[]");
        AlmacenLocal::guardarBorrador(4, "{\"respuestas\":[]}");
        AlmacenLocal::borrarUsuario();
        QVERIFY(!AlmacenLocal::leer(QStringLiteral("/api/materiales")).has_value());
        // Un examen a medio resolver no se pierde al limpiar los datos sin conexión
        QCOMPARE(*AlmacenLocal::leerBorrador(4), QByteArray("{\"respuestas\":[]}"));
        AlmacenLocal::eliminarBorrador(4);
        QVERIFY(!AlmacenLocal::leerBorrador(4).has_value());
    }

    void sobrescribirEsAtomico()
    {
        AlmacenLocal::guardarBorrador(9, "v1");
        AlmacenLocal::guardarBorrador(9, "v2-mas-largo");
        QCOMPARE(*AlmacenLocal::leerBorrador(9), QByteArray("v2-mas-largo"));
        AlmacenLocal::eliminarBorrador(9);
    }
};

QTEST_GUILESS_MAIN(TstAlmacenLocal)
#include "tst_almacenlocal.moc"
