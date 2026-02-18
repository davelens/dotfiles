import QtQuick

// Reusable expandable device list component
Column {
    id: deviceList
    spacing: 2

    // Required properties
    required property var devices  // Array of device objects
    required property var currentDevice  // Currently selected device
    required property string headerIcon
    required property string headerLabel

    // State
    property bool expanded: false

    // Signals
    signal deviceSelected(var device)
    signal toggleExpanded()

    // Header
    Rectangle {
        width: deviceList.width
        height: 28
        radius: 4
        color: headerArea.containsMouse ? Colors.surface0 : "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: deviceList.headerIcon
                color: Colors.blue
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: deviceList.headerLabel
                color: Colors.overlay0
                font.pixelSize: 11
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: deviceList.currentDevice
                    ? (deviceList.currentDevice.description || deviceList.currentDevice.name || "Unknown")
                    : "No device"
                color: Colors.text
                font.pixelSize: 13
                elide: Text.ElideRight
                width: parent.width - 90
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: deviceList.expanded ? "\uf106" : "\uf107"
                color: Colors.overlay0
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                deviceList.expanded = !deviceList.expanded
                deviceList.toggleExpanded()
            }
        }
    }

    // Device list (shown when expanded)
    Column {
        width: deviceList.width
        spacing: 2
        visible: deviceList.expanded

        Repeater {
            model: deviceList.devices

            Rectangle {
                required property var modelData
                property bool isSelected: deviceList.currentDevice && deviceList.currentDevice.id === modelData.id

                width: deviceList.width
                height: 32
                radius: 4
                color: isSelected ? Colors.surface1 : (itemArea.containsMouse ? Colors.surface0 : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: isSelected ? "\uf00c" : deviceList.headerIcon
                        color: isSelected ? Colors.green : Colors.overlay0
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.description || modelData.name || "Unknown"
                        color: isSelected ? Colors.text : Colors.subtext0
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 40
                    }
                }

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceList.deviceSelected(modelData)
                }
            }
        }
    }
}
