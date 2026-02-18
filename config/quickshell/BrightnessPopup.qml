import Quickshell
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: popup

    // Required: anchor item from parent
    required property Item anchorItem

    // State
    property bool isOpen: false

    visible: isOpen

    anchor.item: anchorItem
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
                    font.pixelSize: 11
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
