import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../core/components"

DialogOverlay {
  id: switcher
  title: "Switch Profile"

  // Confirmation state for deletion
  property string confirmDeleteDir: ""

  // Confirmation state for reset
  property bool confirmReset: false

  // Reset confirmation when this component is shown
  Component.onCompleted: {
    confirmDeleteDir = ""
    confirmReset = false
  }

  // Profile list
  Column {
    width: parent.width
    spacing: 4

    Repeater {
      model: GeneralSettings.profiles

      Row {
        width: parent.width
        spacing: 0

        // Profile row (focusable)
        Rectangle {
          id: profileRow
          required property var modelData
          required property int index

          width: parent.width - (deleteBtn.visible ? deleteBtn.width : 0)
          height: 44
          radius: 6
          activeFocusOnTab: true
          color: {
            if (modelData.dir === GeneralSettings.activeProfile) return Colors.surface0
            if (activeFocus || profileHover.containsMouse) return Colors.surface0
            return "transparent"
          }

          // Focus ring
          Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: Colors.peach
            visible: profileRow.activeFocus
          }

          Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Active indicator
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: ""
              color: Colors.blue
              font.pixelSize: 14
              font.family: "Symbols Nerd Font"
              visible: profileRow.modelData.dir === GeneralSettings.activeProfile
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: profileRow.modelData.name
              color: profileRow.modelData.dir === GeneralSettings.activeProfile ? Colors.text : Colors.subtext0
              font.pixelSize: 14
            }
          }

          MouseArea {
            id: profileHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (profileRow.modelData.dir !== GeneralSettings.activeProfile) {
                GeneralSettings.switchProfile(profileRow.modelData.dir)
              }
            }
          }

          Keys.onReturnPressed: {
            if (modelData.dir !== GeneralSettings.activeProfile) {
              GeneralSettings.switchProfile(modelData.dir)
            }
          }
          Keys.onSpacePressed: {
            if (modelData.dir !== GeneralSettings.activeProfile) {
              GeneralSettings.switchProfile(modelData.dir)
            }
          }
        }

        // Delete button (not for first profile / not for active profile)
        Item {
          id: deleteBtn
          width: visible ? 44 : 0
          height: 44
          visible: profileRow.index > 0 && profileRow.modelData.dir !== GeneralSettings.activeProfile
          activeFocusOnTab: visible

          // Focus ring
          Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 16
            color: "transparent"
            border.width: 2
            border.color: Colors.peach
            visible: deleteBtn.activeFocus
          }

          Text {
            anchors.centerIn: parent
            text: switcher.confirmDeleteDir === profileRow.modelData.dir ? "?" : "󰩺"
            color: {
              if (switcher.confirmDeleteDir === profileRow.modelData.dir) return Colors.red
              if (deleteBtn.activeFocus || deleteHover.containsMouse) return Colors.red
              return Colors.overlay0
            }
            font.pixelSize: switcher.confirmDeleteDir === profileRow.modelData.dir ? 16 : 14
            font.family: switcher.confirmDeleteDir === profileRow.modelData.dir ? undefined : "Symbols Nerd Font"
            font.bold: switcher.confirmDeleteDir === profileRow.modelData.dir
          }

          MouseArea {
            id: deleteHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (switcher.confirmDeleteDir === profileRow.modelData.dir) {
                GeneralSettings.deleteProfile(profileRow.modelData.dir)
                switcher.confirmDeleteDir = ""
              } else {
                switcher.confirmDeleteDir = profileRow.modelData.dir
                confirmTimer.restart()
              }
            }
          }

          Keys.onReturnPressed: deleteHover.clicked(null)
          Keys.onSpacePressed: deleteHover.clicked(null)
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
    }
  }
}
