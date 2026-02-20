import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

// Notification popups window - displays in top-right corner
Variants {
    model: DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

    PanelWindow {
        required property var modelData

        id: popupWindow
        screen: modelData
        visible: NotificationManager.visibleNotifications.length > 0

        anchors {
            top: true
            right: true
        }

        // Position below the bar with margin
        margins {
            top: 44  // Bar height (32) + gap (12)
            right: 12
        }

        implicitWidth: 360
        implicitHeight: notificationColumn.height

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: notificationColumn
            width: parent.width
            spacing: 8

            Repeater {
                model: NotificationManager.visibleNotifications

                Item {
                    id: notificationItem
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: card.height

                    // Track if mouse is hovering (pauses timeout)
                    property bool isHovered: cardMouseArea.containsMouse

                    NotificationCard {
                        id: card
                        width: parent.width
                        appName: modelData.appName
                        appIcon: modelData.appIcon
                        summary: modelData.summary
                        body: modelData.body
                        urgency: modelData.urgency
                        showCloseButton: true
                        compact: false

                        // Slide-in animation
                        x: 0
                        opacity: 1

                        Component.onCompleted: {
                            // Start off-screen
                            x = 400
                            opacity = 0
                            // Animate in
                            slideIn.start()
                        }

                        NumberAnimation on x {
                            id: slideIn
                            from: 400
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                            running: false
                        }

                        NumberAnimation on opacity {
                            id: fadeIn
                            from: 0
                            to: 1
                            duration: 200
                            running: slideIn.running
                        }

                        onDismissed: {
                            NotificationManager.dismissPopup(modelData.id)
                        }

                        onClicked: {
                            NotificationManager.dismissPopup(modelData.id)
                        }

                        MouseArea {
                            id: cardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onClicked: function(event) {
                                event.accepted = false
                            }
                            onPressed: function(event) {
                                event.accepted = false
                            }
                            onReleased: function(event) {
                                event.accepted = false
                            }
                        }
                    }

                    // Auto-dismiss timer
                    Timer {
                        id: dismissTimer
                        interval: NotificationManager.popupTimeout
                        running: !notificationItem.isHovered && notificationItem.visible
                        repeat: false
                        onTriggered: {
                            NotificationManager.expirePopup(modelData.id)
                        }
                    }

                    // Reset timer when hover ends
                    onIsHoveredChanged: {
                        if (!isHovered) {
                            dismissTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
