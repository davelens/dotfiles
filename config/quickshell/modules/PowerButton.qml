import QtQuick
import Quickshell.Io
import ".."

BarButton {
    icon: "⏻"
    iconSize: 28
    iconColor: Colors.blue

    Process {
        id: powerMenuProc
        command: ["sh", "-c", "~/.local/bin/rofi-start --powermenu"]
        running: false
    }

    onClicked: powerMenuProc.running = true
}
