import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  visible: UpdatesManager.totalCount > 0

  popupId: "updates"

  icon: UpdatesManager.getIcon()
  iconColor: Colors.green

  // Hover tooltip showing update count breakdown
  PopupWindow {
    visible: button.hovered && !button.popupManager.isOpen("updates")

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
        visible: UpdatesManager.checking || UpdatesManager.totalCount === 0
        text: UpdatesManager.checking ? "Checking for updates..." : "System up to date"
        color: Colors.text
        font.pixelSize: 13
      }

      // Breakdown lines when updates are available
      Text {
        visible: UpdatesManager.pacmanUpdates.length > 0
        text: UpdatesManager.pacmanUpdates.length + " system update" + (UpdatesManager.pacmanUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }

      Text {
        visible: UpdatesManager.aurUpdates.length > 0
        text: UpdatesManager.aurUpdates.length + " package update" + (UpdatesManager.aurUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }

      Text {
        visible: UpdatesManager.flatpakUpdates.length > 0
        text: UpdatesManager.flatpakUpdates.length + " flatpak update" + (UpdatesManager.flatpakUpdates.length !== 1 ? "s" : "")
        color: Colors.text
        font.pixelSize: 13
      }
    }
  }
}
