import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 400
    height: 600
    title: "API Client"

    Button {
        text: "Proyecto listo 🚀"
        anchors.centerIn: parent
        onClicked: console.log("QML funcionando")
    }
}
