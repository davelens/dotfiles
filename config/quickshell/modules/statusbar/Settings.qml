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

  // Highlight matching text with yellow background
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

  // Get module info for an item
  function getModuleInfo(id) {
    return ModuleRegistry.getModule(id) || { name: id, icon: "?" }
  }

  Column {
    width: parent.width
    spacing: 24

    // Header
    Row {
      spacing: 16

      Text {
        text: "Status Bar"
        color: Colors.text
        font.pixelSize: 24
        font.bold: true
      }

      FocusButton {
        anchors.verticalCenter: parent.verticalCenter
        text: "Reset to Defaults"
        width: 140
        height: 32
        backgroundColor: Colors.surface1
        hoverColor: Colors.surface2
        onClicked: StatusbarManager.resetToDefaults()
      }
    }

    // Bar margins section
    Column {
      width: parent.width
      spacing: 8

      Text {
        text: settingsRoot.highlightText("Bar Margins", settingsRoot.searchQuery)
        textFormat: Text.RichText
        color: Colors.subtext0
        font.pixelSize: 14
      }

      Row {
        width: parent.width
        spacing: 24

        // Left margin
        Row {
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Left:"
            color: Colors.text
            font.pixelSize: 13
          }

          SpinBox {
            id: leftMarginSpin
            from: 0
            to: 100
            value: StatusbarManager.barMargins.left
            editable: true
            width: 80

            onValueModified: {
              StatusbarManager.setBarMargins(value, StatusbarManager.barMargins.right)
            }

            background: Rectangle {
              color: Colors.surface0
              radius: 4
            }

            contentItem: TextInput {
              z: 2
              text: leftMarginSpin.textFromValue(leftMarginSpin.value, leftMarginSpin.locale)
              color: Colors.text
              font.pixelSize: 13
              horizontalAlignment: Qt.AlignHCenter
              verticalAlignment: Qt.AlignVCenter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: 24
              anchors.rightMargin: 24
              readOnly: !leftMarginSpin.editable
              validator: leftMarginSpin.validator
              inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            up.indicator: Rectangle {
              x: parent.width - width
              height: parent.height
              width: 24
              color: leftMarginSpin.up.pressed ? Colors.surface2 : Colors.surface1
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
              color: leftMarginSpin.down.pressed ? Colors.surface2 : Colors.surface1
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

        // Right margin
        Row {
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Right:"
            color: Colors.text
            font.pixelSize: 13
          }

          SpinBox {
            id: rightMarginSpin
            from: 0
            to: 100
            value: StatusbarManager.barMargins.right
            editable: true
            width: 80

            onValueModified: {
              StatusbarManager.setBarMargins(StatusbarManager.barMargins.left, value)
            }

            background: Rectangle {
              color: Colors.surface0
              radius: 4
            }

            contentItem: TextInput {
              z: 2
              text: rightMarginSpin.textFromValue(rightMarginSpin.value, rightMarginSpin.locale)
              color: Colors.text
              font.pixelSize: 13
              horizontalAlignment: Qt.AlignHCenter
              verticalAlignment: Qt.AlignVCenter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: 24
              anchors.rightMargin: 24
              readOnly: !rightMarginSpin.editable
              validator: rightMarginSpin.validator
              inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            up.indicator: Rectangle {
              x: parent.width - width
              height: parent.height
              width: 24
              color: rightMarginSpin.up.pressed ? Colors.surface2 : Colors.surface1
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
              color: rightMarginSpin.down.pressed ? Colors.surface2 : Colors.surface1
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

    // Separator
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
    }

    // Left section
    Column {
      width: parent.width
      spacing: 8

      Text {
        text: settingsRoot.highlightText("Left Section", settingsRoot.searchQuery)
        textFormat: Text.RichText
        color: Colors.subtext0
        font.pixelSize: 14
      }

      Column {
        width: parent.width
        spacing: 4

        Repeater {
          model: StatusbarManager.leftItems

          StatusbarItemRow {
            required property var modelData
            required property int index
            item: modelData
            itemIndex: index
            section: "left"
            totalItems: StatusbarManager.leftItems.length
          }
        }

        Text {
          text: "No items in left section"
          color: Colors.overlay0
          font.pixelSize: 13
          visible: StatusbarManager.leftItems.length === 0
        }
      }
    }

    // Separator
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
    }

    // Center section
    Column {
      width: parent.width
      spacing: 8

      Text {
        text: settingsRoot.highlightText("Center Section", settingsRoot.searchQuery)
        textFormat: Text.RichText
        color: Colors.subtext0
        font.pixelSize: 14
      }

      Column {
        width: parent.width
        spacing: 4

        Repeater {
          model: StatusbarManager.centerItems

          StatusbarItemRow {
            required property var modelData
            required property int index
            item: modelData
            itemIndex: index
            section: "center"
            totalItems: StatusbarManager.centerItems.length
          }
        }

        Text {
          text: "No items in center section"
          color: Colors.overlay0
          font.pixelSize: 13
          visible: StatusbarManager.centerItems.length === 0
        }
      }
    }

    // Separator
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
    }

    // Right section
    Column {
      width: parent.width
      spacing: 8

      Text {
        text: settingsRoot.highlightText("Right Section", settingsRoot.searchQuery)
        textFormat: Text.RichText
        color: Colors.subtext0
        font.pixelSize: 14
      }

      Column {
        width: parent.width
        spacing: 4

        Repeater {
          model: StatusbarManager.rightItems

          StatusbarItemRow {
            required property var modelData
            required property int index
            item: modelData
            itemIndex: index
            section: "right"
            totalItems: StatusbarManager.rightItems.length
          }
        }

        Text {
          text: "No items in right section"
          color: Colors.overlay0
          font.pixelSize: 13
          visible: StatusbarManager.rightItems.length === 0
        }
      }
    }
  }

  // Reusable item row component
  component StatusbarItemRow: Rectangle {
    id: itemRow
    property var item
    property int itemIndex
    property string section
    property int totalItems

    width: parent.width
    height: 56
    radius: 6
    color: item.enabled ? Colors.surface0 : Colors.mantle

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      // Module icon
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
          var mod = ModuleRegistry.getModule(item.id)
          return mod ? mod.icon : "?"
        }
        color: item.enabled ? Colors.blue : Colors.overlay0
        font.pixelSize: 18
        font.family: "Symbols Nerd Font"
        width: 24
        horizontalAlignment: Text.AlignHCenter
      }

      // Module name
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
          var mod = ModuleRegistry.getModule(item.id)
          return mod ? mod.name : item.id
        }
        color: item.enabled ? Colors.text : Colors.overlay0
        font.pixelSize: 14
        width: 120
      }

      // Move up button
      FocusIconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰁝"
        iconColor: itemIndex === 0 ? Colors.surface2 : Colors.overlay0
        hoverColor: Colors.blue
        visible: itemIndex > 0
        onClicked: StatusbarManager.moveUp(item.id)
      }

      // Placeholder when move up not visible
      Item {
        width: 22
        height: 22
        visible: itemIndex === 0
      }

      // Move down button
      FocusIconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰁅"
        iconColor: itemIndex >= totalItems - 1 ? Colors.surface2 : Colors.overlay0
        hoverColor: Colors.blue
        visible: itemIndex < totalItems - 1
        onClicked: StatusbarManager.moveDown(item.id)
      }

      // Placeholder when move down not visible
      Item {
        width: 22
        height: 22
        visible: itemIndex >= totalItems - 1
      }

      // Section dropdown
      Dropdown {
        anchors.verticalCenter: parent.verticalCenter
        width: 90
        compact: true
        items: ["left", "center", "right"]
        currentItem: section
        onItemSelected: selectedSection => {
          if (selectedSection !== section) {
            StatusbarManager.moveToSection(item.id, selectedSection)
          }
          expanded = false
        }
      }

      // Margin inputs
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "L:"
          color: Colors.overlay0
          font.pixelSize: 11
        }

        Rectangle {
          width: 40
          height: 24
          radius: 4
          color: Colors.surface1
          border.width: leftMarginInput.activeFocus ? 2 : 0
          border.color: Colors.peach

          TextInput {
            id: leftMarginInput
            anchors.fill: parent
            anchors.margins: 4
            text: item.marginLeft
            color: Colors.text
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            activeFocusOnTab: true
            validator: IntValidator { bottom: 0; top: 100 }
            onEditingFinished: {
              StatusbarManager.setMargins(item.id, parseInt(text) || 0, item.marginRight)
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "R:"
          color: Colors.overlay0
          font.pixelSize: 11
        }

        Rectangle {
          width: 40
          height: 24
          radius: 4
          color: Colors.surface1
          border.width: rightMarginInput.activeFocus ? 2 : 0
          border.color: Colors.peach

          TextInput {
            id: rightMarginInput
            anchors.fill: parent
            anchors.margins: 4
            text: item.marginRight
            color: Colors.text
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            activeFocusOnTab: true
            validator: IntValidator { bottom: 0; top: 100 }
            onEditingFinished: {
              StatusbarManager.setMargins(item.id, item.marginLeft, parseInt(text) || 0)
            }
          }
        }
      }
    }

    // Enable toggle on the right
    SwitchToggle {
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      checked: item.enabled
      onClicked: StatusbarManager.toggleItem(item.id)
    }
  }
}
