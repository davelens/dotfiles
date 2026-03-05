import QtQuick
import Quickshell.I3

// Sway/i3 workspace backend using native Quickshell.I3 API.
// Exposes normalized workspace data for Segment.qml consumption.
Item {
  visible: false

  // Normalized workspace list: [{ name, focused, hasWindows }]
  readonly property var workspaces: {
    var _ = I3.workspaces.values.length
    var arr = []
    var wsValues = I3.workspaces.values
    for (var i = 0; i < wsValues.length; i++) {
      var ws = wsValues[i]
      var hasWin = false
      var ipc = ws.lastIpcObject
      if (ipc && ipc.representation) {
        var match = ipc.representation.match(/\[(.+)\]/)
        hasWin = match !== null && match[1].length > 0
      }
      arr.push({ name: ws.name, focused: ws.focused, hasWindows: hasWin })
    }
    arr.sort(function(a, b) {
      return parseInt(a.name) - parseInt(b.name)
    })
    return arr
  }

  function focusWorkspace(name) {
    I3.dispatch("workspace " + name)
  }

  // Find a single workspace by name
  function findWorkspace(name) {
    for (var i = 0; i < workspaces.length; i++) {
      if (workspaces[i].name === name) return workspaces[i]
    }
    return null
  }
}
