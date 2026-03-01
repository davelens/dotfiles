import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  id: volumePopup

  model: PopupManager.isOpen("volume") && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  // Dropdown expansion state (local to this popup)
  property bool outputDevicesExpanded: false
  property bool inputDevicesExpanded: false

  // Reset dropdown state when popup closes
  Connections {
    target: PopupManager
    function onActivePopupChanged() {
      if (PopupManager.activePopup !== "volume") {
        volumePopup.outputDevicesExpanded = false
        volumePopup.inputDevicesExpanded = false
      }
    }
  }

  property var sink: Pipewire.defaultAudioSink
  property real volume: sink && sink.audio ? sink.audio.volume : 0
  property bool muted: sink && sink.audio ? sink.audio.muted : false

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

  PopupBase {
    popupWidth: 360

    // Volume slider
    Row {
      width: parent.width
      height: 32
      spacing: 8

      property var sink: Pipewire.defaultAudioSink
      property real volume: sink && sink.audio ? sink.audio.volume : 0
      property bool muted: sink && sink.audio ? sink.audio.muted : false

      FocusIconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: parent.muted ? "󰝟" : "󰕾"
        iconColor: parent.muted ? Colors.red : Colors.text
        hoverColor: parent.muted ? Colors.red : Colors.blue
        iconSize: 20
        onClicked: {
          if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
          }
        }
      }

      FocusSlider {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 28 - 44 - 16
        height: 20
        from: 0
        to: 1
        stepSize: 0.02
        value: parent.volume
        accentColor: Colors.blue
        trackColor: Colors.surface0
        trackHeight: 8
        handleSize: 14
        onMoved: {
          if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = value
          }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(parent.volume * 100) + "%"
        color: Colors.blue
        font.pixelSize: 16
        width: 44
        horizontalAlignment: Text.AlignRight
      }
    }

    // Output devices
    Dropdown {
      width: parent.width
      items: volumePopup.audioSinks
      currentItem: Pipewire.defaultAudioSink
      headerIcon: "󰓃"
      headerLabel: "Output"
      textRole: "description"
      valueRole: "id"
      expanded: volumePopup.outputDevicesExpanded
      onToggled: expanded => volumePopup.outputDevicesExpanded = expanded
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
      items: volumePopup.audioSources
      currentItem: Pipewire.defaultAudioSource
      headerIcon: "󰍬"
      headerLabel: "Input"
      textRole: "description"
      valueRole: "id"
      expanded: volumePopup.inputDevicesExpanded
      onToggled: expanded => volumePopup.inputDevicesExpanded = expanded
      onItemSelected: item => Pipewire.preferredDefaultAudioSource = item
    }
  }
}
