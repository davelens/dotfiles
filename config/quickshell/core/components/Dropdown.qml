import QtQuick
import QtQuick.Controls
import "../.."

// Reusable expandable dropdown component
// Can display any list of items with customizable display
// In compact mode, items appear as overlay; otherwise they flow in Column
Item {
  id: dropdown

  // Required properties
  required property var items           // Array of items to display

  // Optional properties
  property string headerIcon: ""        // Icon shown in header (required if not compact)
  property string headerLabel: ""       // Label shown in header (required if not compact)
  property var currentItem: null        // Currently selected item (for highlighting)
  property bool compact: false          // Compact mode: hides icon/label, just shows value + chevron
  property string textRole: ""          // Property name to use for display text (if items are objects)
  property string valueRole: ""         // Property name to use for comparison (if items are objects)
  property string itemIcon: ""          // Icon to show for each item (empty = use headerIcon)
  property string selectedIcon: "\uf00c" // Icon to show for selected item

  // Keyboard focus support (settings panel focus cycling)
  property bool showFocusRing: true
  property bool keyboardFocus: false
  property bool focused: activeFocus && showFocusRing && keyboardFocus
  focus: true
  activeFocusOnTab: true

  onActiveFocusChanged: {
    if (!activeFocus) keyboardFocus = false
  }

  // State
  property bool expanded: false
  property int highlightIndex: -1

  // Size: in compact mode, fixed to header size only; otherwise grows with content
  implicitWidth: compact ? width : contentColumn.width
  implicitHeight: compact ? 28 : contentColumn.height

  // Prevent child items from affecting size in compact mode
  clip: false

  // Signals
  signal itemSelected(var item)
  signal toggled(bool expanded)

  // Helper function to capitalize first letter
  function capitalize(str) {
    if (!str || typeof str !== "string") return str
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  // Helper function to get display text from an item
  function getItemText(item, shouldCapitalize) {
    if (!item) return "None"
    if (typeof item === "string") return shouldCapitalize ? capitalize(item) : item
    if (textRole && item[textRole]) return item[textRole]
    // Fallback: try common property names
    return item.description || item.name || item.text || item.label || String(item)
  }

  // Helper function to check if an item is selected
  function isItemSelected(item) {
    if (!currentItem || !item) return false
    if (valueRole) return item[valueRole] === currentItem[valueRole]
    if (typeof item === "string") return item === currentItem
    // Fallback: try common id properties
    if (item.id !== undefined && currentItem.id !== undefined) return item.id === currentItem.id
    return item === currentItem
  }

  // Keyboard navigation
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (expanded && highlightIndex >= 0 && highlightIndex < items.length) {
        // Select the highlighted item
        itemSelected(items[highlightIndex])
      } else {
        // Toggle expand/collapse
        expanded = !expanded
        highlightIndex = -1
        toggled(expanded)
      }
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      if (expanded) {
        expanded = false
        highlightIndex = -1
        toggled(false)
        event.accepted = true
      }
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
      if (expanded) {
        highlightIndex = (highlightIndex + 1) % items.length
        event.accepted = true
      }
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
      if (expanded) {
        highlightIndex = (highlightIndex - 1 + items.length) % items.length
        event.accepted = true
      }
    }
  }

  // Non-compact mode: Column layout where items flow below header
  Column {
    id: contentColumn
    spacing: 2
    visible: !dropdown.compact

    // Header (non-compact)
    Item {
      width: dropdown.width
      height: 28

      // Focus ring
      Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: 7
        color: "transparent"
        border.width: 2
        border.color: Colors.peach
        visible: dropdown.focused && !dropdown.compact
      }

      Rectangle {
        anchors.fill: parent
        radius: 4
        color: headerAreaNormal.containsMouse ? Colors.surface0 : "transparent"

      Row {
        id: headerLeft
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
          id: headerIcon
          anchors.verticalCenter: parent.verticalCenter
          text: dropdown.headerIcon
          color: Colors.blue
          font.pixelSize: 16
          font.family: "Symbols Nerd Font"
          visible: dropdown.headerIcon
        }

        AnnotationText {
          id: headerLabel
          anchors.verticalCenter: parent.verticalCenter
          text: dropdown.headerLabel
          visible: dropdown.headerLabel
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: dropdown.getItemText(dropdown.currentItem, false)
          color: Colors.text
          font.pixelSize: 15
          elide: Text.ElideRight
          width: {
            var used = chevronNormal.width + 24
            if (headerIcon.visible) used += headerIcon.width + headerLeft.spacing
            if (headerLabel.visible) used += headerLabel.width + headerLeft.spacing
            return Math.max(0, dropdown.width - used)
          }
        }
      }

      Text {
        id: chevronNormal
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: dropdown.expanded ? "\uf106" : "\uf107"
        color: Colors.overlay0
        font.pixelSize: 16
        font.family: "Symbols Nerd Font"
      }

      MouseArea {
        id: headerAreaNormal
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          dropdown.forceActiveFocus()
          dropdown.expanded = !dropdown.expanded
          dropdown.highlightIndex = -1
          dropdown.toggled(dropdown.expanded)
        }
      }
      }
    }

    // Items list (non-compact, flows in Column)
    Column {
      width: dropdown.width
      spacing: 2
      visible: dropdown.expanded

      Repeater {
        model: dropdown.items

        Rectangle {
          required property var modelData
          required property int index
          property bool isSelected: dropdown.isItemSelected(modelData)
          property bool isHighlighted: dropdown.highlightIndex === index

          width: dropdown.width
          height: 32
          radius: 4
          color: {
            if (isHighlighted) return Colors.surface1
            if (isSelected) return Colors.surface1
            if (itemAreaNormal.containsMouse) return Colors.surface0
            return "transparent"
          }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: isSelected ? dropdown.selectedIcon : (dropdown.itemIcon || dropdown.headerIcon)
              color: isSelected ? Colors.green : (isHighlighted ? Colors.blue : Colors.overlay0)
              font.pixelSize: 16
              font.family: "Symbols Nerd Font"
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: dropdown.getItemText(modelData, false)
              color: (isSelected || isHighlighted) ? Colors.text : Colors.subtext0
              font.pixelSize: 15
              elide: Text.ElideRight
              width: parent.width - 40
            }
          }

          MouseArea {
            id: itemAreaNormal
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdown.itemSelected(modelData)
          }
        }
      }
    }
  }

  // Compact mode: Header is the main element, items overlay below
  Item {
    visible: dropdown.compact
    width: dropdown.width
    height: 28

    // Focus ring (compact)
    Rectangle {
      anchors.fill: parent
      anchors.margins: -3
      radius: 7
      color: "transparent"
      border.width: 2
      border.color: Colors.peach
      visible: dropdown.focused && dropdown.compact
    }

    Rectangle {
      id: compactHeader
      anchors.fill: parent
      radius: 4
      color: headerAreaCompact.containsMouse ? Colors.surface1 : Colors.surface0
      border.width: 1
      border.color: Colors.surface2

    Row {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 4

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: dropdown.getItemText(dropdown.currentItem, true)
        color: Colors.text
        font.pixelSize: 12
        elide: Text.ElideRight
        width: parent.width - 20
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: dropdown.expanded ? "\uf106" : "\uf107"
        color: Colors.overlay0
        font.pixelSize: 10
        font.family: "Symbols Nerd Font"
      }
    }

    MouseArea {
      id: headerAreaCompact
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        dropdown.forceActiveFocus()
        dropdown.expanded = !dropdown.expanded
        dropdown.highlightIndex = -1
        dropdown.toggled(dropdown.expanded)
      }
    }
    }
  }

  // Compact items list (using Popup for proper overlay behavior)
  Popup {
    id: compactPopup
    visible: dropdown.compact && dropdown.expanded
    x: 0
    y: compactHeader.height + 2
    width: dropdown.width
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onClosed: {
      if (dropdown.expanded) {
        dropdown.expanded = false
        dropdown.toggled(false)
      }
    }

    background: Rectangle {
      radius: 4
      color: Colors.surface0
      border.width: 1
      border.color: Colors.surface2
    }

    contentItem: Column {
      id: itemsColumn
      width: dropdown.width
      spacing: 0

      Repeater {
        id: itemsRepeaterCompact
        model: dropdown.items

        Rectangle {
          required property var modelData
          property bool isSelected: dropdown.isItemSelected(modelData)

          width: dropdown.width
          height: 32
          radius: 4
          color: isSelected ? Colors.surface1 : (itemAreaCompact.containsMouse ? Colors.surface1 : "transparent")

          Text {
            anchors.centerIn: parent
            text: dropdown.getItemText(modelData, true)
            color: isSelected ? Colors.text : Colors.subtext0
            font.pixelSize: 12
          }

          MouseArea {
            id: itemAreaCompact
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdown.itemSelected(modelData)
          }
        }
      }
    }
  }
}
