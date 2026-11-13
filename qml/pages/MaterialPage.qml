import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Rep
import "../components"

/*
 * Material de estudio.
 *  - Profesor: publica archivos (PDF, imágenes, documentos, audio, vídeo...) para una
 *    materia y curso que tenga asignados, y elimina los suyos.
 *  - Estudiante: ve el material de su curso, filtra por materia y lo abre.
 */
Page {
    id: root
    readonly property bool esProfesor: sessionManager.userRole === "PROFESOR"
    property var materiales: []
    property string error: ""
    property string aviso: ""
    property url archivoSeleccionado: ""
    property bool publicando: false

    background: Rectangle { color: Theme.background }

    header: PageHeader {
        title: qsTr("Material de estudio")
        subtitle: root.esProfesor ? qsTr("Comparta guías, lecturas y recursos con sus cursos")
                                  : qsTr("Guías y recursos publicados por tus profesores")
        AppButton {
            text: qsTr("↻ Actualizar")
            variant: "secondary"
            onClicked: root.cargar()
        }
    }

    ApiRequests { id: requests }

    // Modelos de materias/cursos según el rol
    readonly property var materiaModel: esProfesor ? profesorViewModel.materiaModel : estudianteViewModel.materiaModel

    function idSeleccionado(combo, modelo) {
        return combo.currentIndex >= 0 && modelo && modelo.get ? modelo.get(combo.currentIndex).id : null
    }

    function cargar() {
        let ruta = "/materiales"
        const filtros = []
        if (filtroMateria.currentIndex >= 0)
            filtros.push("materiaId=" + materiaModel.get(filtroMateria.currentIndex).id)
        if (filtros.length) ruta += "?" + filtros.join("&")
        requests.get(ruta, datos => { root.materiales = datos || []; root.error = "" },
                     mensaje => { root.error = mensaje })
    }

    function publicar() {
        error = ""; aviso = ""
        if (archivoSeleccionado.toString() === "") { error = qsTr("Seleccione un archivo"); return }
        const materiaId = idSeleccionado(materiaCombo, profesorViewModel.materiaModel)
        const cursoId = idSeleccionado(cursoCombo, profesorViewModel.cursoModel)
        if (materiaId === null || cursoId === null) { error = qsTr("Seleccione materia y curso"); return }
        publicando = true
        requests.subir("/api/materiales", archivoSeleccionado, {
            titulo: tituloField.text.trim(),
            descripcion: descripcionField.text.trim(),
            materiaId: materiaId,
            cursoId: cursoId
        }, () => {
            publicando = false
            aviso = qsTr("Material publicado")
            tituloField.text = ""; descripcionField.text = ""; archivoSeleccionado = ""
            cargar()
        }, mensaje => { publicando = false; error = mensaje })
    }

    function icono(tipo) {
        if (!tipo) return "📄"
        if (tipo.startsWith("image/")) return "🖼"
        if (tipo === "application/pdf") return "📕"
        if (tipo.startsWith("audio/")) return "🎵"
        if (tipo.startsWith("video/")) return "🎬"
        if (tipo.indexOf("sheet") >= 0 || tipo.indexOf("excel") >= 0) return "📊"
        if (tipo.indexOf("presentation") >= 0 || tipo.indexOf("powerpoint") >= 0) return "📽"
        return "📄"
    }

    Component.onCompleted: {
        if (esProfesor) { profesorViewModel.loadMaterias(); profesorViewModel.loadCursos() }
        else estudianteViewModel.loadMaterias()
        cargar()
    }

    FileDialog {
        id: selectorArchivo
        title: qsTr("Seleccionar archivo")
        onAccepted: {
            root.archivoSeleccionado = selectedFile
            if (tituloField.text === "") {
                const nombre = selectedFile.toString().split("/").pop()
                tituloField.text = decodeURIComponent(nombre.replace(/\.[^.]+$/, ""))
            }
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroll.availableWidth - 2 * Theme.spacingXl, Theme.maxContentWidth)
            x: (scroll.availableWidth - width) / 2
            y: Theme.spacingL
            spacing: Theme.spacingM

            Rectangle {
                Layout.fillWidth: true
                visible: root.error !== "" || root.aviso !== ""
                implicitHeight: mensajeLabel.implicitHeight + 2 * Theme.spacingS
                radius: Theme.radiusM
                color: root.error !== "" ? Theme.dangerSoft : Theme.successSoft
                Label {
                    id: mensajeLabel
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    text: root.error !== "" ? root.error : root.aviso
                    color: root.error !== "" ? Theme.dangerDark : Theme.successDark
                    wrapMode: Text.WordWrap
                }
            }

            // ---------------------------------------------------- publicar (profesor)
            Card {
                Layout.fillWidth: true
                visible: root.esProfesor

                GridLayout {
                    anchors.fill: parent
                    columns: root.width > 900 ? 2 : 1
                    columnSpacing: Theme.spacingM
                    rowSpacing: Theme.spacingS

                    Label {
                        Layout.columnSpan: parent.columns
                        text: qsTr("Publicar material")
                        font.pixelSize: Theme.fontSubtitle
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                    ComboBox {
                        id: materiaCombo
                        Layout.fillWidth: true
                        model: profesorViewModel.materiaModel
                        textRole: "nombre"
                        displayText: currentIndex >= 0 ? currentText : qsTr("Materia…")
                    }
                    ComboBox {
                        id: cursoCombo
                        Layout.fillWidth: true
                        model: profesorViewModel.cursoModel
                        textRole: "nombre"
                        displayText: currentIndex >= 0 ? currentText : qsTr("Curso…")
                    }
                    AppTextField {
                        id: tituloField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Título (por defecto, el nombre del archivo)")
                    }
                    AppTextField {
                        id: descripcionField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Descripción (opcional)")
                    }
                    RowLayout {
                        Layout.columnSpan: parent.columns
                        Layout.fillWidth: true
                        AppButton {
                            text: qsTr("📎 Elegir archivo")
                            variant: "secondary"
                            onClicked: selectorArchivo.open()
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.archivoSeleccionado.toString() !== ""
                                  ? decodeURIComponent(root.archivoSeleccionado.toString().split("/").pop())
                                  : qsTr("PDF, imágenes, Office, texto, audio, vídeo o ZIP (máx. 25 MB)")
                            color: root.archivoSeleccionado.toString() !== "" ? Theme.textPrimary : Theme.textMuted
                            elide: Text.ElideMiddle
                        }
                        AppButton {
                            text: root.publicando ? qsTr("Publicando…") : qsTr("Publicar")
                            enabled: !root.publicando
                            onClicked: root.publicar()
                        }
                    }
                }
            }

            // ---------------------------------------------------- filtro
            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Materia:"); color: Theme.textSecondary }
                ComboBox {
                    id: filtroMateria
                    Layout.preferredWidth: 280
                    model: root.materiaModel
                    textRole: "nombre"
                    currentIndex: -1
                    displayText: currentIndex < 0 ? qsTr("Todas las materias") : currentText
                    onActivated: root.cargar()
                }
                ToolButton {
                    visible: filtroMateria.currentIndex >= 0
                    text: "\u2715"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Quitar filtro")
                    onClicked: { filtroMateria.currentIndex = -1; root.cargar() }
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: qsTr("%n archivo(s)", "", root.materiales.length)
                    color: Theme.textSecondary
                }
            }

            EmptyState {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingL
                visible: root.materiales.length === 0 && requests.enCurso === 0
                icon: "📚"
                title: qsTr("No hay material publicado")
                message: root.esProfesor ? qsTr("Publique el primero con el formulario de arriba.")
                                         : qsTr("Cuando tus profesores compartan material aparecerá aquí.")
            }

            // ---------------------------------------------------- lista
            Repeater {
                model: root.materiales
                delegate: Card {
                    id: item
                    required property var modelData
                    Layout.fillWidth: true
                    hoverable: true
                    padding: Theme.spacingM

                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.spacingM

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: Theme.radiusM
                            color: Theme.primarySoft
                            Label { anchors.centerIn: parent; text: root.icono(item.modelData.tipoContenido); font.pixelSize: 24 }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: item.modelData.titulo
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                visible: !!item.modelData.descripcion
                                text: item.modelData.descripcion || ""
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Label {
                                text: item.modelData.materiaNombre + " · " + item.modelData.cursoNombre
                                      + " · " + item.modelData.nombreArchivo
                                      + " · " + api.tamanoLegible(item.modelData.tamanoBytes || 0)
                                      + (root.esProfesor ? "" : " · " + item.modelData.profesorNombre)
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        AppButton {
                            text: item.modelData.esImagen ? qsTr("Ver") : qsTr("Abrir")
                            variant: "secondary"
                            onClicked: api.abrir(item.modelData.archivoUrl)
                        }
                        AppButton {
                            visible: root.esProfesor
                            text: qsTr("Eliminar")
                            variant: "danger"
                            onClicked: { confirmar.material = item.modelData; confirmar.open() }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingL }
        }
    }

    Connections {
        target: api
        function onArchivoFallo(ruta, mensaje) { root.error = mensaje }
    }

    Dialog {
        id: confirmar
        property var material: null
        anchors.centerIn: parent
        modal: true
        title: qsTr("Eliminar material")
        standardButtons: Dialog.Yes | Dialog.No
        width: Math.min(root.width - 40, 420)
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: confirmar.material ? qsTr("¿Eliminar «%1»? Los estudiantes dejarán de verlo.").arg(confirmar.material.titulo) : ""
        }
        onAccepted: requests.eliminar("/materiales/" + material.id,
                                      () => { root.aviso = qsTr("Material eliminado"); root.cargar() },
                                      mensaje => { root.error = mensaje })
    }
}
