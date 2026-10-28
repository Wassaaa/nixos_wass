import QtQuick
import Quickshell
import Quickshell.Io
import "viewer"

ShellRoot {
    ExtendedKeybindingsViewer {
        id: viewer
    }

    IpcHandler {
        target: "keybindings-viewer"
        function toggle(): void {
            if (viewer.opened)
                viewer.close()
            else
                viewer.open("")
        }
        function hide(): void {
            viewer.close()
        }
    }
}
