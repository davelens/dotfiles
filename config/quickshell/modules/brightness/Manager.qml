pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: brightnessManager

  // =========================================================================
  // PUBLIC STATE
  // =========================================================================

  // List of detected displays with brightness info
  // Each: { id: string, name: string, type: "backlight"|"ddc", brightness: real, deviceId: any }
  property var displays: []

  // True while user is adjusting (prevents refresh from overwriting)
  property bool userAdjusting: false

  // Average brightness for bar icon
  readonly property real averageLevel: {
    if (displays.length === 0) return 0.5
    var total = 0
    for (var i = 0; i < displays.length; i++) {
      total += displays[i].brightness
    }
    return total / displays.length
  }

  // Pause refresh when popup is open
  property bool popupOpen: false

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  function setBrightness(displayId, level) {
    userAdjusting = true

    for (var j = 0; j < displays.length; j++) {
      if (displays[j].id === displayId) {
        var display = displays[j]
        var percent = Math.round(level * 100)
        if (display.type === "backlight") {
          backlightSetProc.device = display.deviceId
          backlightSetProc.targetPercent = percent
          backlightSetProc.running = true
        } else if (display.type === "ddc") {
          ddcSetProc.displayNum = display.deviceId
          ddcSetProc.targetPercent = percent
          ddcSetProc.running = true
        }
        break
      }
    }

    settleTimer.restart()
  }

  function getIcon(level) {
    if (level < 0.25) return "󰃞"
    if (level < 0.5) return "󰃟"
    if (level < 0.75) return "󰃠"
    return "󰃡"
  }

  function refresh() {
    backlightReadProc.running = true
    ddcDetectProc.running = true
  }

  // =========================================================================
  // INTERNAL STATE
  // =========================================================================

  property var ddcDisplays: []

  // =========================================================================
  // BACKLIGHT (laptop panels)
  // =========================================================================

  Process {
    id: backlightReadProc
    command: ["brightnessctl", "-m", "-c", "backlight"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        if (brightnessManager.userAdjusting) return
        // Format: device,class,current,percentage%,max
        var parts = data.trim().split(",")
        if (parts.length >= 5 && parts[1] === "backlight") {
          var deviceName = parts[0]
          var current = parseInt(parts[2])
          var max = parseInt(parts[4])
          if (max > 0) {
            var brightness = current / max
            brightnessManager.updateDisplay("backlight-" + deviceName, "Built-in Display", "backlight", brightness, deviceName)
          }
        }
      }
    }
    onExited: exitCode => {
      if (exitCode !== 0) {
        brightnessManager.removeDisplaysByType("backlight")
      }
    }
  }

  Process {
    id: backlightSetProc
    property string device: ""
    property int targetPercent: 50
    command: ["brightnessctl", "-d", device, "set", targetPercent + "%"]
    running: false
  }

  // =========================================================================
  // DDC (external monitors)
  // =========================================================================

  Process {
    id: ddcDetectProc
    command: ["ddcutil", "detect", "--brief"]
    running: true
    property var foundDisplays: []
    onStarted: foundDisplays = []
    stdout: SplitParser {
      onRead: data => {
        var match = data.match(/^\s*Display\s+(\d+)/)
        if (match) {
          ddcDetectProc.foundDisplays.push(parseInt(match[1]))
        }
      }
    }
    onExited: exitCode => {
      brightnessManager.ddcDisplays = foundDisplays
      brightnessManager.removeStaleDisplays()
      for (var i = 0; i < foundDisplays.length; i++) {
        brightnessManager.readDdcBrightness(foundDisplays[i])
      }
    }
  }

  function readDdcBrightness(displayNum) {
    ddcReadProc.displayNum = displayNum
    ddcReadProc.running = true
  }

  Process {
    id: ddcReadProc
    property int displayNum: 1
    property bool foundDisplay: false
    property real detectedBrightness: 0
    command: ["ddcutil", "getvcp", "10", "--display", displayNum.toString(), "--brief"]
    running: false
    onStarted: {
      foundDisplay = false
      detectedBrightness = 0
    }
    stdout: SplitParser {
      onRead: data => {
        if (brightnessManager.userAdjusting) return
        var parts = data.trim().split(/\s+/)
        if (parts.length >= 5 && parts[0] === "VCP") {
          var current = parseInt(parts[3])
          var max = parseInt(parts[4])
          if (max > 0) {
            ddcReadProc.detectedBrightness = current / max
            ddcReadProc.foundDisplay = true
          }
        }
      }
    }
    onExited: exitCode => {
      if (exitCode === 0 && foundDisplay) {
        var name = "External Monitor" + (brightnessManager.ddcDisplays.length > 1 ? " " + displayNum : "")
        brightnessManager.updateDisplay("ddc-" + displayNum, name, "ddc", detectedBrightness, displayNum)
      } else {
        brightnessManager.removeDisplay("ddc-" + displayNum)
      }
    }
  }

  Process {
    id: ddcSetProc
    property int displayNum: 1
    property int targetPercent: 50
    command: ["ddcutil", "setvcp", "10", targetPercent.toString(), "--display", displayNum.toString()]
    running: false
  }

  // =========================================================================
  // TIMERS
  // =========================================================================

  Timer {
    id: settleTimer
    interval: 1000
    onTriggered: brightnessManager.userAdjusting = false
  }

  Timer {
    id: refreshTimer
    interval: 5000
    running: !brightnessManager.popupOpen
    repeat: true
    onTriggered: brightnessManager.refresh()
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  function updateDisplay(id, name, type, brightness, deviceId) {
    var newDisplays = displays.slice()
    var found = false
    for (var i = 0; i < newDisplays.length; i++) {
      if (newDisplays[i].id === id) {
        newDisplays[i] = { id: id, name: name, type: type, brightness: brightness, deviceId: deviceId }
        found = true
        break
      }
    }
    if (!found) {
      newDisplays.push({ id: id, name: name, type: type, brightness: brightness, deviceId: deviceId })
    }
    displays = newDisplays
  }

  function removeDisplay(id) {
    var newDisplays = []
    for (var i = 0; i < displays.length; i++) {
      if (displays[i].id !== id) {
        newDisplays.push(displays[i])
      }
    }
    displays = newDisplays
  }

  function removeDisplaysByType(type) {
    var newDisplays = []
    for (var i = 0; i < displays.length; i++) {
      if (displays[i].type !== type) {
        newDisplays.push(displays[i])
      }
    }
    displays = newDisplays
  }

  function removeStaleDisplays() {
    var newDisplays = []
    for (var i = 0; i < displays.length; i++) {
      var d = displays[i]
      if (d.type !== "ddc") {
        newDisplays.push(d)
      } else {
        var stillExists = false
        for (var j = 0; j < ddcDisplays.length; j++) {
          if (d.deviceId === ddcDisplays[j]) {
            stillExists = true
            break
          }
        }
        if (stillExists) {
          newDisplays.push(d)
        }
      }
    }
    displays = newDisplays
  }
}
