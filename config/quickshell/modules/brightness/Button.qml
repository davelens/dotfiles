import Quickshell
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

BarButton {
  id: button

  // Required: screen for popup management
  required property var screen

  // PopupManager passed from shell.qml for singleton consistency
  property var popupManager: PopupManager

  icon: BrightnessManager.getIcon(BrightnessManager.averageLevel)

  onClicked: button.popupManager.toggle("brightness", screen)

  onWheel: event => {
    var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
    for (var i = 0; i < BrightnessManager.displays.length; i++) {
      var d = BrightnessManager.displays[i]
      var newLevel = Math.max(0.01, Math.min(1, d.brightness + delta))
      BrightnessManager.setBrightness(d.id, newLevel)
    }
  }

  PopupWindow {
    id: popup

    property bool isOpen: button.popupManager.isOpen("brightness", button.screen)

    visible: isOpen

    anchor.item: button
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -8

    implicitWidth: 280
    implicitHeight: content.implicitHeight + 48
    color: Colors.base

    // Pause brightness refresh while popup is open
    onIsOpenChanged: BrightnessManager.popupOpen = isOpen

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

    Column {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 24
      spacing: 8

      Repeater {
        model: BrightnessManager.displays

        Column {
          width: parent.width
          spacing: 4

          Text {
            text: (modelData.type === "ddc" ? "󰍹  " : "󰌢  ") + modelData.name
            color: Colors.overlay0
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
          }

          Row {
            width: parent.width
            height: 32
            spacing: 8

            property string displayId: modelData.id
            property real displayBrightness: modelData.brightness

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: BrightnessManager.getIcon(brightnessSlider.value)
              color: Colors.text
              font.pixelSize: 18
              font.family: "Symbols Nerd Font"
            }

            Slider {
              id: brightnessSlider
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 18 - 44 - 16
              height: 20
              from: 0.01
              to: 1
              value: parent.displayBrightness

              onMoved: BrightnessManager.setBrightness(parent.displayId, value)

              background: Rectangle {
                x: brightnessSlider.leftPadding
                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 8
                width: brightnessSlider.availableWidth
                height: 8
                radius: 4
                color: Colors.surface0

                Rectangle {
                  width: brightnessSlider.visualPosition * parent.width
                  height: parent.height
                  color: Colors.yellow
                  radius: 4
                }
              }

              handle: Rectangle {
                x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                implicitWidth: 14
                implicitHeight: 14
                width: 14
                height: 14
                radius: 7
                color: Colors.text
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(brightnessSlider.value * 100) + "%"
              color: Colors.yellow
              font.pixelSize: 14
              width: 44
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
