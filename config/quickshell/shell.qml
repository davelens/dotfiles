import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

Scope {
  id: root

  SettingsPanel {}
  // Floating notifications top-right
  NotificationPopups {}
  // Notifications history panel slide-in
  NotificationPanel {}

  // Module popups (PanelWindow-based, with click-outside and ESC support)
  VolumePopup {}
  BrightnessPopup {}
  DisplayPopup {}
  BluetoothPopup {}
  WirelessPopup {}

  // Pipewire tracking
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  // Makes the statusbar only appear on primary screen
  Variants {
    model: DisplayConfig.primaryScreen && StatusbarManager.ready ? [DisplayConfig.primaryScreen] : []

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

      // Helper function to build props for dynamically loaded bar components.
      // Only pass singleton references to modules that need them to
      // avoid "non-existent property" warnings from Loader.setSource().
      function buildBarComponentProps(moduleId) {
        var props = { "screen": panel.modelData }
        var popupModules = ["volume", "brightness", "display", "bluetooth", "wireless"]
        if (popupModules.indexOf(moduleId) !== -1) {
          props.popupManager = PopupManager
        }
        if (moduleId === "notifications") {
          props.notificationManager = NotificationManager
        }
        return props
      }

      // Left section
      Row {
        anchors.left: parent.left
        anchors.leftMargin: StatusbarManager.barMargins.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: StatusbarManager.sectionSpacing.left

        Repeater {
          model: StatusbarManager.leftItems.filter(function(i) { return i.enabled })

          Row {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item { width: modelData.marginLeft; height: 1 }

            Loader {
              id: loader
              anchors.verticalCenter: parent.verticalCenter

              Component.onCompleted: {
                var url = ModuleRegistry.getBarComponentUrl(modelData.id)
                if (url) {
                  setSource(url, panel.buildBarComponentProps(modelData.id))
                }
              }
            }

            Item { width: modelData.marginRight; height: 1 }
          }
        }
      }

      // Center section
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: StatusbarManager.sectionSpacing.center

        Repeater {
          model: StatusbarManager.centerItems.filter(function(i) { return i.enabled })

          Row {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item { width: modelData.marginLeft; height: 1 }

            Loader {
              id: loader
              anchors.verticalCenter: parent.verticalCenter

              Component.onCompleted: {
                var url = ModuleRegistry.getBarComponentUrl(modelData.id)
                if (url) {
                  setSource(url, panel.buildBarComponentProps(modelData.id))
                }
              }
            }

            Item { width: modelData.marginRight; height: 1 }
          }
        }
      }

      // Right section
      Row {
        anchors.right: parent.right
        anchors.rightMargin: StatusbarManager.barMargins.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: StatusbarManager.sectionSpacing.right

        Repeater {
          model: StatusbarManager.rightItems.filter(function(i) { return i.enabled })

          Row {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item { width: modelData.marginLeft; height: 1 }

            Loader {
              id: loader
              anchors.verticalCenter: parent.verticalCenter

              Component.onCompleted: {
                var url = ModuleRegistry.getBarComponentUrl(modelData.id)
                if (url) {
                  setSource(url, panel.buildBarComponentProps(modelData.id))
                }
              }
            }

            Item { width: modelData.marginRight; height: 1 }
          }
        }
      }
    }
  }
}
