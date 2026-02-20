import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import ".."

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
    height: compact ? compactLayout.height + 24 : fullLayout.height + 28
    topLeftRadius: 0
    bottomLeftRadius: 0
    topRightRadius: 8
    bottomRightRadius: 8
    color: mouseArea.containsMouse ? Colors.surface1 : Colors.crust
    border.width: 2
    border.color: Colors.surface2

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowHorizontalOffset: 2
        shadowVerticalOffset: 2
        shadowBlur: 0.5
    }

    // Left border for urgency indication
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
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
        anchors.leftMargin: 26
        anchors.rightMargin: showCloseButton ? 40 : 26
        anchors.topMargin: 12
        spacing: 4

        // Header row: icon + app name
        Row {
            spacing: 8

            // App icon
            IconImage {
                id: iconImage
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 18
                source: appIcon
                visible: appIcon !== ""
            }

            Text {
                visible: appIcon === ""
                text: "󰀄"
                color: Colors.overlay0
                font.pixelSize: 16
                font.family: "Symbols Nerd Font"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: appName
                color: Colors.overlay1
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Summary
        Text {
            width: parent.width
            text: summary
            color: Colors.text
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Body
        Text {
            width: parent.width
            text: body
            color: Colors.subtext0
            font.pixelSize: 14
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
        anchors.leftMargin: 16
        anchors.rightMargin: showCloseButton ? 36 : 16
        anchors.topMargin: 10
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
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: compact ? 10 : 12
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
