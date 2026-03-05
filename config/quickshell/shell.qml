import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "core/components"

Scope {
  id: root

  SettingsPanel {}

  // Dynamically load module popups and root components from manifests
  Connections {
    target: ModuleRegistry
    function onReadyChanged() {
      if (!ModuleRegistry.ready) return

      // Module popups (e.g. volume, bluetooth, wireless popup windows)
      var popups = ModuleRegistry.getPopupModules()
      for (var i = 0; i < popups.length; i++) {
        var popupPath = ModuleRegistry.getPopupRelPath(popups[i].id)
        var popupComp = Qt.createComponent(popupPath)
        if (popupComp.status === Component.Ready) {
          popupComp.createObject(root)
        } else {
          console.error("[shell] Failed to load popup:", popupPath, popupComp.errorString())
        }
      }

      // Root components (e.g. notification panel, notification popups)
      var rootComps = ModuleRegistry.getRootComponents()
      for (var j = 0; j < rootComps.length; j++) {
        var rootPath = ModuleRegistry.getRelPath(rootComps[j].module, rootComps[j].file)
        var rootComp = Qt.createComponent(rootPath)
        if (rootComp.status === Component.Ready) {
          rootComp.createObject(root)
        } else {
          console.error("[shell] Failed to load root component:", rootPath, rootComp.errorString())
        }
      }
    }
  }

  // Pipewire tracking
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  // Makes the statusbar only appear on primary screen
  Variants {
    model: ScreenManager.primaryScreen && StatusbarManager.ready ? [ScreenManager.primaryScreen] : []

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

      // Modules that use PanelWindow popups (derived from ModuleRegistry)
      property var popupModules: ModuleRegistry.ready ? ModuleRegistry.getPopupModuleIds() : []

      // Bar focus mode state (unified index across left, center, right sections)
      property bool barFocusActive: false
      property int barFocusIndex: 0

      // Enabled items per section
      property var leftEnabledItems: StatusbarManager.leftItems.filter(function(i) { return i.enabled })
      property var centerEnabledItems: StatusbarManager.centerItems.filter(function(i) { return i.enabled })
      property var rightEnabledItems: StatusbarManager.rightItems.filter(function(i) { return i.enabled })

      // Unified index offsets: [left 0..L-1] [center L..L+C-1] [right L+C..L+C+R-1]
      property int centerOffset: leftEnabledItems.length
      property int rightOffset: leftEnabledItems.length + centerEnabledItems.length
      property int totalFocusItems: leftEnabledItems.length + centerEnabledItems.length + rightEnabledItems.length

      // Modules to skip during keyboard navigation (declared via skipBarFocus in module.json)
      property var skipModules: ModuleRegistry.ready ? ModuleRegistry.getSkipBarFocusIds() : []

      // Resolve a unified index to its section and local index
      function resolveSection(idx) {
        if (idx < centerOffset) return { section: "left", localIndex: idx, items: leftEnabledItems }
        if (idx < rightOffset) return { section: "center", localIndex: idx - centerOffset, items: centerEnabledItems }
        return { section: "right", localIndex: idx - rightOffset, items: rightEnabledItems }
      }

      function isFocusable(idx) {
        if (idx < 0 || idx >= totalFocusItems) return false
        var resolved = resolveSection(idx)
        if (skipModules.indexOf(resolved.items[resolved.localIndex].id) !== -1) return false

        // Check delegate visibility
        if (resolved.section === "left") {
          var d = leftSection.repeater.itemAt(resolved.localIndex)
          return d && d.visible
        } else if (resolved.section === "center") {
          var d = centerSection.repeater.itemAt(resolved.localIndex)
          return d && d.visible
        } else {
          var d = rightRepeater.itemAt(resolved.localIndex)
          return d && d.visible
        }
      }

      function nextFocusIndex(from) {
        for (var i = from + 1; i < totalFocusItems; i++) {
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

      // Start at center, fall back to right, then left
      function firstFocusIndex() {
        for (var i = centerOffset; i < rightOffset; i++) {
          if (isFocusable(i)) return i
        }
        for (var i = rightOffset; i < totalFocusItems; i++) {
          if (isFocusable(i)) return i
        }
        for (var i = 0; i < centerOffset; i++) {
          if (isFocusable(i)) return i
        }
        return 0
      }

      // Update barFocused property on segments and focusLocalIndex on BarSections
      onBarFocusIndexChanged: updateSegmentFocus()
      onBarFocusActiveChanged: updateSegmentFocus()

      function updateSegmentFocus() {
        // Compute local focus indices for each BarSection
        var resolved = barFocusActive ? resolveSection(barFocusIndex) : null

        leftSection.focusLocalIndex = (resolved && resolved.section === "left") ? resolved.localIndex : -1
        centerSection.focusLocalIndex = (resolved && resolved.section === "center") ? resolved.localIndex : -1

        // Update barFocused on left section segments
        for (var i = 0; i < leftEnabledItems.length; i++) {
          var item = leftSection.itemAt(i)
          if (item && item.hasOwnProperty("barFocused")) {
            item.barFocused = barFocusActive && barFocusIndex === i
          }
        }

        // Update barFocused on center section segments
        for (var i = 0; i < centerEnabledItems.length; i++) {
          var item = centerSection.itemAt(i)
          if (item && item.hasOwnProperty("barFocused")) {
            item.barFocused = barFocusActive && barFocusIndex === (i + centerOffset)
          }
        }

        // Update barFocused on right section segments
        for (var i = 0; i < rightEnabledItems.length; i++) {
          var delegate = rightRepeater.itemAt(i)
          if (!delegate) continue
          var wrapper = delegate.children[1]
          if (!wrapper) continue
          var loader = wrapper.children[0]
          if (!loader || !loader.item) continue

          if (loader.item.hasOwnProperty("barFocused")) {
            loader.item.barFocused = barFocusActive && barFocusIndex === (i + rightOffset)
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

      // Exit bar focus when a slide-in overlay opens
      Connections {
        target: SlideInOverlayManager
        function onOverlayOpenChanged() {
          if (SlideInOverlayManager.overlayOpen) {
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
          } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            panel.activateFocusedItem()
            event.accepted = true
          } else if (event.key === Qt.Key_L) {
            panel.barFocusIndex = panel.nextFocusIndex(panel.barFocusIndex)
            event.accepted = true
          } else if (event.key === Qt.Key_H) {
            panel.barFocusIndex = panel.prevFocusIndex(panel.barFocusIndex)
            event.accepted = true
          }
        }
      }

      // Activate the currently focused bar item
      function activateFocusedItem() {
        if (barFocusIndex < 0 || barFocusIndex >= totalFocusItems) return

        var resolved = resolveSection(barFocusIndex)
        var moduleId = resolved.items[resolved.localIndex].id

        // Get the delegate and wrapper for anchor computation
        var wrapper = null
        if (resolved.section === "left") {
          var d = leftSection.repeater.itemAt(resolved.localIndex)
          if (d) wrapper = d.children[1]
        } else if (resolved.section === "center") {
          var d = centerSection.repeater.itemAt(resolved.localIndex)
          if (d) wrapper = d.children[1]
        } else {
          var d = rightRepeater.itemAt(resolved.localIndex)
          if (d) wrapper = d.children[1]
        }

        // Compute anchor position for popups
        var anchorRight = panel.width - 10
        if (wrapper) {
          var mapped = wrapper.mapToItem(null, wrapper.width, 0)
          anchorRight = mapped.x
        }

        if (panel.popupModules.indexOf(moduleId) !== -1) {
          PopupManager.toggle(moduleId, panel.modelData, anchorRight)
          return
        }

        // Buttons without popups: trigger their clicked signal directly
        if (ModuleRegistry.isButton(moduleId)) {
          if (wrapper) {
            var loader = wrapper.children[0]
            if (loader && loader.item && loader.item.clicked) {
              loader.item.clicked()
            }
          }
          return
        }

        // Segments: dismiss focus mode (tooltip already showing via barFocused)
        barFocusActive = false
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
        return props
      }

      // Left section
      BarSection {
        id: leftSection
        anchors.left: parent.left
        anchors.leftMargin: StatusbarManager.barMargins.left
        spacing: StatusbarManager.sectionSpacing.left
        items: StatusbarManager.leftItems
        buildProps: panel.buildBarComponentProps
      }

      // Center section
      BarSection {
        id: centerSection
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
            visible: !loader.item || (loader.item.showInBar !== undefined ? loader.item.showInBar : true)
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
                  var relPath = ModuleRegistry.getBarComponentRelPath(modelData.id)
                  if (relPath) {
                    setSource(relPath, panel.buildBarComponentProps(modelData.id))
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
                visible: panel.barFocusActive && (index + panel.rightOffset) === panel.barFocusIndex
              }
            }

            Item { width: modelData.marginRight; height: 1 }
          }
        }
      }
    }
  }
}
