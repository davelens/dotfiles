import Quickshell
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  model: PopupManager.isOpen("brightness") && ScreenManager.primaryScreen
         ? [ScreenManager.primaryScreen] : []

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

        BodyText {
          text: (modelData.type === "ddc" ? "󰍹  " : "󰌢  ") + modelData.name
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

          FocusSlider {
            id: brightnessSlider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 18 - 44 - 16
            height: 20
            from: 0.01
            to: 1
            stepSize: 0.02
            value: parent.displayBrightness
            accentColor: Colors.yellow
            trackColor: Colors.surface0
            trackHeight: 8
            handleSize: 14
            onMoved: BrightnessManager.setBrightness(parent.displayId, value)
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
