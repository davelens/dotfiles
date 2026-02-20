import Quickshell
import QtQuick
import ".."

BarButton {
    id: button

    // Required: screen for popup management
    required property var screen

    // Force reactive update by depending on the properties that affect the icon
    icon: {
        var _ = WirelessManager.enabled
        var __ = WirelessManager.connectedNetwork
        return WirelessManager.getIcon()
    }
    iconColor: WirelessManager.enabled ? Colors.text : Colors.overlay0

    onClicked: PopupManager.toggle("wireless", screen)

    // Bar icon tooltip
    PopupWindow {
        visible: button.hovered && WirelessManager.connectedNetwork && !PopupManager.isOpen("wireless", button.screen)

        anchor.item: button
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -10

        implicitWidth: 260
        implicitHeight: 72
        color: Colors.crust

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 2

            Text {
                text: "Connected to " + (WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : "")
                color: Colors.text
                font.pixelSize: 13
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: "Uptime: " + WirelessManager.getConnectionDurationLong()
                color: Colors.overlay0
                font.pixelSize: 12
            }

            Row {
                spacing: 16

                Text {
                    text: "Down: " + WirelessManager.formatSpeed(WirelessManager.downloadSpeed)
                    color: Colors.overlay0
                    font.pixelSize: 12
                }

                Text {
                    text: "Up: " + WirelessManager.formatSpeed(WirelessManager.uploadSpeed)
                    color: Colors.overlay0
                    font.pixelSize: 12
                }
            }
        }
    }

    // Main popup
    PopupWindow {
        id: popup

        property bool isOpen: PopupManager.isOpen("wireless", button.screen)

        visible: isOpen

        anchor.item: button
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -8

        implicitWidth: 340
        implicitHeight: {
            // Header (28) + spacing (12) + separator (1) + spacing (12)
            var h = 28 + 12 + 1 + 12

            if (!WirelessManager.enabled) {
                // "Wi-Fi is off" message
                h += 50
            } else {
                // Connected network (if any)
                if (WirelessManager.connectedNetwork) {
                    h += 36 + 6 + 32 + 12 // network row + spacing + connection info + spacing
                }

                // "Networks" header
                h += 20 + 12 // label + spacing

                // Network list (excluding connected)
                var visibleNetworks = WirelessManager.networks.filter(n => !n.active).length
                if (visibleNetworks > 0) {
                    // Cap at 8 networks to avoid huge popup
                    var displayCount = Math.min(visibleNetworks, 8)
                    h += displayCount * 36 + (displayCount - 1) * 2
                } else {
                    h += 40 // empty state message
                }
            }

            return h + 48 // margins
        }
        color: Colors.base

        // Start scan when popup opens
        onIsOpenChanged: {
            if (isOpen && WirelessManager.enabled) {
                WirelessManager.startScan()
            }
        }

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 12

            // Header with power toggle
            Row {
                width: parent.width
                height: 28
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WirelessManager.getIcon()
                    color: WirelessManager.enabled ? Colors.blue : Colors.overlay0
                    font.pixelSize: 18
                    font.family: "Symbols Nerd Font"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    color: Colors.text
                    font.pixelSize: 14
                }

                Item { width: parent.width - 120; height: 1 }

                // Power toggle
                SwitchToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: WirelessManager.enabled
                    onClicked: WirelessManager.toggleEnabled()
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surface1
                visible: WirelessManager.enabled
            }

            // Connected network
            Column {
                width: parent.width
                spacing: 6
                visible: WirelessManager.connectedNetwork !== null

                Rectangle {
                    id: connectedNetworkRect
                    width: parent.width
                    height: 36
                    radius: 4
                    color: Colors.surface1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: WirelessManager.getIcon()
                        color: Colors.green
                        font.pixelSize: 16
                        font.family: "Symbols Nerd Font"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.right: disconnectBtn.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : ""
                        color: Colors.text
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        id: disconnectBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        color: disconnectArea.containsMouse ? Colors.red : Colors.overlay0
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font"

                        MouseArea {
                            id: disconnectArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WirelessManager.disconnect()
                        }
                    }
                }

                // Connection info (uptime + speeds)
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 2

                    Text {
                        text: "Uptime: " + WirelessManager.getConnectionDurationLong()
                        color: Colors.overlay0
                        font.pixelSize: 12
                    }

                    Text {
                        text: "Down: " + WirelessManager.formatSpeed(WirelessManager.downloadSpeed) + "  Up: " + WirelessManager.formatSpeed(WirelessManager.uploadSpeed)
                        color: Colors.overlay0
                        font.pixelSize: 12
                    }
                }
            }

            // Networks header
            Item {
                width: parent.width
                height: 20
                visible: WirelessManager.enabled

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: WirelessManager.scanning ? "Scanning..." : "Networks"
                        color: Colors.overlay0
                        font.pixelSize: 12
                    }

                    // Spinner while scanning
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰔟"
                        color: Colors.blue
                        font.pixelSize: 12
                        font.family: "Symbols Nerd Font"
                        visible: WirelessManager.scanning

                        RotationAnimation on rotation {
                            running: WirelessManager.scanning
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                }

                // Refresh button
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰑐"
                    color: refreshArea.containsMouse ? Colors.blue : Colors.overlay0
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                    visible: !WirelessManager.scanning

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WirelessManager.startScan()
                    }
                }
            }

            // Network list
            Column {
                width: parent.width
                spacing: 2
                visible: WirelessManager.enabled

                Repeater {
                    // Filter out active network and limit to 8
                    model: WirelessManager.networks.filter(n => !n.active).slice(0, 8)

                    Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 36
                        radius: 4
                        color: networkArea.containsMouse ? Colors.surface0 : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: WirelessManager.getSignalIcon(modelData.signal)
                            color: Colors.overlay0
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: securityIcon.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.ssid
                            color: Colors.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            id: securityIcon
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.security ? "󰌾" : ""
                            color: Colors.overlay0
                            font.pixelSize: 12
                            font.family: "Symbols Nerd Font"
                        }

                        MouseArea {
                            id: networkArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: WirelessManager.busy ? Qt.WaitCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!WirelessManager.busy) {
                                    WirelessManager.connect(modelData.ssid)
                                }
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    width: parent.width
                    text: WirelessManager.scanning ? "Looking for networks..." : "No networks found"
                    color: Colors.overlay0
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    visible: WirelessManager.networks.filter(n => !n.active).length === 0
                    topPadding: 8
                    bottomPadding: 8
                }
            }

            // WiFi off state
            Column {
                width: parent.width
                spacing: 8
                visible: !WirelessManager.enabled

                Text {
                    width: parent.width
                    text: "Wi-Fi is off"
                    color: Colors.overlay0
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 8
                }

                Text {
                    width: parent.width
                    text: "Toggle the switch above to enable"
                    color: Colors.overlay1
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    bottomPadding: 8
                }
            }
        }
    }
}
