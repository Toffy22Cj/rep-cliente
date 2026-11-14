# Pruebas automáticas del cliente (QtTest + CTest):  ctest --test-dir build --output-on-failure
function(rep_prueba nombre)
    qt_add_executable(${nombre} ${nombre}.cpp ServidorFalso.h)
    target_link_libraries(${nombre} PRIVATE repcore Qt6::Test)
    add_test(NAME ${nombre} COMMAND ${nombre})
    # Sin pantalla ni llavero del sistema: plataforma offscreen y almacén en memoria
    set_tests_properties(${nombre} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endfunction()

rep_prueba(tst_preguntamodel)
rep_prueba(tst_almacenlocal)
rep_prueba(tst_sincronizacion)
rep_prueba(tst_httpclient)
rep_prueba(tst_descubrimiento)
