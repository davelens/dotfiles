import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".."

Item {
    id: battery
    anchors.verticalCenter: parent.verticalCenter
    width: batteryRow.width
    height: batteryRow.height
    visible: UPower.displayDevice && UPower.displayDevice.ready

    property real percentage: UPower.displayDevice ? UPower.displayDevice.percentage * 100 : 0
    property int batteryState: UPower.displayDevice ? UPower.displayDevice.state : 0
    property bool charging: batteryState === 1
    property bool fullyCharged: batteryState === 4
    property real changeRate: UPower.displayDevice ? UPower.displayDevice.changeRate : 0
    property real timeToEmpty: UPower.displayDevice ? UPower.displayDevice.timeToEmpty : 0
    property real timeToFull: UPower.displayDevice ? UPower.displayDevice.timeToFull : 0

    function formatTime(seconds) {
        if (seconds <= 0) return ""
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function getBatteryIcon(percentage, charging, fullyCharged) {
        if (charging) return "󰂄"
        if (fullyCharged) return "󰂅"
        if (percentage >= 90) return "󰁹"
        if (percentage >= 80) return "󰂂"
        if (percentage >= 70) return "󰂁"
        if (percentage >= 60) return "󰂀"
        if (percentage >= 50) return "󰁿"
        if (percentage >= 40) return "󰁾"
        if (percentage >= 30) return "󰁽"
        if (percentage >= 20) return "󰁼"
        if (percentage >= 10) return "󰁻"
        return "󰂃"
    }

    function getBatteryColor(percentage, charging, fullyCharged) {
        if (charging || fullyCharged) return Colors.green
        if (percentage <= 10) return Colors.red
        if (percentage <= 25) return Colors.peach
        if (percentage <= 50) return Colors.yellow
        return Colors.green
    }

    Row {
        id: batteryRow
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: battery.getBatteryIcon(battery.percentage, battery.charging, battery.fullyCharged)
            color: battery.getBatteryColor(battery.percentage, battery.charging, battery.fullyCharged)
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(battery.percentage) + "%"
            color: Colors.text
            font.pixelSize: 14
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    // Tooltip
    PopupWindow {
        visible: hoverArea.containsMouse

        anchor.item: battery
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -10

        implicitWidth: tooltipText.implicitWidth + 24
        implicitHeight: tooltipText.implicitHeight + 16
        color: Colors.crust

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            color: Colors.text
            font.pixelSize: 14

            text: {
                var rate = Math.abs(battery.changeRate)
                var parts = []

                parts.push(rate.toFixed(1) + " W")

                if (!battery.charging && !battery.fullyCharged && battery.timeToEmpty > 0) {
                    parts.push(battery.formatTime(battery.timeToEmpty) + " remaining")
                } else if (battery.charging && battery.timeToFull > 0) {
                    parts.push(battery.formatTime(battery.timeToFull) + " until full")
                }

                return parts.join("  ·  ")
            }
        }
    }
}
