import QtQuick
import ".."

Item {
  id: button

  property string text: ""
  property color textColor: Colors.text
  property color textHoverColor: textColor
  property color backgroundColor: Colors.surface0
  property color hoverColor: Colors.surface1
  property int fontSize: 13

  // Allow parent to control whether focus ring is shown
  property bool showFocusRing: true

  // Track if focus came from keyboard (not mouse)
  property bool keyboardFocus: false

  // Focus support - only show ring for keyboard focus
  property bool focused: activeFocus && showFocusRing && keyboardFocus
  property bool hovered: mouseArea.containsMouse
  focus: true
  activeFocusOnTab: true

  onActiveFocusChanged: {
    if (!activeFocus) keyboardFocus = false
  }

  signal clicked()

  width: 180
  height: 36

  // Focus ring
  Rectangle {
    anchors.centerIn: parent
    width: parent.width + 6
    height: parent.height + 6
    radius: body.radius + 3
    color: "transparent"
    border.width: 2
    border.color: Colors.peach
    visible: button.focused
  }

  // Button body
  Rectangle {
    id: body
    anchors.fill: parent
    radius: 6
    color: button.hovered ? button.hoverColor : button.backgroundColor

    Text {
      anchors.centerIn: parent
      text: button.text
      color: button.hovered ? button.textHoverColor : button.textColor
      font.pixelSize: button.fontSize
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      button.forceActiveFocus()
      button.clicked()
    }
  }

  Keys.onSpacePressed: button.clicked()
  Keys.onReturnPressed: button.clicked()
  Keys.onEnterPressed: button.clicked()
}
