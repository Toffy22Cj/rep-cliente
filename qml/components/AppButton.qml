import QtQuick
import QtQuick.Controls
import Rep

/*
 * Botón con variantes: "primary" (por defecto), "secondary", "danger", "ghost".
 */
Button {
    id: control
    property string variant: "primary"

    readonly property color _base: variant === "danger" ? Theme.danger
                                 : variant === "secondary" || variant === "ghost" ? Theme.surface
                                 : Theme.primary
    readonly property color _pressed: variant === "danger" ? Theme.dangerDark
                                    : variant === "secondary" || variant === "ghost" ? Theme.surfaceAlt
                                    : Theme.primaryDark
    readonly property color _fg: variant === "secondary" ? Theme.textPrimary
                               : variant === "ghost" ? Theme.primary
                               : Theme.textOnPrimary

    implicitHeight: Theme.controlHeight
    leftPadding: Theme.spacingM
    rightPadding: Theme.spacingM
    font.pixelSize: Theme.fontBody
    font.weight: Font.DemiBold
    hoverEnabled: true

    contentItem: Label {
        text: control.text
        font: control.font
        color: control._fg
        opacity: control.enabled ? 1.0 : 0.6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.radiusM
        color: control.down ? control._pressed
             : control.hovered && control.variant !== "primary" && control.variant !== "danger" ? Theme.surfaceAlt
             : control._base
        opacity: control.enabled ? 1.0 : 0.5
        border.width: control.variant === "secondary" ? 1 : 0
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
}
