import QtQuick
import qs.Commons

Rectangle {
    id: root
    property string text: ""
    signal clicked()
    implicitWidth: label.implicitWidth + 24
    implicitHeight: label.implicitHeight + 12
    radius: 8
    color: Color.accent
    opacity: enabled ? 1 : 0.5

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Color.background
        font.family: Style.font.family
        font.pixelSize: Style.font.body
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
