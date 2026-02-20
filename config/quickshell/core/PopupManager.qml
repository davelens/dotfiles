pragma Singleton
import QtQuick
import Quickshell

QtObject {
  // Current active popup: "", "volume", "brightness", "display"
  property string activePopup: ""

  // Screen that opened the popup
  property var activePopupScreen: null

  // Volume popup expansion state
  property bool outputDevicesExpanded: false
  property bool inputDevicesExpanded: false

  function toggle(name: string, screen: var): void {
    if (activePopup === name && activePopupScreen === screen) {
      close()
    } else {
      activePopup = name
      activePopupScreen = screen
      outputDevicesExpanded = false
      inputDevicesExpanded = false
    }
  }

  function close(): void {
    activePopup = ""
    activePopupScreen = null
    outputDevicesExpanded = false
    inputDevicesExpanded = false
  }

  function isOpen(name: string, screen: var): bool {
    return activePopup === name && activePopupScreen === screen
  }
}
