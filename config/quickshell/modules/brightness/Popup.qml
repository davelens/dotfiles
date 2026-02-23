import Quickshell
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  model: PopupManager.isOpen("brightness") && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PopupBase {
    popupWidth: 320

    // Pause brightness refresh while popup is open
    Component.onCompleted: BrightnessManager.popupOpen = true
    Component.onDestruction: BrightnessManager.popupOpen = false

    Repeater {
      model: BrightnessManager.displays

      Column {
        width: parent.width
        spacing: 4

        Text {
          text: (modelData.type === "ddc" ? "󰍹  " : "󰌢  ") + modelData.name
          color: Colors.overlay0
          font.pixelSize: 16
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
            font.pixelSize: 20
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
            font.pixelSize: 16
            width: 44
            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }
}
