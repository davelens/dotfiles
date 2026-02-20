pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: manager

  // Whether config has loaded
  property bool ready: false

  // Bar margins (left/right edge padding)
  property var barMargins: ({ left: 4, right: 10 })

  // Section spacing (between items in each section)
  property var sectionSpacing: ({ left: 0, center: 0, right: 0 })

  // Items in each section
  property var leftItems: []
  property var centerItems: []
  property var rightItems: []

  // Path to config file
  readonly property string configPath: DataManager.statusbarPath
  readonly property string defaultsPath: DataManager.defaultsDir + "/statusbar.json"

  // Track if we should reload when ModuleRegistry becomes ready
  property bool pendingReload: false
  property string pendingConfig: ""

  // Load config when DataManager is ready
  Connections {
    target: DataManager
    function onReadyChanged() {
      if (DataManager.ready) {
        configFile.blockLoading = false
      }
    }
  }

  // Reload items when ModuleRegistry becomes ready
  Connections {
    target: ModuleRegistry
    function onReadyChanged() {
      if (ModuleRegistry.ready && manager.pendingReload) {
        manager.parseConfig(manager.pendingConfig)
        manager.pendingReload = false
        manager.pendingConfig = ""
      }
    }
  }

  // Config file watcher
  FileView {
    id: configFile
    path: manager.configPath
    blockLoading: !DataManager.ready
    watchChanges: true
    onFileChanged: reload()

    onLoaded: {
      var text = configFile.text()
      if (ModuleRegistry.ready) {
        manager.parseConfig(text)
      } else {
        // Store config and wait for ModuleRegistry
        manager.pendingConfig = text
        manager.pendingReload = true
      }
    }

    onLoadFailed: error => {
      console.error("[StatusbarManager] Failed to load config:", error)
    }
  }

  // Parse JSON config
  function parseConfig(text) {
    if (!text || text.trim() === "") {
      console.log("[StatusbarManager] Empty config text, skipping parse")
      return
    }

    try {
      var config = JSON.parse(text)

      // Load bar margins
      if (config.barMargins) {
        barMargins = {
          left: config.barMargins.left || 4,
          right: config.barMargins.right || 10
        }
      }

      // Load section spacing
      if (config.sectionSpacing) {
        sectionSpacing = {
          left: config.sectionSpacing.left || 0,
          center: config.sectionSpacing.center || 0,
          right: config.sectionSpacing.right || 0
        }
      }

      // Load items, filtering out modules that don't exist
      leftItems = filterValidItems(config.left || [])
      centerItems = filterValidItems(config.center || [])
      rightItems = filterValidItems(config.right || [])

      ready = true
      console.log("[StatusbarManager] Loaded config:", leftItems.length, "left,", centerItems.length, "center,", rightItems.length, "right")
    } catch (e) {
      console.error("[StatusbarManager] Failed to parse config:", e)
    }
  }

  // Filter out items whose modules don't exist
  function filterValidItems(items) {
    return items.filter(function(item) {
      return ModuleRegistry.hasBarComponent(item.id)
    })
  }

  // Get all items across all sections (for settings panel)
  function getAllItems() {
    var all = []
    for (var i = 0; i < leftItems.length; i++) {
      all.push(Object.assign({}, leftItems[i], { section: "left", index: i }))
    }
    for (var j = 0; j < centerItems.length; j++) {
      all.push(Object.assign({}, centerItems[j], { section: "center", index: j }))
    }
    for (var k = 0; k < rightItems.length; k++) {
      all.push(Object.assign({}, rightItems[k], { section: "right", index: k }))
    }
    return all
  }

  // Get items for a specific section
  function getItemsForSection(section) {
    if (section === "left") return leftItems
    if (section === "center") return centerItems
    if (section === "right") return rightItems
    return []
  }

  // Find item by ID and return { section, index, item }
  function findItem(id) {
    for (var i = 0; i < leftItems.length; i++) {
      if (leftItems[i].id === id) return { section: "left", index: i, item: leftItems[i] }
    }
    for (var j = 0; j < centerItems.length; j++) {
      if (centerItems[j].id === id) return { section: "center", index: j, item: centerItems[j] }
    }
    for (var k = 0; k < rightItems.length; k++) {
      if (rightItems[k].id === id) return { section: "right", index: k, item: rightItems[k] }
    }
    return null
  }

  // Toggle item enabled state
  function toggleItem(id) {
    var found = findItem(id)
    if (!found) return

    var items = getItemsForSection(found.section).slice()
    items[found.index] = Object.assign({}, items[found.index], { enabled: !items[found.index].enabled })

    if (found.section === "left") leftItems = items
    else if (found.section === "center") centerItems = items
    else if (found.section === "right") rightItems = items

    saveConfig()
  }

  // Set margins for an item
  function setMargins(id, marginLeft, marginRight) {
    var found = findItem(id)
    if (!found) return

    var items = getItemsForSection(found.section).slice()
    items[found.index] = Object.assign({}, items[found.index], {
      marginLeft: marginLeft,
      marginRight: marginRight
    })

    if (found.section === "left") leftItems = items
    else if (found.section === "center") centerItems = items
    else if (found.section === "right") rightItems = items

    saveConfig()
  }

  // Move item up within its section
  function moveUp(id) {
    var found = findItem(id)
    if (!found || found.index === 0) return

    var items = getItemsForSection(found.section).slice()
    var temp = items[found.index - 1]
    items[found.index - 1] = items[found.index]
    items[found.index] = temp

    if (found.section === "left") leftItems = items
    else if (found.section === "center") centerItems = items
    else if (found.section === "right") rightItems = items

    saveConfig()
  }

  // Move item down within its section
  function moveDown(id) {
    var found = findItem(id)
    if (!found) return

    var items = getItemsForSection(found.section).slice()
    if (found.index >= items.length - 1) return

    var temp = items[found.index + 1]
    items[found.index + 1] = items[found.index]
    items[found.index] = temp

    if (found.section === "left") leftItems = items
    else if (found.section === "center") centerItems = items
    else if (found.section === "right") rightItems = items

    saveConfig()
  }

  // Move item to a different section
  function moveToSection(id, newSection) {
    var found = findItem(id)
    if (!found || found.section === newSection) return

    // Remove from old section
    var oldItems = getItemsForSection(found.section).slice()
    var item = oldItems.splice(found.index, 1)[0]

    // Add to new section
    var newItems = getItemsForSection(newSection).slice()
    newItems.push(item)

    // Update both sections
    if (found.section === "left") leftItems = oldItems
    else if (found.section === "center") centerItems = oldItems
    else if (found.section === "right") rightItems = oldItems

    if (newSection === "left") leftItems = newItems
    else if (newSection === "center") centerItems = newItems
    else if (newSection === "right") rightItems = newItems

    saveConfig()
  }

  // Set bar margins
  function setBarMargins(left, right) {
    barMargins = { left: left, right: right }
    saveConfig()
  }

  // Set section spacing
  function setSectionSpacing(section, value) {
    var newSpacing = Object.assign({}, sectionSpacing)
    newSpacing[section] = value
    sectionSpacing = newSpacing
    saveConfig()
  }

  // Reset to defaults
  function resetToDefaults() {
    resetProc.running = true
  }

  Process {
    id: resetProc
    command: ["cp", manager.defaultsPath, manager.configPath]
    onExited: {
      // Reload config
      configFile.reload()
    }
  }

  // Save current config to file
  function saveConfig() {
    var config = {
      barMargins: barMargins,
      sectionSpacing: sectionSpacing,
      left: leftItems.map(stripMeta),
      center: centerItems.map(stripMeta),
      right: rightItems.map(stripMeta)
    }

    saveProc.configJson = JSON.stringify(config, null, 2)
    saveProc.running = true
  }

  // Strip metadata added by getAllItems
  function stripMeta(item) {
    return {
      id: item.id,
      enabled: item.enabled,
      marginLeft: item.marginLeft,
      marginRight: item.marginRight
    }
  }

  Process {
    id: saveProc
    property string configJson: ""
    command: ["sh", "-c", "cat > " + manager.configPath + " << 'STATUSBAR_EOF'\n" + configJson + "\nSTATUSBAR_EOF"]
    onExited: (code) => {
      if (code !== 0) {
        console.error("[StatusbarManager] Failed to save config")
      }
    }
  }
}
