import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "core/components"

Scope {
  id: root

  SettingsPanel {}
  // Floating notifications top-right
  NotificationPopups {}
  // Notifications history panel slide-in
  NotificationPanel {}

  // Module popups (PanelWindow-based, with click-outside and ESC support)
  VolumePopup {}
  BrightnessPopup {}
  DisplayPopup {}
  BluetoothPopup {}
  WirelessPopup {}
  UpdatesPopup {}

  // Pipewire tracking
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  // Makes the statusbar only appear on primary screen
  Variants {
    model: DisplayConfig.primaryScreen && StatusbarManager.ready ? [DisplayConfig.primaryScreen] : []

    PanelWindow {
      required property var modelData

      id: panel
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 32
      color: Colors.crust

      WlrLayershell.namespace: "quickshell-bar"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: barFocusActive
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      // Modules that use PanelWindow popups (referenced by focus mode and prop builder)
      property var popupModules: ["volume", "brightness", "display", "bluetooth", "wireless", "updates"]

      // Bar focus mode state
      property bool barFocusActive: false
      property int barFocusIndex: 0
      property var rightEnabledItems: StatusbarManager.rightItems.filter(function(i) { return i.enabled })

      // Modules to skip during keyboard navigation (they have their own keybinds)
      property var skipModules: ["notifications"]

      function isFocusable(index) {
        if (index < 0 || index >= rightEnabledItems.length) return false
        return skipModules.indexOf(rightEnabledItems[index].id) === -1
      }

      function nextFocusIndex(from) {
        for (var i = from + 1; i < rightEnabledItems.length; i++) {
          if (isFocusable(i)) return i
        }
        return from
      }

      function prevFocusIndex(from) {
        for (var i = from - 1; i >= 0; i--) {
          if (isFocusable(i)) return i
        }
        return from
      }

      function firstFocusIndex() {
        for (var i = 0; i < rightEnabledItems.length; i++) {
          if (isFocusable(i)) return i
        }
        return 0
      }

      // Clear barFocused on the previously focused segment when index changes
      onBarFocusIndexChanged: updateSegmentFocus()
      onBarFocusActiveChanged: updateSegmentFocus()

      function updateSegmentFocus() {
        for (var i = 0; i < rightEnabledItems.length; i++) {
          var delegate = rightRepeater.itemAt(i)
          if (!delegate) continue
          var wrapper = delegate.children[1]
          if (!wrapper) continue
          var loader = wrapper.children[0]
          if (!loader || !loader.item) continue

          // Only set barFocused on segments (they have the property, buttons don't)
          if (!ModuleRegistry.isButton(rightEnabledItems[i].id)
              && loader.item.hasOwnProperty("barFocused")) {
            loader.item.barFocused = barFocusActive && i === barFocusIndex
          }
        }
      }

      // Exit bar focus when a popup opens
      Connections {
        target: PopupManager
        function onActivePopupChanged() {
          if (PopupManager.activePopup !== "") {
            panel.barFocusActive = false
          }
        }
      }

      Connections {
        target: NotificationManager
        function onPanelOpenChanged() {
          if (NotificationManager.panelOpen) {
            panel.barFocusActive = false
          }
        }
      }

      // Keyboard handling for bar focus mode
      contentItem {
        focus: panel.barFocusActive

        Keys.onPressed: function(event) {
          if (!panel.barFocusActive) return

          // Escape or ctrl+[
          if (event.key === Qt.Key_Escape
              || (event.key === Qt.Key_BracketLeft && (event.modifiers & Qt.ControlModifier))) {
            panel.barFocusActive = false
            event.accepted = true
          } else if (event.key === Qt.Key_Space) {
            panel.activateFocusedItem()
            event.accepted = true
          } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
            panel.barFocusIndex = panel.nextFocusIndex(panel.barFocusIndex)
            event.accepted = true
          } else if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
            panel.barFocusIndex = panel.prevFocusIndex(panel.barFocusIndex)
            event.accepted = true
          }
        }
      }

      // Activate the currently focused bar item
      function activateFocusedItem() {
        if (barFocusIndex < 0 || barFocusIndex >= rightEnabledItems.length) return

        var item = rightEnabledItems[barFocusIndex]
        var moduleId = item.id

        // Compute anchor position from the Loader
        var delegate = rightRepeater.itemAt(barFocusIndex)
        var anchorRight = panel.width - 10
        if (delegate) {
          var wrapper = delegate.children[1]
          if (wrapper) {
            var mapped = wrapper.mapToItem(null, wrapper.width, 0)
            anchorRight = mapped.x
          }
        }

        if (panel.popupModules.indexOf(moduleId) !== -1) {
          PopupManager.toggle(moduleId, panel.modelData, anchorRight)
          return
        }

        // Segments with tooltips: toggle barFocused (tooltip shows reactively)
        // Space on a segment that already shows its tooltip just dismisses focus mode
        if (!ModuleRegistry.isButton(moduleId)) {
          barFocusActive = false
          return
        }
      }

      // IPC handler for bar focus mode
      IpcHandler {
        target: "bar"

        function toggle(): void {
          if (panel.barFocusActive) {
            panel.barFocusActive = false
          } else {
            panel.barFocusActive = true
            panel.barFocusIndex = panel.firstFocusIndex()
          }
        }
      }

      // Helper function to build props for dynamically loaded bar components.
      // Only pass singleton references to modules that need them to
      // avoid "non-existent property" warnings from Loader.setSource().
      function buildBarComponentProps(moduleId) {
        var props = { "screen": panel.modelData }
        if (popupModules.indexOf(moduleId) !== -1) {
          props.popupManager = PopupManager
        }
        if (moduleId === "notifications") {
          props.notificationManager = NotificationManager
        }
        return props
      }

      // Left section
      BarSection {
        anchors.left: parent.left
        anchors.leftMargin: StatusbarManager.barMargins.left
        spacing: StatusbarManager.sectionSpacing.left
        items: StatusbarManager.leftItems
        buildProps: panel.buildBarComponentProps
      }

      // Center section
      BarSection {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: StatusbarManager.sectionSpacing.center
        items: StatusbarManager.centerItems
        buildProps: panel.buildBarComponentProps
      }

      // Right section
      Row {
        anchors.right: parent.right
        anchors.rightMargin: StatusbarManager.barMargins.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: StatusbarManager.sectionSpacing.right

        Repeater {
          id: rightRepeater
          model: panel.rightEnabledItems

          Row {
            required property var modelData
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item { width: modelData.marginLeft; height: 1 }

            // Wrapper for Loader + focus highlight ring
            Item {
              width: loader.width
              height: loader.height
              anchors.verticalCenter: parent.verticalCenter

              Loader {
                id: loader
                anchors.verticalCenter: parent.verticalCenter

                Component.onCompleted: {
                  var url = ModuleRegistry.getBarComponentUrl(modelData.id)
                  if (url) {
                    setSource(url, panel.buildBarComponentProps(modelData.id))
                  }
                }
              }

              // Focus highlight ring (peach border, matching keyboard focus convention)
              Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 6
                color: "transparent"
                border.width: 2
                border.color: Colors.peach
                visible: panel.barFocusActive && index === panel.barFocusIndex
              }
            }

            Item { width: modelData.marginRight; height: 1 }
          }
        }
      }
    }
  }
}
