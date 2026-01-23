import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property date selectedDate: new Date()
    signal dateSelected(date date)
    
    // Calculate first day of current month (0-6, where 0 is Monday or Sunday depending on locale, 
    // but the grid logic assumes a specific start)
    // The user's code: d.getDay() === 0 ? 6 : d.getDay() - 1 // Lunes=0
    property int firstDayOfMonth: {
        var d = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1)
        return d.getDay() === 0 ? 6 : d.getDay() - 1 
    }
    
    // Calculate days in month
    property int daysInMonth: {
        return new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, 0).getDate()
    }
    
    ColumnLayout {
        anchors.fill: parent
        
        // Mes/Año
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                text: "<"
                onClicked: root.selectedDate = new Date(root.selectedDate.setMonth(root.selectedDate.getMonth() - 1))
            }
            
            Label {
                text: root.selectedDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
            }
            
            Button {
                text: ">"
                onClicked: root.selectedDate = new Date(root.selectedDate.setMonth(root.selectedDate.getMonth() + 1))
            }
        }
        
        // Días de la semana
        GridLayout {
            columns: 7
            Layout.fillWidth: true
            
            Repeater {
                model: ["L", "M", "M", "J", "V", "S", "D"]
                delegate: Label {
                    text: modelData
                    font.bold: true
                    color: "#7f8c8d"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }
        
        // Días del mes
        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Repeater {
                model: 42 // 6 weeks
                
                delegate: Button {
                    property int dayNumber: index - firstDayOfMonth + 1
                    property bool isCurrentMonth: dayNumber > 0 && dayNumber <= daysInMonth
                    
                    text: isCurrentMonth ? dayNumber : ""
                    flat: true
                    enabled: isCurrentMonth
                    
                    background: Rectangle {
                        color: parent.pressed ? "#3498db" : 
                               isCurrentMonth && dayNumber === root.selectedDate.getDate() ? "#3498db" : 
                               "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Label {
                        text: parent.text
                        color: parent.pressed || (isCurrentMonth && dayNumber === root.selectedDate.getDate()) ? 
                               "white" : "#2c3e50"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        var d = new Date(root.selectedDate)
                        d.setDate(dayNumber)
                        root.selectedDate = d
                        root.dateSelected(d)
                    }
                }
            }
        }
    }
}
