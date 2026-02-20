import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card

    // Required properties
    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property var urgency: NotificationUrgency.Normal
    property bool showCloseButton: true
    property bool compact: false  // Compact mode for history panel

    signal dismissed()
    signal clicked()

    width: parent ? parent.width : 360
    height: compact ? compactLayout.height + 16 : fullLayout.height + 20
    radius: 8
    color: mouseArea.containsMouse ? Colors.surface1 : Colors.surface0

    // Left border for urgency indication
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        radius: 8
        color: {
            if (urgency === NotificationUrgency.Critical) return Colors.red
            if (urgency === NotificationUrgency.Low) return Colors.surface2
            return Colors.blue
        }
    }

    // Full layout (for popups)
    Column {
        id: fullLayout
        visible: !compact
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: showCloseButton ? 36 : 12
        anchors.topMargin: 10
        spacing: 4

        // Header row: icon + app name
        Row {
            spacing: 8

            // App icon
            IconImage {
                id: iconImage
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: appIcon
                visible: appIcon !== ""
            }

            Text {
                visible: appIcon === ""
                text: "󰀄"
                color: Colors.overlay0
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: appName
                color: Colors.overlay1
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Summary
        Text {
            width: parent.width
            text: summary
            color: Colors.text
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Body
        Text {
            width: parent.width
            text: body
            color: Colors.subtext0
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
            visible: body !== ""
        }
    }

    // Compact layout (for history panel)
    Column {
        id: compactLayout
        visible: compact
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: showCloseButton ? 32 : 12
        anchors.topMargin: 8
        spacing: 2

        // Summary
        Text {
            width: parent.width
            text: summary
            color: Colors.text
            font.pixelSize: 13
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Body (single line)
        Text {
            width: parent.width
            text: body
            color: Colors.subtext0
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: body !== ""
        }
    }

    // Close button
    Text {
        visible: showCloseButton && mouseArea.containsMouse
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: compact ? 8 : 10
        text: "󰅖"
        color: closeArea.containsMouse ? Colors.red : Colors.overlay0
        font.pixelSize: 14
        font.family: "Symbols Nerd Font"

        MouseArea {
            id: closeArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(event) {
                event.accepted = true
                card.dismissed()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: 100 }
    }
}
