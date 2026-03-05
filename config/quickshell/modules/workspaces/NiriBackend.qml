import QtQuick
import Quickshell
import Quickshell.Io

// Niri workspace backend using CLI IPC.
// Polls `niri msg -j workspaces` and exposes normalized data.
Item {
  id: backend
  visible: false

  // Normalized workspace list: [{ name, focused, hasWindows }]
  property var workspaces: []

  // Auto-discover niri socket if not in environment
  readonly property string niriSocket: Quickshell.env("NIRI_SOCKET") || ""
  property string discoveredSocket: ""
  readonly property string socket: niriSocket || discoveredSocket

  // Socket discovery (runs once at startup if NIRI_SOCKET is unset)
  Process {
    id: discoverProc
    command: ["sh", "-c", "ls /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1"]
    running: !backend.niriSocket
  }

  SplitParser {
    source: discoverProc
    onRead: line => {
      if (line.trim()) backend.discoveredSocket = line.trim()
    }
  }

  // Poll timer
  Timer {
    interval: 750
    running: backend.socket !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!pollProc.running) pollProc.running = true
    }
  }

  // Workspace polling process
  Process {
    id: pollProc
    command: ["sh", "-c", "NIRI_SOCKET='" + backend.socket + "' niri msg -j workspaces"]
    property string buffer: ""
    onExited: (code) => {
      if (code === 0 && pollProc.buffer) {
        backend.parseWorkspaces(pollProc.buffer)
      }
      pollProc.buffer = ""
    }
  }

  SplitParser {
    source: pollProc
    onRead: line => { pollProc.buffer += line }
  }

  function parseWorkspaces(json) {
    try {
      var data = JSON.parse(json)
      var arr = []
      for (var i = 0; i < data.length; i++) {
        var ws = data[i]
        // Niri uses idx for ordering and may have optional names
        var name = ws.name || String(ws.idx)
        arr.push({
          name: name,
          focused: ws.is_focused || false,
          hasWindows: ws.active_window_id !== null
        })
      }
      arr.sort(function(a, b) {
        return parseInt(a.name) - parseInt(b.name)
      })
      workspaces = arr
    } catch (e) {
      console.error("[NiriBackend] Failed to parse workspaces:", e)
    }
  }

  function focusWorkspace(name) {
    focusProc.command = ["sh", "-c",
      "NIRI_SOCKET='" + backend.socket + "' niri msg action focus-workspace " + name]
    focusProc.running = true
  }

  Process {
    id: focusProc
  }

  // Find a single workspace by name
  function findWorkspace(name) {
    for (var i = 0; i < workspaces.length; i++) {
      if (workspaces[i].name === name) return workspaces[i]
    }
    return null
  }
}
