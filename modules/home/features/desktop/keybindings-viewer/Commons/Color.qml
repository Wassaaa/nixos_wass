pragma Singleton
import QtQuick

QtObject {
    readonly property color foreground: "#e5e1e9"
    readonly property color background: "#141218"
    readonly property color accent: "#c2c1ff"
    readonly property color urgent: "#ffb4ab"
    readonly property var menu: ({
        text: "#e5e1e9",
        background: "#1d1b20",
        border: "#938f99",
        scrim: "#99000000",
        selectedText: "#141218",
        selectedBackground: "#c2c1ff",
        selectedBorder: "#c2c1ff"
    })
    readonly property var tooltip: ({
        background: "#36343b",
        border: "#938f99",
        text: "#e5e1e9"
    })
}
