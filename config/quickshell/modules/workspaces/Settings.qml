import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

ScrollView {
  id: settingsRoot
  anchors.fill: parent
  clip: true
  contentWidth: availableWidth

  // Search query passed from SettingsPanel
  property string searchQuery: ""

  function highlightText(text, query) {
    if (!query) return text
    var lowerText = text.toLowerCase()
    var lowerQuery = query.toLowerCase()
    var idx = lowerText.indexOf(lowerQuery)
    if (idx === -1) return text
    var before = text.substring(0, idx)
    var match = text.substring(idx, idx + query.length)
    var after = text.substring(idx + query.length)
    return before + '<span style="background-color: ' + Colors.yellow + '; color: ' + Colors.crust + ';">' + match + '</span>' + after
  }

  Column {
    width: parent.width
    spacing: 20

    Text {
      text: "Workspaces"
      color: Colors.text
      font.pixelSize: 24
      font.bold: true
    }

    // Backend
    TitleText {
      text: settingsRoot.highlightText("Backend", settingsRoot.searchQuery)
      textFormat: Text.RichText
    }

    Rectangle {
      width: parent.width
      height: backendColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: backendColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        HelpText {
          width: parent.width
          text: "Which compositor backend to use for reading workspace state. Auto-detect checks for Sway/i3 first, then Niri."
            + (WorkspacesManager.backend === "auto"
              ? " Currently detected: <b>" + WorkspacesManager.resolvedBackend + "</b>."
              : "")
          textFormat: Text.RichText
          wrapMode: Text.WordWrap
        }

        Dropdown {
          width: parent.width
          headerLabel: "Compositor"
          items: ["auto", "sway", "niri"]
          currentItem: WorkspacesManager.backend
          onItemSelected: function(item) {
            WorkspacesManager.setBackend(item)
            expanded = false
          }
        }
      }
    }

    // Detection
    TitleText {
      text: settingsRoot.highlightText("Detection", settingsRoot.searchQuery)
      textFormat: Text.RichText
    }

    Rectangle {
      width: parent.width
      height: detectionColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: detectionColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        HelpText {
          width: parent.width
          text: "Automatically show only workspaces that currently exist in the compositor. When disabled, a fixed number of workspace slots are shown."
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: 12

          SwitchToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: WorkspacesManager.autoDetect
            onClicked: WorkspacesManager.setAutoDetect(!WorkspacesManager.autoDetect)
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Detect active workspaces"
            color: Colors.text
            font.pixelSize: 14
          }
        }
      }
    }

    // Display mode
    TitleText {
      text: settingsRoot.highlightText("Display Mode", settingsRoot.searchQuery)
      textFormat: Text.RichText
    }

    Rectangle {
      width: parent.width
      height: modeColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: modeColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        HelpText {
          width: parent.width
          text: "Choose how workspace indicators are displayed in the bar."
          wrapMode: Text.WordWrap
        }

        Dropdown {
          width: parent.width
          headerLabel: "Style"
          items: ["icons", "numbers", "dots"]
          currentItem: WorkspacesManager.displayMode
          onItemSelected: function(item) {
            WorkspacesManager.setDisplayMode(item)
            expanded = false
          }
        }
      }
    }

    // Workspace count
    TitleText {
      text: settingsRoot.highlightText("Workspace Count", settingsRoot.searchQuery)
      textFormat: Text.RichText
      opacity: WorkspacesManager.autoDetect ? 0.4 : 1.0
    }

    Rectangle {
      width: parent.width
      height: countColumn.height + 24
      radius: 8
      color: Colors.surface0
      opacity: WorkspacesManager.autoDetect ? 0.4 : 1.0

      Column {
        id: countColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        HelpText {
          width: parent.width
          text: WorkspacesManager.autoDetect
            ? "Workspace count is determined automatically by the compositor."
            : "Number of workspace slots shown in the bar."
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Count:"
            color: Colors.text
            font.pixelSize: 13
          }

          SpinBox {
            id: countSpin
            from: 1
            to: 10
            value: WorkspacesManager.count
            editable: !WorkspacesManager.autoDetect
            enabled: !WorkspacesManager.autoDetect
            width: 80

            onValueModified: {
              WorkspacesManager.setCount(value)
            }

            background: Rectangle {
              color: Colors.surface1
              radius: 4
            }

            contentItem: TextInput {
              z: 2
              text: countSpin.textFromValue(countSpin.value, countSpin.locale)
              color: Colors.text
              font.pixelSize: 13
              horizontalAlignment: Qt.AlignHCenter
              verticalAlignment: Qt.AlignVCenter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: 24
              anchors.rightMargin: 24
              readOnly: !countSpin.editable
              validator: countSpin.validator
              inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            up.indicator: Rectangle {
              x: parent.width - width
              height: parent.height
              width: 24
              color: countSpin.up.pressed ? Colors.surface2 : Colors.surface1
              radius: 4

              Text {
                anchors.centerIn: parent
                text: "+"
                color: Colors.text
                font.pixelSize: 14
              }
            }

            down.indicator: Rectangle {
              x: 0
              height: parent.height
              width: 24
              color: countSpin.down.pressed ? Colors.surface2 : Colors.surface1
              radius: 4

              Text {
                anchors.centerIn: parent
                text: "-"
                color: Colors.text
                font.pixelSize: 14
              }
            }
          }
        }
      }
    }

    // Icon mapping (only visible in icons mode)
    Column {
      width: parent.width
      spacing: 20
      visible: WorkspacesManager.displayMode === "icons"

      TitleText {
        text: settingsRoot.highlightText("Workspace Icons", settingsRoot.searchQuery)
        textFormat: Text.RichText
      }

      Rectangle {
        width: parent.width
        height: iconsColumn.height + 24
        radius: 8
        color: Colors.surface0

        Column {
          id: iconsColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          spacing: 8

          HelpText {
            width: parent.width
            text: "Paste a Nerd Font icon for each workspace. Leave empty to show the workspace number instead."
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: WorkspacesManager.count

            Row {
              required property int index
              spacing: 12

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Workspace " + (index + 1)
                color: Colors.text
                font.pixelSize: 13
                width: 100
              }

              Rectangle {
                width: 48
                height: 32
                radius: 6
                color: Colors.surface1
                border.width: iconInput.activeFocus ? 2 : 1
                border.color: iconInput.activeFocus ? Colors.peach : Colors.surface2

                TextInput {
                  id: iconInput
                  anchors.fill: parent
                  anchors.margins: 4
                  text: WorkspacesManager.icons[String(index + 1)] || ""
                  color: Colors.text
                  font.pixelSize: 18
                  font.family: "Symbols Nerd Font"
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  activeFocusOnTab: true
                  selectByMouse: true
                  onActiveFocusChanged: if (activeFocus) selectAll()
                  onEditingFinished: {
                    WorkspacesManager.setIcon(String(index + 1), text)
                  }
                  Keys.onReturnPressed: focus = false
                  Keys.onEnterPressed: focus = false
                }
              }

              // Preview of current icon
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  var icon = WorkspacesManager.icons[String(index + 1)]
                  return icon ? icon : String(index + 1)
                }
                color: Colors.overlay0
                font.pixelSize: 18
                font.family: "Symbols Nerd Font"
              }
            }
          }
        }
      }
    }
  }
}
