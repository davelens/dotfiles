import QtQuick
import Quickshell.I3
import "../.."

Row {
  property var screen

  anchors.verticalCenter: parent.verticalCenter
  spacing: 2

  // Build model array: auto-detect reads from compositor, manual uses fixed count
  readonly property var workspaceModel: {
    if (WorkspacesManager.autoDetect) {
      var wsValues = I3.workspaces.values
      var arr = []
      for (var i = 0; i < wsValues.length; i++) arr.push(wsValues[i])
      arr.sort(function(a, b) { return a.number - b.number })
      var names = []
      for (var j = 0; j < arr.length; j++) names.push(arr[j].name)
      return names
    }
    var fixed = []
    for (var k = 1; k <= WorkspacesManager.count; k++) fixed.push(String(k))
    return fixed
  }

  Repeater {
    model: workspaceModel

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
        text: {
          var mode = WorkspacesManager.displayMode
          if (mode === "dots") {
            return (workspaceRect.isFocused || workspaceRect.hasWindows) ? "" : ""
          }
          if (mode === "numbers") return workspaceRect.modelData
          // icons mode
          return WorkspacesManager.icons[workspaceRect.modelData] || workspaceRect.modelData
        }
        color: workspaceRect.isFocused ? Colors.blue : (workspaceRect.hasWindows ? Colors.text : Colors.overlay0)
        font.pixelSize: WorkspacesManager.displayMode === "dots" ? 12 : 18
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
