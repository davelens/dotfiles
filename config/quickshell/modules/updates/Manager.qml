pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: manager

  // Package update lists
  // Each item: { name: string, currentVersion: string, newVersion: string, source: string }
  property var pacmanUpdates: []
  property var aurUpdates: []
  // Flatpak items also have appId
  property var flatpakUpdates: []

  // Total count across all sources
  readonly property int totalCount: pacmanCount + aurCount + flatpakCount
  property int pacmanCount: 0
  property int aurCount: 0
  property int flatpakCount: 0

  // Whether a check is currently running
  property bool checking: false

  // System update in progress (paru -Syu). Blocks all other update actions.
  property bool systemUpdating: false

  // Set of package names currently being updated individually
  property var updatingPackages: ({})

  // Whether any blocking operation is running
  readonly property bool blocked: systemUpdating

  // Icons
  readonly property string iconError: "󰒑"
  readonly property string iconUpToDate: "󰸟"
  readonly property string iconHasUpdates: "󰄠"
  readonly property string iconDownload: "󰇚"

  function getIcon() {
    if (checking) return iconHasUpdates
    if (totalCount > 0) return iconHasUpdates
    return iconUpToDate
  }

  // Check if a specific package is currently being updated
  function isUpdating(name) {
    return updatingPackages[name] === true
  }

  // Start checking all sources
  function checkUpdates() {
    if (checking) return
    checking = true
    checkPacmanProc.running = true
  }

  // Update a single package
  function updatePackage(name, source) {
    if (systemUpdating || isUpdating(name)) return

    var pkgs = Object.assign({}, updatingPackages)
    pkgs[name] = true
    updatingPackages = pkgs

    if (source === "flatpak") {
      singleUpdateHelper.start(["flatpak", "update", "-y", name], name)
    } else if (source === "aur") {
      singleUpdateHelper.start(["paru", "-S", "--needed", "--noconfirm", name], name)
    } else {
      singleUpdateHelper.start(["bash", "-c", "sudo pacman -Sy && sudo pacman -S --needed --noconfirm " + name], name)
    }
  }

  // Update all packages in a specific source
  function updateSource(source) {
    if (systemUpdating) return

    if (source === "pacman") {
      if (pacmanUpdates.length === 0) return
      sourceUpdateProc.source = source
      var names = pacmanUpdates.map(function(p) { return p.name }).join(" ")
      sourceUpdateProc.command = ["bash", "-c", "sudo pacman -Sy && sudo pacman -S --needed --noconfirm " + names]
      // Mark all pacman packages as updating
      var pkgs = Object.assign({}, updatingPackages)
      for (var i = 0; i < pacmanUpdates.length; i++) pkgs[pacmanUpdates[i].name] = true
      updatingPackages = pkgs
      sourceUpdateProc.running = true
    } else if (source === "aur") {
      if (aurUpdates.length === 0) return
      sourceUpdateProc.source = source
      sourceUpdateProc.command = ["paru", "-S", "--needed", "--noconfirm"].concat(
        aurUpdates.map(function(p) { return p.name })
      )
      var aurPkgs = Object.assign({}, updatingPackages)
      for (var j = 0; j < aurUpdates.length; j++) aurPkgs[aurUpdates[j].name] = true
      updatingPackages = aurPkgs
      sourceUpdateProc.running = true
    } else if (source === "flatpak") {
      if (flatpakUpdates.length === 0) return
      sourceUpdateProc.source = source
      sourceUpdateProc.command = ["flatpak", "update", "-y"]
      var fpPkgs = Object.assign({}, updatingPackages)
      for (var k = 0; k < flatpakUpdates.length; k++) fpPkgs[flatpakUpdates[k].name] = true
      updatingPackages = fpPkgs
      sourceUpdateProc.running = true
    }
  }

  // Full system update (paru -Syu). Blocks everything.
  function systemUpdate() {
    if (systemUpdating) return
    systemUpdating = true
    systemUpdateProc.command = ["paru", "-Syu", "--noconfirm"]
    systemUpdateProc.running = true
  }

  function onSystemUpdateComplete(success) {
    systemUpdating = false
    updatingPackages = {}
    if (success) {
      notifyProc.command = ["notify-send", "System Updates", "System update completed successfully", "-i", "package-install"]
    } else {
      notifyProc.command = ["notify-send", "System Updates", "System update failed", "-i", "dialog-error"]
    }
    notifyProc.running = true
    recheckTimer.restart()
  }

  // Helper object to manage concurrent single-package updates.
  // Uses a queue since Process can only run one command at a time.
  QtObject {
    id: singleUpdateHelper
    property var queue: []
    property bool busy: false

    function start(cmd, pkgName) {
      queue.push({ command: cmd, name: pkgName })
      processNext()
    }

    function processNext() {
      if (busy || queue.length === 0) return
      busy = true
      var item = queue.shift()
      singleProc.pkgName = item.name
      singleProc.command = item.command
      singleProc.running = true
    }

    function onFinished(pkgName, exitCode) {
      busy = false
      // Remove from updatingPackages
      var pkgs = Object.assign({}, manager.updatingPackages)
      delete pkgs[pkgName]
      manager.updatingPackages = pkgs

      if (exitCode === 0) {
        notifyProc.command = ["notify-send", "System Updates", "Updated " + pkgName, "-i", "package-install"]
      } else {
        notifyProc.command = ["notify-send", "System Updates", "Failed to update " + pkgName, "-i", "dialog-error"]
      }
      notifyProc.running = true

      // Process next in queue, or re-check if queue is empty
      if (queue.length > 0) {
        processNext()
      } else {
        recheckTimer.restart()
      }
    }
  }

  // Check for pacman updates
  Process {
    id: checkPacmanProc
    command: ["checkupdates"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => checkPacmanProc.output += data + "\n"
    }
    onExited: exitCode => {
      if (exitCode === 0) {
        var lines = checkPacmanProc.output.trim().split("\n").filter(l => l.length > 0)
        var updates = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(" ")
          if (parts.length >= 4) {
            updates.push({
              name: parts[0],
              currentVersion: parts[1],
              newVersion: parts[3],
              source: "pacman"
            })
          }
        }
        manager.pacmanUpdates = updates
        manager.pacmanCount = updates.length
      } else {
        manager.pacmanUpdates = []
        manager.pacmanCount = 0
      }
      checkAurProc.running = true
    }
  }

  // Check for AUR updates
  Process {
    id: checkAurProc
    command: ["paru", "-Qua"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => checkAurProc.output += data + "\n"
    }
    onExited: exitCode => {
      if (exitCode === 0) {
        var lines = checkAurProc.output.trim().split("\n").filter(l => l.length > 0)
        var updates = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(" ")
          if (parts.length >= 4) {
            updates.push({
              name: parts[0],
              currentVersion: parts[1],
              newVersion: parts[3],
              source: "aur"
            })
          }
        }
        manager.aurUpdates = updates
        manager.aurCount = updates.length
      } else {
        manager.aurUpdates = []
        manager.aurCount = 0
      }
      checkFlatpakProc.running = true
    }
  }

  // Check for flatpak updates
  Process {
    id: checkFlatpakProc
    command: ["flatpak", "remote-ls", "--updates", "--columns=name,application,version"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => checkFlatpakProc.output += data + "\n"
    }
    onExited: exitCode => {
      if (exitCode === 0) {
        var lines = checkFlatpakProc.output.trim().split("\n").filter(l => l.length > 0)
        var updates = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length >= 2) {
            updates.push({
              name: parts[0].trim(),
              appId: parts.length >= 2 ? parts[1].trim() : parts[0].trim(),
              currentVersion: "",
              newVersion: parts.length >= 3 ? parts[2].trim() : "",
              source: "flatpak"
            })
          }
        }
        manager.flatpakUpdates = updates
        manager.flatpakCount = updates.length
      } else {
        manager.flatpakUpdates = []
        manager.flatpakCount = 0
      }
      manager.checking = false
    }
  }

  // Single package update process (sequential queue)
  Process {
    id: singleProc
    property string pkgName: ""
    onExited: exitCode => singleUpdateHelper.onFinished(pkgName, exitCode)
  }

  // Source-level update process (update all in one source)
  Process {
    id: sourceUpdateProc
    property string source: ""
    onExited: exitCode => {
      // Clear all updating flags for this source
      var pkgs = Object.assign({}, manager.updatingPackages)
      var list = source === "pacman" ? manager.pacmanUpdates
                : source === "aur" ? manager.aurUpdates
                : manager.flatpakUpdates
      for (var i = 0; i < list.length; i++) {
        delete pkgs[list[i].name]
      }
      manager.updatingPackages = pkgs

      if (exitCode === 0) {
        notifyProc.command = ["notify-send", "System Updates", "Updated all " + source + " packages", "-i", "package-install"]
      } else {
        notifyProc.command = ["notify-send", "System Updates", "Failed to update " + source + " packages", "-i", "dialog-error"]
      }
      notifyProc.running = true
      recheckTimer.restart()
    }
  }

  // System update process (paru -Syu)
  Process {
    id: systemUpdateProc
    onExited: exitCode => manager.onSystemUpdateComplete(exitCode === 0)
  }

  // Notification process
  Process {
    id: notifyProc
  }

  // Re-check after updates complete
  Timer {
    id: recheckTimer
    interval: 3000
    onTriggered: manager.checkUpdates()
  }

  // Check on startup (small delay)
  Timer {
    interval: 5000
    running: true
    onTriggered: manager.checkUpdates()
  }

  // Periodic check every hour
  Timer {
    interval: 3600000
    running: true
    repeat: true
    onTriggered: manager.checkUpdates()
  }
}
