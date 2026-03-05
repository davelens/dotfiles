import QtQuick
import "../.."

Row {
  property var screen

  anchors.verticalCenter: parent.verticalCenter
  spacing: 2

  // Backend adapter loaded based on resolved compositor
  Loader {
    id: backendLoader
    visible: false
    source: WorkspacesManager.resolvedBackend === "niri"
      ? "NiriBackend.qml"
      : "I3Backend.qml"
  }

  readonly property var backend: backendLoader.item

  // Build model array: auto-detect reads from backend, manual uses fixed count
  readonly property var workspaceModel: {
    if (!backend) return []
    if (WorkspacesManager.autoDetect) {
      var ws = backend.workspaces
      var names = []
      for (var i = 0; i < ws.length; i++) names.push(ws[i].name)
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

      // Depend on backend.workspaces to re-evaluate when workspace state changes
      property var workspace: {
        if (!backend) return null
        var _ = backend.workspaces
        return backend.findWorkspace(modelData)
      }
      property bool isFocused: workspace ? workspace.focused : false
      property bool hasWindows: workspace ? workspace.hasWindows : false

      width: 28
      height: 24
      radius: 4
      color: isFocused ? Colors.surface1 : (workspaceArea.containsMouse ? Colors.surface0 : "transparent")

      Text {
        anchors.centerIn: parent
        text: {
          var mode = WorkspacesManager.displayMode
          if (mode === "dots") {
            return (workspaceRect.isFocused || workspaceRect.hasWindows) ? "\uf4c3" : "\uf4c2"
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
        onClicked: {
          if (backend) backend.focusWorkspace(workspaceRect.modelData)
        }
      }
    }
  }
}
