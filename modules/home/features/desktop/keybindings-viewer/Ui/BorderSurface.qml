import QtQuick

Rectangle {
    property var borderSpec: ({ width: 0, color: "transparent" })
    border.width: borderSpec.width
    border.color: borderSpec.color
}
