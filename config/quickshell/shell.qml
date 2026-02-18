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

    // Idle inhibitor state
    property bool idleInhibited: false

    // Volume popup state
    property bool volumePopupVisible: false
    property bool deviceListExpanded: false
    property bool inputDeviceListExpanded: false

    // Get list of audio output devices (sinks that are hardware, not streams)
    property var audioSinks: {
        var sinks = [];
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values;
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                if (node.audio && node.isSink && !node.isStream) {
                    sinks.push(node);
                }
            }
        }
        return sinks;
    }

    // Get list of audio input devices (sources that are hardware, not streams)
    property var audioSources: {
        var sources = [];
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values;
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                if (node.audio && !node.isSink && !node.isStream) {
                    sources.push(node);
                }
            }
        }
        return sources;
    }

    // Idle inhibitor process (keeps running to inhibit idle)
    Process {
        id: idleInhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
        running: false
    }

    // Power menu process
    Process {
        id: powerMenuProc
        command: ["sh", "-c", "~/.local/bin/rofi-start --powermenu"]
        running: false
    }

    // Track the default audio sink
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // Workspace icons mapping
    property var workspaceIcons: ({
        "1": "",      // Terminal
        "2": "󰈹",     // Firefox
        "3": "󰙯",     // Discord
        "4": "󰎇",     // Music
        "5": ""      // Steam
    })

    // Click-outside overlay (invisible, catches clicks when popup is open)
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: clickOverlay
            required property var modelData
            screen: modelData
            visible: root.volumePopupVisible

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
                onClicked: {
                    root.volumePopupVisible = false
                    root.deviceListExpanded = false
                    root.inputDeviceListExpanded = false
                }
            }
        }
    }

    // Create a bar on each screen
    Variants {
        model: Quickshell.screens

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
            color: "#1e1e2e"

            WlrLayershell.namespace: "quickshell"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: root.volumePopupVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Handle ESC to close popups
            contentItem {
                focus: root.volumePopupVisible
                Keys.onEscapePressed: {
                    root.volumePopupVisible = false
                    root.deviceListExpanded = false
                    root.inputDeviceListExpanded = false
                }
            }

            // Close popups when clicking on the bar background
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    root.volumePopupVisible = false
                    root.deviceListExpanded = false
                    root.inputDeviceListExpanded = false
                }
            }

            // Left section - Power Menu, Idle Inhibitor, Workspaces
            Row {
                id: leftSection
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Power Menu
                Rectangle {
                    width: 28
                    height: 24
                    radius: 4
                    color: powerMenuArea.containsMouse ? "#45475a" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: "󰤄"
                        color: "#cdd6f4"
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: powerMenuArea
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
                    color: idleInhibitorArea.containsMouse ? "#45475a" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: root.idleInhibited ? "󰈈" : "󰈉"
                        color: root.idleInhibited ? "#89b4fa" : "#cdd6f4"
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: idleInhibitorArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.idleInhibited = !root.idleInhibited
                            if (root.idleInhibited) {
                                idleInhibitProc.running = true
                            } else {
                                idleInhibitProc.signal(15) // SIGTERM
                            }
                        }
                    }
                }

                // Workspaces
                Row {
                    id: workspaces
                    spacing: 4

                    Repeater {
                        // Always show workspaces 1-5
                        model: [1, 2, 3, 4, 5]

                        Rectangle {
                            required property int modelData
                            property bool isActive: I3.focusedWorkspace ? I3.focusedWorkspace.name === modelData.toString() : false
                            property bool exists: {
                                if (!I3.workspaces || !I3.workspaces.values) return false;
                                var ws = I3.workspaces.values;
                                for (var i = 0; i < ws.length; i++) {
                                    if (ws[i].name === modelData.toString()) return true;
                                }
                                return false;
                            }

                            width: 32
                            height: 24
                            radius: 4
                            color: isActive ? "#45475a" : (exists ? "#45475a" : "#313244")

                        Text {
                            anchors.centerIn: parent
                            text: root.workspaceIcons[modelData.toString()] || modelData.toString()
                            color: isActive ? "#89b4fa" : (exists ? "#cdd6f4" : "#6c7086")
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: I3.dispatch("workspace number " + modelData)
                        }
                        }
                    }
                }
            }

            // Right section
            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Volume
                Rectangle {
                    id: volumeItem
                    width: 28
                    height: 24
                    radius: 4
                    color: volumeArea.containsMouse ? "#45475a" : "#313244"

                    Text {
                        id: volumeIcon
                        anchors.centerIn: parent
                        property var sink: Pipewire.defaultAudioSink
                        property real vol: sink && sink.audio ? sink.audio.volume : 0
                        property bool muted: sink && sink.audio ? sink.audio.muted : false

                        text: {
                            if (muted || vol === 0) return "󰝟"
                            if (vol < 0.25) return "󰕿"
                            if (vol < 0.50) return "󰖀"
                            return "󰕾"
                        }
                        color: muted ? "#6c7086" : "#cdd6f4"
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: volumeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.volumePopupVisible = !root.volumePopupVisible
                        onWheel: (event) => {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, Pipewire.defaultAudioSink.audio.volume + delta))
                            }
                        }
                    }
                }

                // Battery
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: UPower.displayDevice && UPower.displayDevice.ready
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // percentage is 0-1, multiply by 100 for display
                        property real percentage: UPower.displayDevice ? UPower.displayDevice.percentage * 100 : 0
                        // state: 1=charging, 2=discharging, 4=fully-charged
                        property int batteryState: UPower.displayDevice ? UPower.displayDevice.state : 0
                        property bool charging: batteryState === 1
                        property bool fullyCharged: batteryState === 4
                        
                        text: {
                            if (charging) return "󰂄"  // Charging
                            if (fullyCharged) return "󰂅"  // Plugged in, full
                            if (percentage >= 90) return "󰁹"  // Full
                            if (percentage >= 80) return "󰂂"  // 90
                            if (percentage >= 70) return "󰂁"  // 80
                            if (percentage >= 60) return "󰂀"  // 70
                            if (percentage >= 50) return "󰁿"  // 60
                            if (percentage >= 40) return "󰁾"  // 50
                            if (percentage >= 30) return "󰁽"  // 40
                            if (percentage >= 20) return "󰁼"  // 30
                            if (percentage >= 10) return "󰁻"  // 20
                            return "󰂃"  // Low/critical
                        }
                        color: {
                            if (charging || fullyCharged) return "#a6e3a1"  // Green when charging/full
                            if (percentage <= 10) return "#f38ba8"  // Red 1-10%
                            if (percentage <= 25) return "#fab387"  // Orange 11-25%
                            if (percentage <= 50) return "#f9e2af"  // Yellow 26-50%
                            return "#a6e3a1"  // Green 51-100%
                        }
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                        color: "#cdd6f4"
                        font.pixelSize: 14
                    }
                }

                // Clock
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.time
                    color: "#cdd6f4"
                    font.pixelSize: 14
                }
            }

            // Volume Popup
            PopupWindow {
                id: volumePopup
                visible: root.volumePopupVisible

                anchor.item: volumeItem
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left

                implicitWidth: 320
                implicitHeight: {
                    var h = 48 + 28 + 16 + 28;  // slider + output header + divider + input header
                    if (root.deviceListExpanded) h += root.audioSinks.length * 36;
                    if (root.inputDeviceListExpanded) h += root.audioSources.length * 36;
                    return h + 16;  // margins
                }
                color: "#1e1e2e"

                Column {
                    id: popupContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    // Volume slider row
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 12

                        // Mute toggle icon
                        Text {
                            id: muteIcon
                            anchors.verticalCenter: parent.verticalCenter
                            property bool muted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                                ? Pipewire.defaultAudioSink.audio.muted
                                : false
                            text: muted ? "󰝟" : "󰕾"
                            color: muted ? "#f38ba8" : "#cdd6f4"
                            font.pixelSize: 18
                            font.family: "Symbols Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }
                        }

                        // Slider
                        Rectangle {
                            width: parent.width - muteIcon.width - volumePercent.width - 24
                            height: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#313244"
                            radius: 4

                            Rectangle {
                                id: sliderFill
                                height: parent.height
                                width: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                                    ? parent.width * Pipewire.defaultAudioSink.audio.volume
                                    : 0
                                color: "#89b4fa"
                                radius: 4

                                Behavior on width {
                                    NumberAnimation { duration: 50 }
                                }
                            }

                            // Slider knob
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width, sliderFill.width - width / 2))
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: "#cdd6f4"
                                visible: Pipewire.defaultAudioSink !== null
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                onPressed: updateVolume(mouseX)
                                onPositionChanged: if (pressed) updateVolume(mouseX)

                                function updateVolume(x) {
                                    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                        var vol = Math.max(0, Math.min(1, (x + 8) / (parent.width + 16)))
                                        Pipewire.defaultAudioSink.audio.volume = vol
                                    }
                                }
                            }
                        }

                        // Volume percentage
                        Text {
                            id: volumePercent
                            anchors.verticalCenter: parent.verticalCenter
                            text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                                ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%"
                                : "N/A"
                            color: "#89b4fa"
                            font.pixelSize: 14
                            width: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Output device header
                    Rectangle {
                        width: parent.width
                        height: 28
                        radius: 4
                        color: deviceExpandArea.containsMouse ? "#313244" : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰓃"
                                color: "#89b4fa"
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Output"
                                color: "#6c7086"
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Pipewire.defaultAudioSink
                                    ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name || "Unknown")
                                    : "No device"
                                color: "#cdd6f4"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: parent.width - 90
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.deviceListExpanded ? "󰅃" : "󰅀"
                                color: "#6c7086"
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }
                        }

                        MouseArea {
                            id: deviceExpandArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deviceListExpanded = !root.deviceListExpanded
                        }
                    }

                    // Output device list (shown when expanded)
                    Column {
                        id: deviceColumn
                        width: parent.width
                        spacing: 2
                        visible: root.deviceListExpanded

                        Repeater {
                            id: deviceRepeater
                            model: root.audioSinks

                            Rectangle {
                                required property var modelData
                                property bool isDefault: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id

                                width: deviceColumn.width
                                height: 32
                                radius: 4
                                color: isDefault ? "#45475a" : (deviceMouseArea.containsMouse ? "#313244" : "transparent")

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: isDefault ? "󰄬" : "󰓃"
                                        color: isDefault ? "#a6e3a1" : "#6c7086"
                                        font.pixelSize: 14
                                        font.family: "Symbols Nerd Font"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.description || modelData.name || "Unknown"
                                        color: isDefault ? "#cdd6f4" : "#a6adc8"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }
                                }

                                MouseArea {
                                    id: deviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSink = modelData
                                    }
                                }
                            }
                        }
                    }

                    // Horizontal divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#45475a"
                    }

                    // Input device header
                    Rectangle {
                        width: parent.width
                        height: 28
                        radius: 4
                        color: inputDeviceExpandArea.containsMouse ? "#313244" : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍬"
                                color: "#89b4fa"
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Input"
                                color: "#6c7086"
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Pipewire.defaultAudioSource
                                    ? (Pipewire.defaultAudioSource.description || Pipewire.defaultAudioSource.name || "Unknown")
                                    : "No device"
                                color: "#cdd6f4"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: parent.width - 90
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inputDeviceListExpanded ? "󰅃" : "󰅀"
                                color: "#6c7086"
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }
                        }

                        MouseArea {
                            id: inputDeviceExpandArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.inputDeviceListExpanded = !root.inputDeviceListExpanded
                        }
                    }

                    // Input device list (shown when expanded)
                    Column {
                        id: inputDeviceColumn
                        width: parent.width
                        spacing: 2
                        visible: root.inputDeviceListExpanded

                        Repeater {
                            id: inputDeviceRepeater
                            model: root.audioSources

                            Rectangle {
                                required property var modelData
                                property bool isDefault: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id

                                width: inputDeviceColumn.width
                                height: 32
                                radius: 4
                                color: isDefault ? "#45475a" : (inputDeviceMouseArea.containsMouse ? "#313244" : "transparent")

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: isDefault ? "󰄬" : "󰍬"
                                        color: isDefault ? "#a6e3a1" : "#6c7086"
                                        font.pixelSize: 14
                                        font.family: "Symbols Nerd Font"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.description || modelData.name || "Unknown"
                                        color: isDefault ? "#cdd6f4" : "#a6adc8"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }
                                }

                                MouseArea {
                                    id: inputDeviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSource = modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
