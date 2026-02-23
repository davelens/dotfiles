pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
  id: popupManager

  // Current active popup: "", "volume", "brightness", "display", "bluetooth", "wireless"
  property string activePopup: ""

  // Screen that opened the popup
  property var activePopupScreen: null

  // Anchor position for popup placement (screen-space X of the button's right edge)
  property real anchorRight: 0

  // Volume popup expansion state
  property bool outputDevicesExpanded: false
  property bool inputDevicesExpanded: false

  // Stored anchor positions per popup (for IPC toggle without a button click)
  property var storedAnchors: ({})

  function toggle(name: string, screen: var, buttonRight: real): void {
    if (activePopup === name && activePopupScreen === screen) {
      close()
    } else {
      activePopup = name
      activePopupScreen = screen
      anchorRight = buttonRight
      outputDevicesExpanded = false
      inputDevicesExpanded = false

      // Store anchor for future IPC toggles
      var anchors = storedAnchors
      anchors[name] = { screen: screen, right: buttonRight }
      storedAnchors = anchors
    }
  }

  function close(): void {
    activePopup = ""
    activePopupScreen = null
    outputDevicesExpanded = false
    inputDevicesExpanded = false
  }

  function isOpen(name: string): bool {
    return activePopup === name
  }

  // IPC handler for external control (e.g. qs ipc call popup toggle volume)
  IpcHandler {
    target: "popup"

    function toggle(name: string): void {
      if (popupManager.activePopup === name) {
        popupManager.close()
      } else {
        // Use stored anchor position if available, otherwise fall back to screen edge
        var stored = popupManager.storedAnchors[name]
        if (stored) {
          popupManager.activePopup = name
          popupManager.activePopupScreen = stored.screen
          popupManager.anchorRight = stored.right
        } else if (DisplayConfig.primaryScreen) {
          popupManager.activePopup = name
          popupManager.activePopupScreen = DisplayConfig.primaryScreen
          popupManager.anchorRight = DisplayConfig.primaryScreen.width - 10
        }
        popupManager.outputDevicesExpanded = false
        popupManager.inputDevicesExpanded = false
      }
    }

    function close(): void { popupManager.close() }
  }
}
