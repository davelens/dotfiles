import QtQuick
import Quickshell.I3
import "../.."

Row {
  property var screen

  anchors.verticalCenter: parent.verticalCenter
  spacing: 2

  readonly property var icons: ({
    "1": "",
    "2": "󰈹",
    "3": "󰙯",
    "4": "󰎇",
    "5": ""
  })

  Repeater {
    model: ["1", "2", "3", "4", "5"]

    Rectangle {
      id: workspaceRect
      required property string modelData

      property var workspace: {
        var _ = I3.workspaces.values.length
        return I3.findWorkspaceByName(modelData)
      }
      property bool isFocused: workspace ? workspace.focused : false
      property bool hasWindows: {
        if (!workspace) return false
        var ipc = workspace.lastIpcObject
        if (!ipc || !ipc.representation) return false
        var match = ipc.representation.match(/\[(.+)\]/)
        return match !== null && match[1].length > 0
      }

      width: 28
      height: 24
      radius: 4
      color: isFocused ? Colors.surface1 : (workspaceArea.containsMouse ? Colors.surface0 : "transparent")

      Text {
        anchors.centerIn: parent
        text: icons[workspaceRect.modelData] || workspaceRect.modelData
        color: workspaceRect.isFocused ? Colors.blue : (workspaceRect.hasWindows ? Colors.text : Colors.overlay0)
        font.pixelSize: 18
        font.family: "Symbols Nerd Font"
      }

      MouseArea {
        id: workspaceArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: I3.dispatch("workspace " + workspaceRect.modelData)
      }
    }
  }
}
