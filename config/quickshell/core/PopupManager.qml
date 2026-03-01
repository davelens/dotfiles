pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
  id: popupManager

  property string activePopup: ""

  // Screen that opened the popup
  property var activePopupScreen: null

  // Anchor position for popup placement (screen-space X of the button's right edge)
  property real anchorRight: 0

  // Registered button references per popup (for IPC toggle anchor computation)
  property var registeredButtons: ({})

  // Legacy stored anchors (kept as fallback)
  property var storedAnchors: ({})

  // Register a button for a popup (called from BarButton)
  function registerButton(name: string, buttonRef: var): void {
    var buttons = Object.assign({}, registeredButtons)
    buttons[name] = buttonRef
    registeredButtons = buttons
  }

  // Compute anchor position from a registered button
  function getButtonAnchor(name: string): var {
    var btn = registeredButtons[name]
    if (btn && btn.screen) {
      var mapped = btn.mapToItem(null, btn.width, 0)
      if (mapped.x > btn.width) {
        return { screen: btn.screen, right: mapped.x }
      }
    }
    return null
  }

  function toggle(name: string, screen: var, buttonRight: real): void {
    if (activePopup === name && activePopupScreen === screen) {
      close()
    } else {
      activePopup = name
      activePopupScreen = screen
      anchorRight = buttonRight
    }
  }

  function close(): void {
    activePopup = ""
    activePopupScreen = null
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
        // Compute anchor from the registered button at toggle time
        var anchor = popupManager.getButtonAnchor(name)
        if (anchor) {
          popupManager.activePopup = name
          popupManager.activePopupScreen = anchor.screen
          popupManager.anchorRight = anchor.right
        } else if (DisplayConfig.primaryScreen) {
          popupManager.activePopup = name
          popupManager.activePopupScreen = DisplayConfig.primaryScreen
          popupManager.anchorRight = DisplayConfig.primaryScreen.width - 10
        }
      }
    }

    function close(): void { popupManager.close() }
  }
}
