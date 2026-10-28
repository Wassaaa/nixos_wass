pragma Singleton
import QtQuick

QtObject {
    function none() { return { width: 0, color: "transparent" } }
    function surfaceSpec(surface, role, color, width) { return { color: color, width: width } }
}
