import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  model: PopupManager.isOpen("brightness") && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PanelWindow {
    required property var modelData

    id: panel
    screen: modelData

    anchors {
      top: true
      left: true
      right: true
      bottom: true
    }

    margins.top: 42
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    contentItem {
      focus: true
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          PopupManager.close()
          event.accepted = true
        }
      }
    }

    // Pause brightness refresh while popup is open
    Component.onCompleted: BrightnessManager.popupOpen = true
    Component.onDestruction: BrightnessManager.popupOpen = false

    // Click outside to close
    MouseArea {
      anchors.fill: parent
      onClicked: PopupManager.close()
    }

    // Popup content
    Rectangle {
      x: PopupManager.anchorRight - width
      y: 0
      width: 280
      height: content.implicitHeight + 48
      color: Colors.base
      border.width: 1
      border.color: Colors.surface2

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
}
