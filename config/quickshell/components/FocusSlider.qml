import QtQuick
import QtQuick.Controls
import ".."

Item {
  id: slider

  property real from: 0
  property real to: 100
  property real value: 0
  property real stepSize: 1
  property bool live: true

  // Allow parent to control whether focus ring is shown
  property bool showFocusRing: true

  // Track if focus came from keyboard (not mouse)
  property bool keyboardFocus: false

  // Focus support - only show ring for keyboard focus
  property bool focused: activeFocus && showFocusRing && keyboardFocus
  focus: true
  activeFocusOnTab: true

  onActiveFocusChanged: {
    if (!activeFocus) keyboardFocus = false
  }

  width: parent ? parent.width : 200
  height: 24

  // Sync value changes from internal slider
  onValueChanged: control.value = value

  // Focus ring
  Rectangle {
    anchors.centerIn: parent
    width: parent.width + 8
    height: parent.height + 8
    radius: 6
    color: "transparent"
    border.width: 2
    border.color: Colors.peach
    visible: slider.focused
  }

  Slider {
    id: control
    anchors.fill: parent
    from: slider.from
    to: slider.to
    value: slider.value
    stepSize: slider.stepSize
    live: slider.live

    onValueChanged: slider.value = value

    background: Rectangle {
      x: control.leftPadding
      y: control.topPadding + control.availableHeight / 2 - height / 2
      width: control.availableWidth
      height: 4
      radius: 2
      color: Colors.surface1

      Rectangle {
        width: control.visualPosition * parent.width
        height: parent.height
        radius: 2
        color: Colors.blue
      }
    }

    handle: Rectangle {
      x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
      y: control.topPadding + control.availableHeight / 2 - height / 2
      width: 16
      height: 16
      radius: 8
      color: Colors.text
    }
  }

  MouseArea {
    id: sliderArea
    anchors.fill: parent
    onPressed: function(event) {
      slider.forceActiveFocus()
      event.accepted = false
    }
  }

  // Keyboard controls: h/l to decrease/increase
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
      control.decrease()
      event.accepted = true
    } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
      control.increase()
      event.accepted = true
    }
  }
}
