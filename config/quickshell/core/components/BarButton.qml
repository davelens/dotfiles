import QtQuick
import "../.."

Rectangle {
  id: button

  // Required
  required property string icon
  required property var screen

  // Popup toggle: set popupId to auto-handle click via popupManager
  property var popupManager: null
  property string popupId: ""

  // Whether this button's popup is currently open (visual effects only when stem is enabled)
  readonly property bool popupOpen: StatusbarManager.popupStem && popupId !== "" && popupManager && popupManager.isOpen(popupId)

  // Optional customization
  property int iconSize: 18
  property color iconColor: Colors.text
  property color iconColorHover: iconColor
  property bool iconColorOnHover: false

  // Expose hover state and click signal
  readonly property bool hovered: mouseArea.containsMouse
  signal clicked()

  // Also support scroll wheel
  signal wheel(var event)

  width: 28
  height: 24
  radius: 4
  bottomLeftRadius: popupOpen ? 0 : 4
  bottomRightRadius: popupOpen ? 0 : 4
  color: {
    if (popupOpen) return Colors.base
    return mouseArea.containsMouse ? Colors.surface1 : Colors.surface0
  }

  // Left border when popup is open
  Rectangle {
    visible: button.popupOpen
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 1
    color: Colors.surface2
  }

  // Top border when popup is open
  Rectangle {
    visible: button.popupOpen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 1
    color: Colors.surface2
  }

  // Right border when popup is open
  Rectangle {
    visible: button.popupOpen
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 1
    color: Colors.surface2
  }

  Text {
    anchors.centerIn: parent
    text: button.icon
    color: button.iconColorOnHover && mouseArea.containsMouse ? button.iconColorHover : button.iconColor
    font.pixelSize: button.iconSize
    font.family: "Symbols Nerd Font"
  }

  // Store anchor position for IPC toggles (so popup appears below the button)
  // Register this button with PopupManager so IPC toggles can compute
  // the anchor position at open time (avoids stale stored positions).
  Component.onCompleted: {
    if (popupId !== "" && popupManager) {
      popupManager.registerButton(popupId, button)
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      if (button.popupId !== "" && button.popupManager) {
        var mapped = button.mapToItem(null, button.width, 0)
        button.popupManager.toggle(button.popupId, button.screen, mapped.x)
      } else {
        button.clicked()
      }
    }

    onWheel: event => button.wheel(event)
  }
}
