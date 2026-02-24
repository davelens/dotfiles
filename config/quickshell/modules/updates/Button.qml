import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  property var updatesManager: UpdatesManager
  property int updateCount: 0

  // Whether this button should be shown in the bar (checked by shell.qml delegate)
  property bool showInBar: updateCount > 0

  popupId: "updates"

  icon: updatesManager.getIcon()
  iconColor: Colors.green

  // Hover tooltip showing update count breakdown
  PopupWindow {
    visible: button.hovered && !button.popupManager.isOpen("updates") && button.visible

    anchor.item: button
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -10

    implicitWidth: tooltipContent.implicitWidth + 24
    implicitHeight: tooltipContent.implicitHeight + 16
    color: Colors.crust

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

    Column {
      id: tooltipContent
      anchors.centerIn: parent
      spacing: 2

      // Single line for checking / up to date states
      Text {
        visible: button.updatesManager.checking || button.updatesManager.totalCount === 0
        text: button.updatesManager.checking ? "Checking for updates..." : "System up to date"
        color: Colors.text
        font.pixelSize: 13
      }

      // Breakdown lines when updates are available
      Text {
        visible: button.updatesManager.pacmanUpdates.length > 0
        text: button.updatesManager.pacmanUpdates.length + " system update" + (button.updatesManager.pacmanUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }

      Text {
        visible: button.updatesManager.aurUpdates.length > 0
        text: button.updatesManager.aurUpdates.length + " package update" + (button.updatesManager.aurUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }

      Text {
        visible: button.updatesManager.flatpakUpdates.length > 0
        text: button.updatesManager.flatpakUpdates.length + " flatpak update" + (button.updatesManager.flatpakUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }
    }
  }
}
