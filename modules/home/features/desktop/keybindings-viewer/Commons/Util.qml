pragma Singleton
import QtQuick

QtObject {
    function alpha(color, opacity) {
        if (typeof color !== "string")
            return Qt.rgba(color.r, color.g, color.b, opacity)
        if (!/^#[0-9a-f]{6}$/i.test(color))
            throw new Error("Unsupported viewer colour: " + color)
        return Qt.rgba(parseInt(color.slice(1, 3), 16) / 255,
                       parseInt(color.slice(3, 5), 16) / 255,
                       parseInt(color.slice(5, 7), 16) / 255, opacity)
    }
}
