import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../core/components"

Rectangle {
  id: switcher
  anchors.fill: parent
  color: Colors.base
  radius: 8

  signal closeRequested()

  // Confirmation state for deletion
  property string confirmDeleteDir: ""

  // Confirmation state for reset
  property bool confirmReset: false

  // Reset confirmation when this component is shown
  Component.onCompleted: {
    confirmDeleteDir = ""
    confirmReset = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {} // absorb clicks
  }

  // Border
  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: Colors.surface2
    radius: parent.radius
    z: 100
  }

  Column {
    anchors.fill: parent
    anchors.margins: 24
    spacing: 16

    Text {
      text: "Switch Profile"
      color: Colors.text
      font.pixelSize: 20
      font.bold: true
    }

    // Profile list
    Column {
      width: parent.width
      spacing: 4

      Repeater {
        model: GeneralSettings.profiles

        Rectangle {
          required property var modelData
          required property int index

          width: parent.width
          height: 44
          radius: 6
          color: {
            if (modelData.dir === GeneralSettings.activeProfile) return Colors.surface0
            if (profileHover.containsMouse) return Colors.surface0
            return "transparent"
          }

          Row {
            anchors.left: parent.left
            anchors.right: deleteArea.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Active indicator
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: ""
              color: Colors.blue
              font.pixelSize: 14
              font.family: "Symbols Nerd Font"
              visible: modelData.dir === GeneralSettings.activeProfile
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.name
              color: modelData.dir === GeneralSettings.activeProfile ? Colors.text : Colors.subtext0
              font.pixelSize: 14
            }
          }

          MouseArea {
            id: profileHover
            anchors.left: parent.left
            anchors.right: deleteArea.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (modelData.dir !== GeneralSettings.activeProfile) {
                GeneralSettings.switchProfile(modelData.dir)
                switcher.closeRequested()
              }
            }
          }

          // Delete button (not for first profile / not for active profile)
          Item {
            id: deleteArea
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: (index > 0 && modelData.dir !== GeneralSettings.activeProfile) ? 44 : 0
            visible: index > 0 && modelData.dir !== GeneralSettings.activeProfile

            Text {
              anchors.centerIn: parent
              text: switcher.confirmDeleteDir === modelData.dir ? "?" : "󰩺"
              color: {
                if (switcher.confirmDeleteDir === modelData.dir) return Colors.red
                if (deleteHover.containsMouse) return Colors.red
                return Colors.overlay0
              }
              font.pixelSize: switcher.confirmDeleteDir === modelData.dir ? 16 : 14
              font.family: switcher.confirmDeleteDir === modelData.dir ? undefined : "Symbols Nerd Font"
              font.bold: switcher.confirmDeleteDir === modelData.dir
            }

            MouseArea {
              id: deleteHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (switcher.confirmDeleteDir === modelData.dir) {
                  // Confirmed: delete
                  GeneralSettings.deleteProfile(modelData.dir)
                  switcher.confirmDeleteDir = ""
                } else {
                  // First click: ask for confirmation
                  switcher.confirmDeleteDir = modelData.dir
                  confirmTimer.restart()
                }
              }
            }
          }
        }
      }
    }

    // Reset to defaults button
    FocusButton {
      anchors.left: parent.left
      anchors.right: parent.right
      height: 32
      text: switcher.confirmReset ? "Are you sure?" : "Reset to defaults"
      fontSize: 12
      backgroundColor: Colors.red
      hoverColor: Qt.darker(Colors.red, 1.1)
      textColor: Colors.crust
      textHoverColor: Colors.crust
      onClicked: {
        if (switcher.confirmReset) {
          // Confirmed: reset active profile from repo defaults
          resetProc.running = true
        } else {
          // First click: ask for confirmation
          switcher.confirmReset = true
          resetTimer.restart()
        }
      }
    }

    // Close hint
    Text {
      text: "Click outside to close"
      color: Colors.overlay0
      font.pixelSize: 11
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }

  // Reset confirmation after 3 seconds
  Timer {
    id: confirmTimer
    interval: 3000
    onTriggered: switcher.confirmDeleteDir = ""
  }

  // Reset button confirmation timer
  Timer {
    id: resetTimer
    interval: 3000
    onTriggered: switcher.confirmReset = false
  }

  // Process to copy repo defaults into active profile
  Process {
    id: resetProc
    command: {
      var cmds = []
      var modules = ModuleRegistry.modules
      for (var i = 0; i < modules.length; i++) {
        var m = modules[i]
        var repoDefaults = m.path + "/defaults.json"
        var stateFile = DataManager.getStatePath(m.id)
        cmds.push("[ -f '" + repoDefaults + "' ] && cp '" + repoDefaults + "' '" + stateFile + "'")
      }
      return ["sh", "-c", cmds.join(" ; ") + " ; true"]
    }
    onExited: {
      switcher.confirmReset = false
      switcher.closeRequested()
    }
  }
}
