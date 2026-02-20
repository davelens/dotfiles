import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

import "modules" as Modules

Scope {
  id: root

  // SETTINGS PANEL
  SettingsPanel {}

  // NOTIFICATION POPUPS (floating notifications top-right)
  NotificationPopups {}

  // NOTIFICATION PANEL (history slide-in)
  NotificationPanel {}

  // PIPEWIRE TRACKING
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  // CLICK-OUTSIDE OVERLAY
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: PopupManager.activePopup !== ""

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
        onClicked: PopupManager.close()
      }
    }
  }

  // BAR (only on primary screen)
  Variants {
    model: DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

    PanelWindow {
      required property var modelData

      id: panel
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

      // LEFT SECTION
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Modules.PowerButton {}
        Modules.IdleInhibitorButton {}
        Modules.Workspaces {}
      }

      // CENTER SECTION
      Modules.MediaButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        screen: panel.modelData
      }

      // RIGHT SECTION
      Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        // Hardware controls group
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Modules.WirelessButton { screen: panel.modelData }
          Modules.BluetoothButton { screen: panel.modelData }
          Modules.DisplayButton { screen: panel.modelData }
          Modules.BrightnessButton { screen: panel.modelData }
          Modules.VolumeButton { screen: panel.modelData }
        }

        Modules.Battery {}
        Modules.Clock {}
        Modules.NotificationButton { screen: panel.modelData }
      }
    }
  }
}
