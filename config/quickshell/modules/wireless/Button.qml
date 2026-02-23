import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  popupId: "wireless"

  // Force reactive update by depending on the properties that affect the icon
  icon: {
    var _ = WirelessManager.enabled
    var __ = WirelessManager.connectedNetwork
    return WirelessManager.getIcon()
  }
  iconColor: WirelessManager.enabled ? Colors.text : Colors.overlay0

  // Bar icon tooltip
  PopupWindow {
    visible: button.hovered && WirelessManager.connectedNetwork && !button.popupManager.isOpen("wireless")

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
}
