import Quickshell
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    // =========================================================================
    // STATE
    // =========================================================================

    // Popup management - only one popup open at a time, on one screen
    property string activePopup: ""  // "", "volume", "brightness", "display"
    property var activePopupScreen: null

    // Device list expansion state (for volume popup height calculation)
    property bool outputDevicesExpanded: false
    property bool inputDevicesExpanded: false

    // Idle inhibitor
    property bool idleInhibited: false

    // Workspace icons
    readonly property var workspaceIcons: ({
        "1": "",
        "2": "󰈹",
        "3": "󰙯",
        "4": "󰎇",
        "5": ""
    })

    // =========================================================================
    // HELPER FUNCTIONS
    // =========================================================================

    function togglePopup(name, screen) {
        if (activePopup === name && activePopupScreen === screen) {
            closePopups()
        } else {
            activePopup = name
            activePopupScreen = screen
            outputDevicesExpanded = false
            inputDevicesExpanded = false
        }
    }

    function closePopups() {
        activePopup = ""
        activePopupScreen = null
        outputDevicesExpanded = false
        inputDevicesExpanded = false
    }

    function getVolumeIcon(volume, muted) {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.25) return "󰕿"
        if (volume < 0.50) return "󰖀"
        return "󰕾"
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

    // =========================================================================
    // COMPUTED PROPERTIES
    // =========================================================================

    property var audioSinks: {
        var sinks = []
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i]
                if (node.audio && node.isSink && !node.isStream) {
                    sinks.push(node)
                }
            }
        }
        return sinks
    }

    property var audioSources: {
        var sources = []
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i]
                if (node.audio && !node.isSink && !node.isStream) {
                    sources.push(node)
                }
            }
        }
        return sources
    }

    // =========================================================================
    // PROCESSES
    // =========================================================================

    Process {
        id: idleInhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
        running: false
    }

    Process {
        id: powerMenuProc
        command: ["sh", "-c", "~/.local/bin/rofi-start --powermenu"]
        running: false
    }

    // =========================================================================
    // PIPEWIRE TRACKING
    // =========================================================================

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // =========================================================================
    // CLICK-OUTSIDE OVERLAY
    // =========================================================================

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.activePopup !== ""

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell-overlay"
            WlrLayershell.layer: WlrLayer.Top

            MouseArea {
                anchors.fill: parent
                onClicked: root.closePopups()
            }
        }
    }

    // =========================================================================
    // BAR (only on primary screen)
    // =========================================================================

    Variants {
        model: DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: Colors.crust

            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top

            // -----------------------------------------------------------------
            // LEFT SECTION
            // -----------------------------------------------------------------
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                // Power Menu
                Rectangle {
                    width: 28
                    height: 24
                    radius: 4
                    color: powerArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        id: powerIcon
                        anchors.centerIn: parent
                        color: Colors.blue
                        font.pixelSize: 28
                        font.family: "Symbols Nerd Font"
                        text: "⏻"
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerMenuProc.running = true
                    }
                }

                // Idle Inhibitor
                Rectangle {
                    width: 28
                    height: 24
                    radius: 4
                    color: idleArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        id: idleIcon
                        anchors.centerIn: parent
                        color: root.idleInhibited ? Colors.blue : Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                        // 󰈈 = eye open (activated), 󰈉 = eye closed (deactivated)
                        text: root.idleInhibited ? "󰈈" : "󰈉"
                    }

                    MouseArea {
                        id: idleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.idleInhibited = !root.idleInhibited
                            if (root.idleInhibited) {
                                idleInhibitProc.running = true
                            } else {
                                idleInhibitProc.signal(15)  // SIGTERM
                            }
                        }
                    }
                }

                // Workspaces (persistent 1-5)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: ["1", "2", "3", "4", "5"]

                        Rectangle {
                            required property string modelData
                            property var workspace: I3.findWorkspaceByName(modelData)
                            property bool isFocused: workspace ? workspace.focused : false
                            property bool isVisible: workspace ? workspace.visible : false
                            property bool hasWindows: workspace !== null

                            width: 28
                            height: 24
                            radius: 4
                            color: isFocused ? Colors.surface1 : (workspaceArea.containsMouse ? Colors.surface0 : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: root.workspaceIcons[modelData] || modelData
                                color: isFocused ? Colors.blue : (hasWindows ? Colors.text : Colors.overlay0)
                                font.pixelSize: 18
                                font.family: root.workspaceIcons[modelData] ? "Symbols Nerd Font" : undefined
                            }

                            MouseArea {
                                id: workspaceArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: I3.dispatch("workspace " + modelData)
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // RIGHT SECTION
            // -----------------------------------------------------------------
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Display
                Rectangle {
                    id: displayButton
                    width: 28
                    height: 24
                    radius: 4
                    color: displayArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "󰍹"
                        color: Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: displayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePopup("display", panel.modelData)
                    }
                }

                // Brightness
                Rectangle {
                    id: brightnessButton
                    width: 28
                    height: 24
                    radius: 4
                    color: brightnessArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: BrightnessManager.getIcon(BrightnessManager.averageLevel)
                        color: Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: brightnessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePopup("brightness", panel.modelData)
                        onWheel: event => {
                            var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                            // Apply to all displays
                            for (var i = 0; i < BrightnessManager.displays.length; i++) {
                                var d = BrightnessManager.displays[i]
                                var newLevel = Math.max(0.01, Math.min(1, d.brightness + delta))
                                BrightnessManager.setBrightness(d.id, newLevel)
                            }
                        }
                    }
                }

                // Volume
                Rectangle {
                    id: volumeButton
                    width: 28
                    height: 24
                    radius: 4
                    color: volumeArea.containsMouse ? Colors.surface1 : Colors.surface0

                    property var sink: Pipewire.defaultAudioSink
                    property real volume: sink && sink.audio ? sink.audio.volume : 0
                    property bool muted: sink && sink.audio ? sink.audio.muted : false

                    Text {
                        anchors.centerIn: parent
                        text: root.getVolumeIcon(volumeButton.volume, volumeButton.muted)
                        color: volumeButton.muted ? Colors.overlay0 : Colors.text
                        font.pixelSize: 24
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: volumeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePopup("volume", panel.modelData)
                        onWheel: event => {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, Pipewire.defaultAudioSink.audio.volume + delta))
                            }
                        }
                    }
                }

                // Battery
                Item {
                    id: batteryItem
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

                    Row {
                        id: batteryRow
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.getBatteryIcon(batteryItem.percentage, batteryItem.charging, batteryItem.fullyCharged)
                            color: root.getBatteryColor(batteryItem.percentage, batteryItem.charging, batteryItem.fullyCharged)
                            font.pixelSize: 18
                            font.family: "Symbols Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(batteryItem.percentage) + "%"
                            color: Colors.text
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: batteryHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                // Battery tooltip
                PopupWindow {
                    visible: batteryHoverArea.containsMouse

                    anchor.item: batteryItem
                    anchor.edges: Edges.Bottom | Edges.Right
                    anchor.gravity: Edges.Bottom | Edges.Left
                    anchor.margins.bottom: -2

                    implicitWidth: batteryTooltipText.implicitWidth + 24
                    implicitHeight: batteryTooltipText.implicitHeight + 16
                    color: Colors.crust

                    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

                    Text {
                        id: batteryTooltipText
                        anchors.centerIn: parent
                        color: Colors.text
                        font.pixelSize: 14

                        text: {
                            var rate = Math.abs(batteryItem.changeRate)
                            var parts = []

                            parts.push(rate.toFixed(1) + " W")

                            if (!batteryItem.charging && !batteryItem.fullyCharged && batteryItem.timeToEmpty > 0) {
                                parts.push(batteryItem.formatTime(batteryItem.timeToEmpty) + " remaining")
                            } else if (batteryItem.charging && batteryItem.timeToFull > 0) {
                                parts.push(batteryItem.formatTime(batteryItem.timeToFull) + " until full")
                            }

                            return parts.join("  ·  ")
                        }
                    }
                }

                // Clock
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.time
                    color: Colors.text
                    font.pixelSize: 14
                }
            }

            // -----------------------------------------------------------------
            // POPUPS
            // -----------------------------------------------------------------

            VolumePopup {
                anchorItem: volumeButton
                isOpen: root.activePopup === "volume" && root.activePopupScreen === panel.modelData
                audioSinks: root.audioSinks
                audioSources: root.audioSources
                outputDevicesExpanded: root.outputDevicesExpanded
                inputDevicesExpanded: root.inputDevicesExpanded
                onOutputExpandedChanged: expanded => root.outputDevicesExpanded = expanded
                onInputExpandedChanged: expanded => root.inputDevicesExpanded = expanded
            }

            BrightnessPopup {
                anchorItem: brightnessButton
                isOpen: root.activePopup === "brightness" && root.activePopupScreen === panel.modelData
            }

            DisplayPopup {
                anchorItem: displayButton
                isOpen: root.activePopup === "display" && root.activePopupScreen === panel.modelData
                onCloseRequested: root.closePopups()
            }
        }
    }
}
