import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Item {
    id: root
    
    // Properties
    property string title: "Title"
    property string value: "0"
    property string icon: "📊"
    property color color: "#3498db"
    property color iconBackground: Qt.lighter(color, 1.4)
    
    Layout.fillWidth: true
    Layout.preferredHeight: 120
    
    // Main Card Background
    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 12
        color: "white"
        
        border.color: "#ecf0f1"
        border.width: 1
        
        // Content
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Icon Container
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                radius: 12
                color: root.iconBackground
                
                Label {
                    anchors.centerIn: parent
                    text: root.icon
                    font.pixelSize: 28
                }
            }
            
            // Text Content
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                Label {
                    text: root.value
                    font.pixelSize: 28
                    font.bold: true
                    color: "#2c3e50"
                }
                
                Label {
                    text: root.title
                    font.pixelSize: 14
                    color: "#7f8c8d"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
