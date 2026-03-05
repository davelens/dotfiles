import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import ".."
import "../core/components"

Scope {
  id: root

  property bool visible: false
  property string searchQuery: ""
  property string activeCategory: ""

  // Focus mode: "categories" or "content"
  property string focusMode: "categories"
  property var contentFocusables: []  // List of focusable items in current panel
  property int contentFocusIndex: -1  // Current focused item index in content

  // Sidebar profile button focus (-1 = none, 0 = New Profile, 1 = Switch Profile)
  property int sidebarProfileFocus: -1
  readonly property int profileButtonCount: GeneralSettings.profiles.length > 1 ? 2 : 1

  // Get categories from ModuleRegistry, sorted by GeneralSettings order.
  // Modules listed in settingsCategoryOrder come first (in that order),
  // unlisted modules follow sorted by their module.json order field.
  readonly property var categories: {
    if (!ModuleRegistry.ready || !GeneralSettings.ready) return []
    var all = ModuleRegistry.getSettingsModules()
    var order = GeneralSettings.settingsCategoryOrder
    var sorted = []
    for (var i = 0; i < order.length; i++) {
      for (var j = 0; j < all.length; j++) {
        if (all[j].id === order[i]) {
          sorted.push(all[j])
          break
        }
      }
    }
    for (var k = 0; k < all.length; k++) {
      if (order.indexOf(all[k].id) === -1) sorted.push(all[k])
    }
    return sorted
  }

  // Set default category when registry is ready
  onCategoriesChanged: {
    if (categories.length > 0 && !activeCategory) {
      activeCategory = categories[0].id
    }
  }

  // Clear search and reset focus when panel is hidden
  onVisibleChanged: {
    if (!visible) {
      searchQuery = ""
      focusMode = "categories"
      contentFocusIndex = -1
      sidebarProfileFocus = -1
      activeOverlay = ""
    }
  }

  // Reset content focus when category changes
  onActiveCategoryChanged: {
    contentFocusIndex = -1
    contentFocusables = []
  }

  // Filter categories based on search (matches name or keywords)
  function matchesSearch(category) {
    if (!searchQuery) return true
    var query = searchQuery.toLowerCase()
    return category.name.toLowerCase().indexOf(query) !== -1 ||
         (category.keywords && category.keywords.toLowerCase().indexOf(query) !== -1)
  }

  // Highlight matching text with yellow background
  function highlightText(text, query) {
    if (!query) return text
    var lowerText = text.toLowerCase()
    var lowerQuery = query.toLowerCase()
    var idx = lowerText.indexOf(lowerQuery)
    if (idx === -1) return text
    var before = text.substring(0, idx)
    var match = text.substring(idx, idx + query.length)
    var after = text.substring(idx + query.length)
    return before + '<span style="background-color: ' + Colors.yellow + '; color: ' + Colors.crust + ';">' + match + '</span>' + after
  }

  // Get visible categories (filtered by search)
  function getVisibleCategories() {
    return categories.filter(function(cat) { return matchesSearch(cat) })
  }

  // Select next category (cycles into profile buttons after last category)
  function selectNextCategory() {
    var visible = getVisibleCategories()

    // Currently on a profile button: advance or wrap to first category
    if (sidebarProfileFocus >= 0) {
      if (sidebarProfileFocus + 1 < profileButtonCount) {
        sidebarProfileFocus++
      } else {
        sidebarProfileFocus = -1
        if (visible.length > 0) activeCategory = visible[0].id
      }
      return
    }

    // On a category: advance or enter profile buttons
    if (visible.length === 0) {
      sidebarProfileFocus = 0
      return
    }
    var currentIndex = visible.findIndex(function(cat) { return cat.id === activeCategory })
    if (currentIndex === visible.length - 1) {
      sidebarProfileFocus = 0
    } else {
      var nextIndex = (currentIndex + 1) % visible.length
      activeCategory = visible[nextIndex].id
    }
  }

  // Select previous category (cycles into profile buttons before first category)
  function selectPreviousCategory() {
    var visible = getVisibleCategories()

    // Currently on a profile button: go back or return to last category
    if (sidebarProfileFocus >= 0) {
      if (sidebarProfileFocus > 0) {
        sidebarProfileFocus--
      } else {
        sidebarProfileFocus = -1
        if (visible.length > 0) activeCategory = visible[visible.length - 1].id
      }
      return
    }

    // On a category: go back or enter profile buttons from below
    if (visible.length === 0) {
      sidebarProfileFocus = profileButtonCount - 1
      return
    }
    var currentIndex = visible.findIndex(function(cat) { return cat.id === activeCategory })
    if (currentIndex === 0) {
      sidebarProfileFocus = profileButtonCount - 1
    } else {
      var prevIndex = (currentIndex - 1 + visible.length) % visible.length
      activeCategory = visible[prevIndex].id
    }
  }

  // Activate the focused profile button
  function activateProfileButton() {
    if (sidebarProfileFocus === 0) {
      sidebarProfileFocus = -1
      root.activeOverlay = "newProfile"
    } else if (sidebarProfileFocus === 1) {
      sidebarProfileFocus = -1
      root.activeOverlay = "switchProfile"
    }
  }

  // Reference to current content loader
  property var currentContentLoader: null

  // Find all focusable items in the current content
  function findFocusables(item, result) {
    if (!item) return
    if (item.showFocusRing !== undefined) {
      result.push(item)
    } else if (item.activeFocusOnTab === true) {
      result.push(item)
    }
    // Recurse into children
    if (item.children) {
      for (var i = 0; i < item.children.length; i++) {
        findFocusables(item.children[i], result)
      }
    }
    // Also check data (for Repeater items)
    if (item.contentItem) {
      findFocusables(item.contentItem, result)
    }
  }

  // Refresh the list of focusable items
  function refreshFocusables() {
    contentFocusables = []
    if (currentContentLoader && currentContentLoader.item) {
      findFocusables(currentContentLoader.item, contentFocusables)
    }
  }

  // Find the Flickable ancestor of an item (ScrollView's internal Flickable)
  function findFlickable(item) {
    var parent = item ? item.parent : null
    while (parent) {
      // Flickable has contentY and flick method
      if (parent.contentY !== undefined && parent.contentHeight !== undefined && parent.height !== undefined) {
        return parent
      }
      parent = parent.parent
    }
    return null
  }

  // Scroll to make an item visible
  function scrollToItem(item) {
    if (!item) return
    var flickable = findFlickable(item)
    if (!flickable) return

    // Map item position to flickable's content coordinates
    var mapped = item.mapToItem(flickable.contentItem, 0, 0)
    var itemTop = mapped.y
    var itemBottom = itemTop + item.height

    // Current visible area
    var visibleTop = flickable.contentY
    var visibleBottom = visibleTop + flickable.height

    // Add padding for focus ring
    var padding = 24

    // Scroll if item is outside visible area
    if (itemTop - padding < visibleTop) {
      // Item is above visible area - scroll up
      flickable.contentY = Math.max(0, itemTop - padding)
    } else if (itemBottom + padding > visibleBottom) {
      // Item is below visible area - scroll down
      flickable.contentY = Math.min(
        flickable.contentHeight - flickable.height,
        itemBottom + padding - flickable.height
      )
    }
  }

  // Focus an item via keyboard (sets keyboardFocus flag and scrolls to it)
  function focusItemViaKeyboard(item) {
    if (item) {
      if (item.keyboardFocus !== undefined) item.keyboardFocus = true
      if (item.forceActiveFocus) item.forceActiveFocus()
      scrollToItem(item)
    }
  }

  // Focus next item in content
  function focusNextContent() {
    refreshFocusables()
    if (contentFocusables.length === 0) return
    contentFocusIndex = (contentFocusIndex + 1) % contentFocusables.length
    focusItemViaKeyboard(contentFocusables[contentFocusIndex])
  }

  // Focus previous item in content
  function focusPreviousContent() {
    refreshFocusables()
    if (contentFocusables.length === 0) return
    if (contentFocusIndex < 0) contentFocusIndex = contentFocusables.length - 1
    else contentFocusIndex = (contentFocusIndex - 1 + contentFocusables.length) % contentFocusables.length
    focusItemViaKeyboard(contentFocusables[contentFocusIndex])
  }

  // Enter content focus mode
  function enterContentMode() {
    focusMode = "content"
    sidebarProfileFocus = -1
    refreshFocusables()
    // Re-enable focus rings on all content items
    for (var i = 0; i < contentFocusables.length; i++) {
      var item = contentFocusables[i]
      if (item && item.showFocusRing !== undefined) {
        item.showFocusRing = true
      }
    }
    contentFocusIndex = -1
    // Focus first item if available
    if (contentFocusables.length > 0) {
      contentFocusIndex = 0
      focusItemViaKeyboard(contentFocusables[0])
    }
  }

  // Return to category focus mode
  function enterCategoryMode() {
    focusMode = "categories"
    sidebarProfileFocus = -1
    // Hide focus rings on all content items
    for (var i = 0; i < contentFocusables.length; i++) {
      var item = contentFocusables[i]
      if (item && item.showFocusRing !== undefined) {
        item.showFocusRing = false
      }
    }
    contentFocusIndex = -1
    // Return focus to panel root
    if (panelRoot) panelRoot.forceActiveFocus()
  }

  // Reference to panel root for focus management
  property var panelRoot: null

  // Reference to search input
  property var searchInputRef: null

  // Focus the search input
  function focusSearch() {
    if (searchInputRef) {
      searchInputRef.forceActiveFocus()
    }
  }

  // Get the settings component path for a category (relative to core/components/)
  function getSettingsUrl(categoryId) {
    var module = ModuleRegistry.getModule(categoryId)
    if (module && module.components && module.components.settings) {
      return "../" + ModuleRegistry.getSettingsRelPath(categoryId)
    }
    return ""
  }

  // Which overlay is showing: "", "switchProfile", or "newProfile"
  property string activeOverlay: ""

  // IPC handler to toggle visibility
  IpcHandler {
    target: "settings"

    function toggle(): void { root.visible = !root.visible }
    function show(): void { root.visible = true }
    function hide(): void { root.visible = false }
    function showCategory(categoryId: string): void {
      root.activeCategory = categoryId
      root.visible = true
    }
  }

  // Full-screen overlay with centered panel
  Variants {
    model: root.visible && ScreenManager.primaryScreen ? [ScreenManager.primaryScreen] : []

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
        bottom: true
      }

      color: "#80000000"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-settings"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      // Handle keyboard input
      contentItem {
        id: panelRootItem
        focus: true
        Component.onCompleted: root.panelRoot = panelRootItem
        Keys.onPressed: event => {
          // Ctrl+[: close overlay, blur search, or close panel (in that order)
          if (event.key === Qt.Key_BracketLeft && (event.modifiers & Qt.ControlModifier)) {
            if (root.activeOverlay !== "") {
              root.activeOverlay = ""
            } else if (root.searchInputRef && root.searchInputRef.activeFocus) {
              panelRootItem.forceActiveFocus()
            } else {
              root.visible = false
            }
            event.accepted = true
          }
          // Q or Escape: close overlay first, then settings
          else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
            if (root.activeOverlay !== "") {
              root.activeOverlay = ""
            } else {
              root.visible = false
            }
            event.accepted = true
          }
          // Ctrl+L: enter content mode (focus panel content)
          else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
            root.enterContentMode()
            event.accepted = true
          }
          // Ctrl+H: return to category mode
          else if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
            root.enterCategoryMode()
            event.accepted = true
          }
          // Ctrl+N: next (category or content item depending on mode)
          else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
            if (root.focusMode === "categories") {
              root.selectNextCategory()
            } else {
              root.focusNextContent()
            }
            event.accepted = true
          }
          // Ctrl+P: previous (category or content item depending on mode)
          else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
            if (root.focusMode === "categories") {
              root.selectPreviousCategory()
            } else {
              root.focusPreviousContent()
            }
            event.accepted = true
          }
          // Ctrl+F: focus search input
          else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            root.focusSearch()
            event.accepted = true
          }
          // Enter/Space: activate focused profile button (category mode only)
          else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                    && root.focusMode === "categories" && root.sidebarProfileFocus >= 0) {
            root.activateProfileButton()
            event.accepted = true
          }
        }
      }

      // Click outside to close
      MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
      }

      // Centered panel
      Rectangle {
        id: panel
        anchors.centerIn: parent
        width: parent.width * 0.6
        height: parent.height * 0.7
        color: Colors.base
        radius: 8

        // Prevent clicks inside panel from closing
        MouseArea {
          anchors.fill: parent
          onClicked: {} // absorb click
        }

        // Border
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          border.width: 1
          border.color: Colors.surface2
          radius: parent.radius
          z: 100
        }

        // Main layout
        Column {
          anchors.fill: parent

          // Search bar
          Rectangle {
            width: parent.width
            height: 56
            color: Colors.mantle
            radius: 8

            // Cover bottom corners
            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: 8
              color: Colors.mantle
            }

            Row {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 12

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍉"
                color: Colors.overlay0
                font.pixelSize: 18
                font.family: "Symbols Nerd Font"
              }

              TextInput {
                id: searchInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40
                color: Colors.text
                font.pixelSize: 14
                clip: true
                focus: true
                Component.onCompleted: root.searchInputRef = searchInput

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.IBeamCursor
                  onClicked: searchInput.forceActiveFocus()
                }

                Text {
                  anchors.fill: parent
                  text: "Search settings..."
                  color: Colors.overlay0
                  font.pixelSize: 14
                  visible: !searchInput.text && !searchInput.activeFocus
                }

                onTextChanged: root.searchQuery = text
              }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: 1
              color: Colors.surface0
            }
          }

          // Content area
          Row {
            width: parent.width
            height: parent.height - 56

            // Sidebar
            Rectangle {
              id: sidebar
              width: 200
              height: parent.height
              color: root.focusMode === "categories" ? Colors.base : Colors.mantle
              Behavior on color { ColorAnimation { duration: 150 } }

              // Cover bottom-left corner
              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: 8
                height: 8
                color: sidebar.color
                radius: 8

                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  width: 8
                  height: 8
                  color: sidebar.color
                }
              }

              Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 8
                spacing: 2

                Repeater {
                  model: root.categories

                  Rectangle {
                    required property var modelData
                    required property int index

                    width: sidebar.width
                    height: visible ? 44 : 0
                    visible: root.matchesSearch(modelData)
                    color: root.activeCategory === modelData.id ? Colors.surface0 :
                         categoryArea.containsMouse ? Colors.surface0 : "transparent"

                    Rectangle {
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      width: 3
                      height: 24
                      radius: 2
                      color: Colors.blue
                      visible: root.activeCategory === modelData.id
                    }

                    Row {
                      anchors.left: parent.left
                      anchors.leftMargin: 16
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 12

                      Text {
                        width: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        color: root.activeCategory === modelData.id ? Colors.blue : Colors.text
                        font.pixelSize: 16
                        font.family: "Symbols Nerd Font"
                        horizontalAlignment: Text.AlignHCenter
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: root.activeCategory === modelData.id ? Colors.text : Colors.subtext0
                        font.pixelSize: 14
                      }
                    }

                    MouseArea {
                      id: categoryArea
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.sidebarProfileFocus = -1
                        root.activeCategory = modelData.id
                      }
                    }
                  }
                }
              }

              // Profile buttons
              Column {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 6

                // Active profile indicator
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Profile: " + GeneralSettings.activeProfileName
                  color: Colors.subtext0
                  font.pixelSize: 11
                  visible: GeneralSettings.activeProfileName !== ""
                }

                Item {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: 36

                  FocusButton {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32
                    text: "New Profile"
                    fontSize: 12
                    backgroundColor: Colors.surface0
                    hoverColor: Colors.surface1
                    onClicked: root.activeOverlay = "newProfile"
                  }

                  Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 6
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.peach
                    visible: root.sidebarProfileFocus === 0
                  }
                }

                Item {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: 36
                  visible: GeneralSettings.profiles.length > 1

                  FocusButton {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32
                    text: "Switch Profile"
                    fontSize: 12
                    backgroundColor: Colors.surface0
                    hoverColor: Colors.surface1
                    onClicked: root.activeOverlay = "switchProfile"
                  }

                  Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 6
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.peach
                    visible: root.sidebarProfileFocus === 1
                  }
                }
              }

              Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Colors.surface0
              }
            }

            // Main content
            Rectangle {
              id: contentArea
              width: parent.width - sidebar.width
              height: parent.height
              color: root.focusMode === "content" ? Colors.base : Colors.mantle
              Behavior on color { ColorAnimation { duration: 150 } }
              radius: 8

              // Only round bottom-right
              Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: parent.radius
                color: contentArea.color
              }
              Rectangle {
                anchors.left: parent.left
                width: parent.radius
                height: parent.height
                color: contentArea.color
              }

              // Dynamic content loader
              Loader {
                id: contentLoader
                anchors.fill: parent
                anchors.margins: 24
                source: root.getSettingsUrl(root.activeCategory)
                onLoaded: {
                  root.currentContentLoader = contentLoader
                  // Pass searchQuery to the loaded component
                  if (item && item.searchQuery !== undefined) {
                    item.searchQuery = Qt.binding(function() { return root.searchQuery })
                  }
                }
              }

              // Fallback when no module is selected or found
              Text {
                anchors.centerIn: parent
                text: ModuleRegistry.ready ? "Select a category" : "Loading modules..."
                color: Colors.overlay0
                font.pixelSize: 14
                visible: !contentLoader.source || contentLoader.status !== Loader.Ready
              }
            }
          }
        }

        // Profile overlay (scrim + content, fills the panel)
        Rectangle {
          anchors.fill: parent
          color: "#80000000"
          radius: parent.radius
          visible: root.activeOverlay !== ""
          z: 200

          MouseArea {
            anchors.fill: parent
            onClicked: root.activeOverlay = ""
          }

          Loader {
            id: overlayLoader
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
            source: {
              if (root.activeOverlay === "switchProfile") return "SwitchProfileDialog.qml"
              if (root.activeOverlay === "newProfile") return "NewProfileDialog.qml"
              return ""
            }
            onLoaded: {
              if (item && item.closeRequested) {
                item.closeRequested.connect(function() { root.activeOverlay = "" })
              }
            }
          }
        }
      }
    }
  }
}
