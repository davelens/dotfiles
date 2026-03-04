import QtQuick
import Quickshell
import "../.."

Item {
  id: root
  property var screen
  property bool barFocused: false

  anchors.verticalCenter: parent.verticalCenter
  width: contentRow.width
  height: contentRow.height

  Row {
    id: contentRow
    spacing: 4

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      color: Colors.text
      font.pixelSize: 16
      font.family: "Symbols Nerd Font"
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemLoadManager.cpuPercent + "%"
      color: Colors.text
      font.pixelSize: 14
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰧑"
      color: Colors.text
      font.pixelSize: 16
      font.family: "Symbols Nerd Font"
      leftPadding: 6
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemLoadManager.ramPercent + "%"
      color: Colors.text
      font.pixelSize: 14
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
  }

  PopupWindow {
    visible: hoverArea.containsMouse || root.barFocused

    anchor.item: root
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
      spacing: 4

      Text {
        text: "CPU: " + SystemLoadManager.cpuPercent + "%"
        color: Colors.text
        font.pixelSize: 14
      }

      Text {
        text: "Memory: " + SystemLoadManager.ramUsedGb.toFixed(1) + " / " + SystemLoadManager.ramTotalGb.toFixed(1) + " GB (" + SystemLoadManager.ramPercent + "%)"
        color: Colors.text
        font.pixelSize: 14
      }
    }
  }
}
