import Quickshell
import QtQuick
import ".."

BarButton {
    id: button

    // Required: screen for popup management
    required property var screen

    icon: "󰍹"

    onClicked: PopupManager.toggle("display", screen)

    PopupWindow {
        id: popup

        visible: PopupManager.isOpen("display", button.screen)

        anchor.item: button
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -8

        implicitWidth: 280
        implicitHeight: content.implicitHeight + 48
        color: Colors.base

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 12

            // Header
            Text {
                text: "Main display"
                color: Colors.text
                font.pixelSize: 14
            }

            // Display list
            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: Quickshell.screens

                Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 32
                    radius: 4
                    color: displayItemArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name.startsWith("eDP") ? "󰌢" : "󰍹"
                            color: DisplayConfig.isPrimary(modelData) ? Colors.blue : Colors.text
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: DisplayConfig.friendlyName(modelData)
                            color: Colors.text
                            font.pixelSize: 13
                            width: parent.width - 16 - 8 - 24 - 8 - 24
                            elide: Text.ElideRight
                        }

                        // Primary indicator / selector
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: DisplayConfig.isPrimary(modelData) ? "󰄬" : ""
                            color: Colors.blue
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Rotation toggle
                        Item {
                            id: rotateButton
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: parent.height

                            property bool isLandscape: modelData.width > modelData.height

                            Text {
                                anchors.centerIn: parent
                                text: "󰑵"
                                color: displayRotateArea.containsMouse ? Colors.blue : Colors.overlay0
                                font.pixelSize: 16
                                font.family: "Symbols Nerd Font"
                            }

                            MouseArea {
                                id: displayRotateArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DisplayConfig.toggleRotation(modelData)
                            }

                            // Rotation tooltip
                            PopupWindow {
                                visible: displayRotateArea.containsMouse

                                anchor.item: rotateButton
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.bottom: -8

                                implicitWidth: rotateTooltipText.implicitWidth + 16
                                implicitHeight: rotateTooltipText.implicitHeight + 12
                                color: Colors.crust

                                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

                                Text {
                                    id: rotateTooltipText
                                    anchors.centerIn: parent
                                    text: "Rotate 90°"
                                    color: Colors.text
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: displayItemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: {
                            DisplayConfig.setPrimary(modelData)
                            PopupManager.close()
                        }
                    }
                }
            }
            }
        }
    }
}
