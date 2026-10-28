pragma Singleton
import QtQuick

QtObject {
    readonly property real cornerRadius: 16
    readonly property var font: ({
        family: "sans-serif",
        menuFamily: "sans-serif",
        body: 14,
        title: 16,
        heading: 20,
        displayLarge: 32
    })
    function space(value) { return value }
}
