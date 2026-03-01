pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: displayConfig

  // Open the settings panel to the display category
  function openSettings() {
    PopupManager.close()
    settingsIpcProc.running = true
  }

  Process {
    id: settingsIpcProc
    command: ["qs", "ipc", "call", "settings", "showCategory", "display"]
  }

  // Sway-specific rotation
  Process {
    id: rotateProc
    property string outputName: ""
    property string transform: "normal"
    command: ["swaymsg", "output", outputName, "transform", transform]
    running: false
  }

  // Rotate a screen. degrees: 0, 90, 180, 270
  function setRotation(screen, degrees) {
    if (!screen) return
    var transform = "normal"
    if (degrees === 90) transform = "90"
    else if (degrees === 180) transform = "180"
    else if (degrees === 270) transform = "270"

    rotateProc.outputName = screen.name
    rotateProc.transform = transform
    rotateProc.running = true
  }

  // Track current rotation per screen (by name)
  property var rotations: ({})

  // Rotate 90 degrees clockwise each time
  function toggleRotation(screen) {
    if (!screen) return
    var current = rotations[screen.name] || 0
    var next = (current + 90) % 360
    rotations[screen.name] = next
    setRotation(screen, next)
  }
}
