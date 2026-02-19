import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import ".."

BarButton {
    id: button

    // Required: screen for popup management
    required property var screen

    property var sink: Pipewire.defaultAudioSink
    property real volume: sink && sink.audio ? sink.audio.volume : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false

    icon: getVolumeIcon(volume, muted)
    iconSize: 24
    iconColor: muted ? Colors.overlay0 : Colors.text

    function getVolumeIcon(volume, muted) {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.25) return "󰕿"
        if (volume < 0.50) return "󰖀"
        return "󰕾"
    }

    onClicked: PopupManager.toggle("volume", screen)

    onWheel: event => {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, Pipewire.defaultAudioSink.audio.volume + delta))
        }
    }

    // Audio device lists
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

    PopupWindow {
        id: popup

        visible: PopupManager.isOpen("volume", button.screen)

        anchor.item: button
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -8

        implicitWidth: 320
        implicitHeight: {
            var h = 32 + 8 + 28 + 8 + 1 + 8 + 28
            if (PopupManager.outputDevicesExpanded) h += button.audioSinks.length * 34 + button.audioSinks.length * 2
            if (PopupManager.inputDevicesExpanded) h += button.audioSources.length * 34 + button.audioSources.length * 2
            return h + 48
        }
        color: Colors.base

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 8

            // Volume slider
            Row {
                width: parent.width
                height: 32
                spacing: 8

                property var sink: Pipewire.defaultAudioSink
                property real volume: sink && sink.audio ? sink.audio.volume : 0
                property bool muted: sink && sink.audio ? sink.audio.muted : false

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.muted ? "󰝟" : "󰕾"
                    color: parent.muted ? Colors.red : Colors.text
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

                Slider {
                    id: volumeSlider
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 18 - 44 - 16
                    height: 20
                    from: 0
                    to: 1
                    value: parent.volume
                    onMoved: {
                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                            Pipewire.defaultAudioSink.audio.volume = value
                        }
                    }

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 8
                        width: volumeSlider.availableWidth
                        height: 8
                        radius: 4
                        color: Colors.surface0

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: Colors.blue
                            radius: 4
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.text
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(parent.volume * 100) + "%"
                    color: Colors.blue
                    font.pixelSize: 14
                    width: 44
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Output devices
            Dropdown {
                width: parent.width
                items: button.audioSinks
                currentItem: Pipewire.defaultAudioSink
                headerIcon: "󰓃"
                headerLabel: "Output"
                textRole: "description"
                valueRole: "id"
                expanded: PopupManager.outputDevicesExpanded
                onToggled: expanded => PopupManager.outputDevicesExpanded = expanded
                onItemSelected: item => Pipewire.preferredDefaultAudioSink = item
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surface1
            }

            // Input devices
            Dropdown {
                width: parent.width
                items: button.audioSources
                currentItem: Pipewire.defaultAudioSource
                headerIcon: "󰍬"
                headerLabel: "Input"
                textRole: "description"
                valueRole: "id"
                expanded: PopupManager.inputDevicesExpanded
                onToggled: expanded => PopupManager.inputDevicesExpanded = expanded
                onItemSelected: item => Pipewire.preferredDefaultAudioSource = item
            }
        }
    }
}
