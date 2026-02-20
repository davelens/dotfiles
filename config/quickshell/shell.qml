import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

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

      // Helper function to build props for dynamically loaded bar components
      function buildBarComponentProps(moduleId) {
        var props = {
          "screen": panel.modelData,
          "popupManager": PopupManager  // Pass to all components for singleton consistency
        }
        // Pass additional singleton references for modules that need them
        if (moduleId === "notifications") {
          props.notificationManager = NotificationManager
        }
        return props
      }

      // LEFT SECTION
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

      // CENTER SECTION
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

      // RIGHT SECTION
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
