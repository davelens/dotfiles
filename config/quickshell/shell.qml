import Quickshell
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    // Idle inhibitor state
    property bool idleInhibited: false

    // Volume popup state
    property bool volumePopupVisible: false
    property bool deviceListExpanded: false

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
                }
            }

            // Close popups when clicking on the bar background
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    root.volumePopupVisible = false
                    root.deviceListExpanded = false
                }
            }

            // Left section - Workspaces
            Row {
                id: workspaces
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    // Always show workspaces 1-5
                    model: [1, 2, 3, 4, 5]

                    Rectangle {
                        required property int modelData
                        property var workspace: I3.findWorkspaceByName(modelData.toString())
                        property bool isActive: workspace ? workspace.focused : false
                        property bool exists: workspace !== null

                        width: 32
                        height: 24
                        radius: 4
                        color: isActive ? "#45475a" : (exists ? "#45475a" : "#313244")

                        Text {
                            anchors.centerIn: parent
                            text: root.workspaceIcons[modelData.toString()] || modelData.toString()
                            color: isActive ? "#89b4fa" : (exists ? "#cdd6f4" : "#6c7086")
                            font.pixelSize: 14
                            font.family: "Symbols Nerd Font"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: I3.dispatch("workspace number " + modelData)
                        }
                    }
                }
            }

            // Center section - Clock
            Text {
                anchors.centerIn: parent
                text: Time.time
                color: "#cdd6f4"
                font.pixelSize: 14
                font.bold: true
            }

            // Right section
            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Volume
                Item {
                    id: volumeItem
                    width: volumeIcon.width
                    height: parent.height

                    Text {
                        id: volumeIcon
                        anchors.verticalCenter: parent.verticalCenter
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
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.volumePopupVisible = !root.volumePopupVisible
                        onWheel: (event) => {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, Pipewire.defaultAudioSink.audio.volume + delta))
                            }
                        }
                    }
                }

                Text {
                    text: "Bat"
                    color: "#cdd6f4"
                    font.pixelSize: 14
                }

                // Idle Inhibitor
                Text {
                    text: root.idleInhibited ? "󰈈" : "󰈉"
                    color: root.idleInhibited ? "#89b4fa" : "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"

                    MouseArea {
                        anchors.fill: parent
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

                // Power Menu
                Text {
                    text: "󰤄"
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: powerMenuProc.running = true
                    }
                }
            }

            // Volume Popup
            PopupWindow {
                id: volumePopup
                visible: root.volumePopupVisible

                anchor.item: volumeItem
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left

                implicitWidth: 280
                implicitHeight: popupContent.height + 16
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
                            font.pixelSize: 12
                            width: 32
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Current device display
                    Rectangle {
                        width: parent.width
                        height: 24
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
                                font.pixelSize: 12
                                font.family: "Symbols Nerd Font"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Pipewire.defaultAudioSink
                                    ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name || "Unknown")
                                    : "No device"
                                color: "#cdd6f4"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width - 50
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.deviceListExpanded ? "󰅃" : "󰅀"
                                color: "#6c7086"
                                font.pixelSize: 12
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

                    // Device list (shown when expanded)
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
                                height: 28
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
                                        font.pixelSize: 12
                                        font.family: "Symbols Nerd Font"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.description || modelData.name || "Unknown"
                                        color: isDefault ? "#cdd6f4" : "#a6adc8"
                                        font.pixelSize: 11
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
                }
            }
        }
    }
}
