pragma Singleton

import Quickshell

// Tracks whether any slide-in overlay (e.g. notification panel) is open.
// Modules call open()/close() to signal their state. shell.qml watches
// overlayOpen to deactivate bar focus without knowing which module is active.
Singleton {
  property bool overlayOpen: false

  function open() { overlayOpen = true }
  function close() { overlayOpen = false }
}
