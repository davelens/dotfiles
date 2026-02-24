import Quickshell
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  id: updatesPopup

  property bool isOpen: PopupManager.isOpen("updates")

  model: isOpen && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PopupBase {
    id: popup
    popupWidth: 860
    popupRightMargin: UpdatesManager.totalCount > 0 ? -1 : 20
    contentSpacing: 12
    stemEnabled: UpdatesManager.totalCount > 0

    // Column height for the scrollable lists
    property int maxVisibleItems: 12
    property int rowHeight: 28
    property int rowSpacing: 4

    popupHeight: {
      // Header (28) + spacing (12) + system update row (32) + spacing (12) + separator (1) + spacing (12)
      var h = 28 + 12 + 32 + 12 + 1 + 12

      if (UpdatesManager.checking) {
        h += 40
      } else if (UpdatesManager.totalCount === 0) {
        h += 50
      } else {
        // Column headers (20) + spacing (8) + update-all button (26) + spacing (8) + list
        h += 20 + 8 + 26 + 8
        var maxItems = Math.max(
          Math.min(UpdatesManager.pacmanUpdates.length, popup.maxVisibleItems),
          Math.min(UpdatesManager.aurUpdates.length, popup.maxVisibleItems),
          Math.min(UpdatesManager.flatpakUpdates.length, popup.maxVisibleItems),
          1
        )
        h += maxItems * popup.rowHeight + (maxItems - 1) * popup.rowSpacing
      }

      return h + 48
    }

    // Header row
    Item {
      width: parent.width
      height: 28

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: UpdatesManager.getIcon()
          color: UpdatesManager.totalCount > 0 ? Colors.green : Colors.overlay0
          font.pixelSize: 20
          font.family: "Symbols Nerd Font"
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "System Updates"
          color: Colors.text
          font.pixelSize: 16
        }
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Refresh button
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "󰑐"
          color: refreshArea.containsMouse ? Colors.blue : Colors.overlay0
          font.pixelSize: 16
          font.family: "Symbols Nerd Font"
          visible: !UpdatesManager.checking

          MouseArea {
            id: refreshArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: UpdatesManager.checkUpdates()
          }
        }

        // Spinner while checking
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "󰔿"
          color: Colors.blue
          font.pixelSize: 16
          font.family: "Symbols Nerd Font"
          visible: UpdatesManager.checking

          RotationAnimation on rotation {
            running: UpdatesManager.checking
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }
        }
      }
    }

    // System update button row
    Item {
      width: parent.width
      height: 32

      FocusButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: UpdatesManager.systemUpdating ? "Updating system..." : "System Update"
        width: 160
        height: 28
        backgroundColor: UpdatesManager.totalCount > 0 && !UpdatesManager.systemUpdating ? Colors.green : Colors.surface1
        textColor: UpdatesManager.totalCount > 0 && !UpdatesManager.systemUpdating ? Colors.crust : Colors.overlay0
        hoverColor: UpdatesManager.totalCount > 0 && !UpdatesManager.systemUpdating ? Colors.teal : Colors.surface2
        enabled: UpdatesManager.totalCount > 0 && !UpdatesManager.systemUpdating && !UpdatesManager.checking
        opacity: enabled ? 1.0 : 0.5
        onClicked: UpdatesManager.systemUpdate()
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 170
        anchors.verticalCenter: parent.verticalCenter
        text: "Full system upgrade (pacman + AUR)"
        color: Colors.overlay0
        font.pixelSize: 12
        visible: !UpdatesManager.systemUpdating
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 170
        anchors.verticalCenter: parent.verticalCenter
        text: "Running paru -Syu... All other updates are blocked."
        color: Colors.yellow
        font.pixelSize: 12
        visible: UpdatesManager.systemUpdating
      }
    }

    // Separator
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
    }

    // Checking state
    Item {
      width: parent.width
      height: 40
      visible: UpdatesManager.checking

      Text {
        anchors.centerIn: parent
        text: "Checking for updates..."
        color: Colors.overlay0
        font.pixelSize: 14
      }
    }

    // Up to date state
    Column {
      width: parent.width
      spacing: 8
      visible: !UpdatesManager.checking && UpdatesManager.totalCount === 0

      Text {
        width: parent.width
        text: "System is up to date"
        color: Colors.overlay0
        font.pixelSize: 15
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
      }

      Text {
        width: parent.width
        text: "No pending updates"
        color: Colors.overlay1
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        bottomPadding: 8
      }
    }

    // Three-column layout
    Row {
      width: parent.width
      spacing: 12
      visible: !UpdatesManager.checking && UpdatesManager.totalCount > 0

      // Official column
      Column {
        width: (parent.width - 50) / 3
        spacing: 8

        // Header
        Text {
          text: "Official (" + UpdatesManager.pacmanUpdates.length + ")"
          color: Colors.overlay0
          font.pixelSize: 14
        }

        // Update all button
        FocusButton {
          width: parent.width
          height: 26
          text: "Update all"
          fontSize: 12
          backgroundColor: UpdatesManager.pacmanUpdates.length > 0 && !UpdatesManager.blocked ? Colors.surface1 : Colors.mantle
          textColor: UpdatesManager.pacmanUpdates.length > 0 && !UpdatesManager.blocked ? Colors.text : Colors.overlay0
          hoverColor: Colors.surface2
          enabled: UpdatesManager.pacmanUpdates.length > 0 && !UpdatesManager.blocked
          opacity: enabled ? 1.0 : 0.4
          onClicked: UpdatesManager.updateSource("pacman")
        }

        // Package list
        ScrollView {
          width: parent.width
          clip: true
          contentWidth: availableWidth
          height: {
            var count = Math.min(UpdatesManager.pacmanUpdates.length, popup.maxVisibleItems)
            if (count === 0) return 28
            return count * popup.rowHeight + (count - 1) * popup.rowSpacing
          }

          Column {
            width: parent.width
            spacing: popup.rowSpacing

            Repeater {
              model: UpdatesManager.pacmanUpdates

              Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: popup.rowHeight
                radius: 4
                color: pacPkgMouse.containsMouse ? Colors.surface0 : "transparent"

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 6
                  anchors.right: pacDlBtn.left
                  anchors.rightMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 1

                  Text {
                    width: parent.width
                    text: modelData.name
                    color: Colors.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: modelData.currentVersion + " \u2192 " + modelData.newVersion
                    color: Colors.overlay0
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                  }
                }

                Text {
                  id: pacDlBtn
                  anchors.right: parent.right
                  anchors.rightMargin: 14
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰇚"
                  color: {
                    if (UpdatesManager.blocked) return Colors.surface2
                    if (UpdatesManager.isUpdating(modelData.name)) return Colors.yellow
                    return pacPkgMouse.containsMouse ? Colors.green : Colors.overlay0
                  }
                  font.pixelSize: 13
                  font.family: "Symbols Nerd Font"
                }

                MouseArea {
                  id: pacPkgMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: UpdatesManager.blocked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                  onClicked: {
                    if (!UpdatesManager.blocked) {
                      UpdatesManager.updatePackage(modelData.name, "pacman")
                    }
                  }
                }
              }
            }

            // Empty state
            Text {
              visible: UpdatesManager.pacmanUpdates.length === 0
              text: "No updates"
              color: Colors.overlay0
              font.pixelSize: 12
              topPadding: 4
            }
          }
        }
      }

      // Separator
      Rectangle { width: 1; height: parent.height; color: Colors.surface1 }

      // AUR column
      Column {
        width: (parent.width - 50) / 3
        spacing: 8

        Text {
          text: "AUR (" + UpdatesManager.aurUpdates.length + ")"
          color: Colors.overlay0
          font.pixelSize: 14
        }

        FocusButton {
          width: parent.width
          height: 26
          text: "Update all"
          fontSize: 12
          backgroundColor: UpdatesManager.aurUpdates.length > 0 && !UpdatesManager.blocked ? Colors.surface1 : Colors.mantle
          textColor: UpdatesManager.aurUpdates.length > 0 && !UpdatesManager.blocked ? Colors.text : Colors.overlay0
          hoverColor: Colors.surface2
          enabled: UpdatesManager.aurUpdates.length > 0 && !UpdatesManager.blocked
          opacity: enabled ? 1.0 : 0.4
          onClicked: UpdatesManager.updateSource("aur")
        }

        ScrollView {
          width: parent.width
          clip: true
          contentWidth: availableWidth
          height: {
            var count = Math.min(UpdatesManager.aurUpdates.length, popup.maxVisibleItems)
            if (count === 0) return 28
            return count * popup.rowHeight + (count - 1) * popup.rowSpacing
          }

          Column {
            width: parent.width
            spacing: popup.rowSpacing

            Repeater {
              model: UpdatesManager.aurUpdates

              Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: popup.rowHeight
                radius: 4
                color: aurPkgMouse.containsMouse ? Colors.surface0 : "transparent"

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 6
                  anchors.right: aurDlBtn.left
                  anchors.rightMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 1

                  Text {
                    width: parent.width
                    text: modelData.name
                    color: Colors.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: modelData.currentVersion + " \u2192 " + modelData.newVersion
                    color: Colors.overlay0
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                  }
                }

                Text {
                  id: aurDlBtn
                  anchors.right: parent.right
                  anchors.rightMargin: 14
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰇚"
                  color: {
                    if (UpdatesManager.blocked) return Colors.surface2
                    if (UpdatesManager.isUpdating(modelData.name)) return Colors.yellow
                    return aurPkgMouse.containsMouse ? Colors.green : Colors.overlay0
                  }
                  font.pixelSize: 13
                  font.family: "Symbols Nerd Font"
                }

                MouseArea {
                  id: aurPkgMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: UpdatesManager.blocked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                  onClicked: {
                    if (!UpdatesManager.blocked) {
                      UpdatesManager.updatePackage(modelData.name, "aur")
                    }
                  }
                }
              }
            }

            Text {
              visible: UpdatesManager.aurUpdates.length === 0
              text: "No updates"
              color: Colors.overlay0
              font.pixelSize: 12
              topPadding: 4
            }
          }
        }
      }

      // Separator
      Rectangle { width: 1; height: parent.height; color: Colors.surface1 }

      // Flatpak column
      Column {
        width: (parent.width - 50) / 3
        spacing: 8

        Text {
          text: "Flatpak (" + UpdatesManager.flatpakUpdates.length + ")"
          color: Colors.overlay0
          font.pixelSize: 14
        }

        FocusButton {
          width: parent.width
          height: 26
          text: "Update all"
          fontSize: 12
          backgroundColor: UpdatesManager.flatpakUpdates.length > 0 && !UpdatesManager.blocked ? Colors.surface1 : Colors.mantle
          textColor: UpdatesManager.flatpakUpdates.length > 0 && !UpdatesManager.blocked ? Colors.text : Colors.overlay0
          hoverColor: Colors.surface2
          enabled: UpdatesManager.flatpakUpdates.length > 0 && !UpdatesManager.blocked
          opacity: enabled ? 1.0 : 0.4
          onClicked: UpdatesManager.updateSource("flatpak")
        }

        ScrollView {
          width: parent.width
          clip: true
          contentWidth: availableWidth
          height: {
            var count = Math.min(UpdatesManager.flatpakUpdates.length, popup.maxVisibleItems)
            if (count === 0) return 28
            return count * popup.rowHeight + (count - 1) * popup.rowSpacing
          }

          Column {
            width: parent.width
            spacing: popup.rowSpacing

            Repeater {
              model: UpdatesManager.flatpakUpdates

              Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: popup.rowHeight
                radius: 4
                color: fpPkgMouse.containsMouse ? Colors.surface0 : "transparent"

                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 6
                  anchors.right: fpDlBtn.left
                  anchors.rightMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 1

                  Text {
                    width: parent.width
                    text: modelData.name
                    color: Colors.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: modelData.newVersion ? modelData.newVersion : modelData.appId
                    color: Colors.overlay0
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                  }
                }

                Text {
                  id: fpDlBtn
                  anchors.right: parent.right
                  anchors.rightMargin: 14
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰇚"
                  color: {
                    if (UpdatesManager.blocked) return Colors.surface2
                    if (UpdatesManager.isUpdating(modelData.name)) return Colors.yellow
                    return fpPkgMouse.containsMouse ? Colors.green : Colors.overlay0
                  }
                  font.pixelSize: 13
                  font.family: "Symbols Nerd Font"
                }

                MouseArea {
                  id: fpPkgMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: UpdatesManager.blocked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                  onClicked: {
                    if (!UpdatesManager.blocked) {
                      UpdatesManager.updatePackage(modelData.appId, "flatpak")
                    }
                  }
                }
              }
            }

            Text {
              visible: UpdatesManager.flatpakUpdates.length === 0
              text: "No updates"
              color: Colors.overlay0
              font.pixelSize: 12
              topPadding: 4
            }
          }
        }
      }
    }
  }
}
