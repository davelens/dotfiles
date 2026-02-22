import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Item {
  id: settingsRoot
  anchors.fill: parent

  // Search query passed from SettingsPanel
  property string searchQuery: ""

  // Drag state
  property string draggedItemId: ""
  property string draggedFromSection: ""
  property bool isDragging: false
  property string dropSection: ""
  property int dropIndex: -1
  property real dragMouseY: 0
  property string draggedItemName: ""
  property string draggedItemIcon: ""

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

  function startDrag(itemId, fromSection) {
    draggedItemId = itemId
    draggedFromSection = fromSection
    isDragging = true
    dropSection = ""
    dropIndex = -1
    var mod = ModuleRegistry.getModule(itemId)
    draggedItemName = mod ? mod.name : itemId
    draggedItemIcon = mod ? mod.icon : "?"
  }

  function endDrag() {
    if (draggedItemId && dropSection && dropIndex >= 0) {
      StatusbarManager.moveItem(draggedItemId, dropSection, dropIndex)
    }
    draggedItemId = ""
    draggedFromSection = ""
    isDragging = false
    dropSection = ""
    dropIndex = -1
    dragMouseY = 0
    draggedItemName = ""
    draggedItemIcon = ""
  }

  // Resolve drop target from global mouse Y within the scroll content
  function resolveDropTarget(globalMouseY) {
    // Map mouse position to scroll content coordinates
    var contentY = globalMouseY + scrollView.contentItem.contentY

    // Check each section
    var sections = [
      { name: "left", col: leftSection, items: StatusbarManager.leftItems },
      { name: "center", col: centerSection, items: StatusbarManager.centerItems },
      { name: "right", col: rightSection, items: StatusbarManager.rightItems }
    ]

    for (var s = 0; s < sections.length; s++) {
      var sec = sections[s]
      var colPos = sec.col.mapToItem(scrollContent, 0, 0)
      var colTop = colPos.y
      var colBottom = colTop + sec.col.height

      if (contentY >= colTop && contentY <= colBottom) {
        if (sec.items.length === 0) {
          dropSection = sec.name
          dropIndex = 0
          return
        }

        // Find which row we're over.
        // children[1] is the items Column (children[0] is the section label text).
        // Inside that Column, children[0] is the Repeater, so delegates start at [1].
        var itemsCol = sec.col.children[1]
        if (!itemsCol) continue

        for (var i = 0; i < sec.items.length; i++) {
          var rowWrapper = itemsCol.children[i + 1]
          if (!rowWrapper) continue

          var rowPos = rowWrapper.mapToItem(scrollContent, 0, 0)
          var rowMid = rowPos.y + rowWrapper.height / 2

          if (contentY < rowMid) {
            dropSection = sec.name
            dropIndex = i
            return
          }
        }

        // Below all items in this section
        dropSection = sec.name
        dropIndex = sec.items.length
        return
      }
    }
  }

  // Ghost row that follows the cursor during drag
  Rectangle {
    id: dragGhost
    visible: settingsRoot.isDragging
    z: 200
    x: 12
    y: settingsRoot.dragMouseY - height / 2
    width: settingsRoot.width - 24
    height: 48
    radius: 6
    color: Colors.surface0
    opacity: 0.85
    border.width: 1
    border.color: Colors.blue

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: settingsRoot.draggedItemIcon
        color: Colors.blue
        font.pixelSize: 18
        font.family: "Symbols Nerd Font"
        width: 24
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: settingsRoot.draggedItemName
        color: Colors.text
        font.pixelSize: 14
      }
    }
  }

  ScrollView {
    id: scrollView
    anchors.fill: parent
    clip: true
    contentWidth: availableWidth

    // Disable scroll interaction during drag to prevent it from stealing events
    Binding {
      target: scrollView.contentItem
      property: "interactive"
      value: false
      when: settingsRoot.isDragging
      restoreMode: Binding.RestoreBindingOrValue
    }

    Column {
      id: scrollContent
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

      // Bar margins
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

      Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

      // Left section
      Column {
        id: leftSection
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
          spacing: 0

          Repeater {
            model: StatusbarManager.leftItems

            ItemRowWrapper {
              required property var modelData
              required property int index
              item: modelData
              itemIndex: index
              section: "left"
              sectionItems: StatusbarManager.leftItems
            }
          }
        }

        EmptyDropZone { sectionName: "left"; sectionItems: StatusbarManager.leftItems }
      }

      Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

      // Center section
      Column {
        id: centerSection
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
          spacing: 0

          Repeater {
            model: StatusbarManager.centerItems

            ItemRowWrapper {
              required property var modelData
              required property int index
              item: modelData
              itemIndex: index
              section: "center"
              sectionItems: StatusbarManager.centerItems
            }
          }
        }

        EmptyDropZone { sectionName: "center"; sectionItems: StatusbarManager.centerItems }
      }

      Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

      // Right section
      Column {
        id: rightSection
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
          spacing: 0

          Repeater {
            model: StatusbarManager.rightItems

            ItemRowWrapper {
              required property var modelData
              required property int index
              item: modelData
              itemIndex: index
              section: "right"
              sectionItems: StatusbarManager.rightItems
            }
          }
        }

        EmptyDropZone { sectionName: "right"; sectionItems: StatusbarManager.rightItems }
      }
    }
  }

  // Empty section drop zone
  component EmptyDropZone: Item {
    property string sectionName
    property var sectionItems

    width: parent.width
    height: visible ? 56 : 0
    visible: sectionItems.length === 0

    Rectangle {
      anchors.fill: parent
      radius: 6
      color: "transparent"
      border.width: 2
      border.color: settingsRoot.isDragging && settingsRoot.dropSection === sectionName
                      ? Colors.blue : Colors.surface2
      visible: settingsRoot.isDragging
    }

    Text {
      anchors.centerIn: parent
      text: settingsRoot.isDragging ? "Drop here" : ("No items in " + sectionName + " section")
      color: Colors.overlay0
      font.pixelSize: 13
    }
  }

  // Wrapper around each item row that includes the drop indicator
  component ItemRowWrapper: Column {
    id: wrapper
    property var item
    property int itemIndex
    property string section
    property var sectionItems

    width: parent.width

    // Drop indicator above this row
    Rectangle {
      width: parent.width
      height: 3
      radius: 2
      color: Colors.blue
      visible: settingsRoot.isDragging
                && settingsRoot.dropSection === wrapper.section
                && settingsRoot.dropIndex === wrapper.itemIndex
                && settingsRoot.draggedItemId !== wrapper.item.id
    }

    Item { width: 1; height: 4 }

    StatusbarItemRow {
      item: wrapper.item
      itemIndex: wrapper.itemIndex
      section: wrapper.section
    }

    // Drop indicator after last item
    Rectangle {
      width: parent.width
      height: 3
      radius: 2
      color: Colors.blue
      visible: settingsRoot.isDragging
                && settingsRoot.dropSection === wrapper.section
                && settingsRoot.dropIndex === wrapper.itemIndex + 1
                && wrapper.itemIndex === wrapper.sectionItems.length - 1
                && settingsRoot.draggedItemId !== wrapper.item.id
    }
  }

  // Item row
  component StatusbarItemRow: Rectangle {
    id: itemRow
    property var item
    property int itemIndex
    property string section

    width: parent.width
    height: 56
    radius: 6
    color: item.enabled ? Colors.surface0 : Colors.mantle
    opacity: settingsRoot.draggedItemId === item.id ? 0.3 : 1.0

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      // Drag handle
      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 32

        Text {
          anchors.centerIn: parent
          text: "󰇙"
          color: dragArea.pressed ? Colors.blue : (dragArea.containsMouse ? Colors.text : Colors.overlay0)
          font.pixelSize: 16
          font.family: "Symbols Nerd Font"
        }

        MouseArea {
          id: dragArea
          anchors.fill: parent
          hoverEnabled: true
          preventStealing: true
          cursorShape: settingsRoot.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

          onPressed: mouse => {
            settingsRoot.startDrag(item.id, section)
            var mapped = mapToItem(settingsRoot, mouse.x, mouse.y)
            settingsRoot.dragMouseY = mapped.y
            settingsRoot.resolveDropTarget(mapped.y)
          }

          onPositionChanged: mouse => {
            if (!settingsRoot.isDragging) return
            var mapped = mapToItem(settingsRoot, mouse.x, mouse.y)
            settingsRoot.dragMouseY = mapped.y
            settingsRoot.resolveDropTarget(mapped.y)
          }

          onReleased: {
            settingsRoot.endDrag()
          }
        }
      }

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
            selectByMouse: true
            validator: IntValidator { bottom: 0; top: 100 }
            onActiveFocusChanged: if (activeFocus) selectAll()
            onEditingFinished: {
              StatusbarManager.setMargins(item.id, parseInt(text) || 0, item.marginRight)
            }
            Keys.onReturnPressed: focus = false
            Keys.onEnterPressed: focus = false
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
            selectByMouse: true
            validator: IntValidator { bottom: 0; top: 100 }
            onActiveFocusChanged: if (activeFocus) selectAll()
            onEditingFinished: {
              StatusbarManager.setMargins(item.id, item.marginLeft, parseInt(text) || 0)
            }
            Keys.onReturnPressed: focus = false
            Keys.onEnterPressed: focus = false
          }
        }
      }
    }

    // Enable toggle
    SwitchToggle {
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      checked: item.enabled
      onClicked: StatusbarManager.toggleItem(item.id)
    }
  }
}
