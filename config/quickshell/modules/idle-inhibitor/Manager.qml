pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: manager

  property bool inhibited: false

  function enable() {
    if (inhibited) return
    inhibited = true
    inhibitProc.running = true
  }

  function disable() {
    if (!inhibited) return
    inhibited = false
    if (inhibitProc.running) {
      inhibitProc.signal(15)
    }
  }

  function toggle() {
    if (inhibited) disable()
    else enable()
  }

  IpcHandler {
    target: "idle"

    function enable(): void { manager.enable() }
    function disable(): void { manager.disable() }
    function toggle(): void { manager.toggle() }
    function state(): bool { return manager.inhibited }
  }

  Process {
    id: inhibitProc
    command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
    running: false
    onExited: {
      manager.inhibited = false
    }
  }
}
