pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
  id: registry

  // List of discovered modules with settings (populated after discovery)
  property var modules: []

  // Whether discovery has completed
  property bool ready: false

  // Paths to scan for module.json manifests
  readonly property string configRoot: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell"
  readonly property string modulesPath: configRoot + "/modules"

  // Single discovery process - find and cat all module.json files
  Process {
    id: discoveryProc
    command: [
      "sh", "-c",
      "for f in " + registry.modulesPath + "/*/module.json " +
        registry.configRoot + "/statusbar/module.json; do " +
        "[ -f \"$f\" ] && echo \"__PATH__:$f\" && cat \"$f\" && echo \"__END__\"; " +
      "done"
    ]
    running: true

    property string output: ""

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        discoveryProc.output += data
      }
    }

    onExited: (code, status) => {
      registry.parseOutput(discoveryProc.output)
    }
  }

  function parseOutput(output) {
    var loadedModules = []
    var entries = output.split("__END__")

    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i].trim()
      if (!entry) continue

      // Extract path and JSON content
      var pathMatch = entry.match(/^__PATH__:(.+)/)
      if (!pathMatch) continue

      var jsonPath = pathMatch[1].trim()
      var moduleDir = jsonPath.substring(0, jsonPath.lastIndexOf("/"))
      var jsonContent = entry.substring(entry.indexOf("\n") + 1).trim()

      try {
        var moduleData = JSON.parse(jsonContent)
        moduleData.path = moduleDir
        moduleData.dirName = moduleDir.substring(moduleDir.lastIndexOf("/") + 1)

        // Resolve component paths to full file:// URLs
        if (moduleData.components) {
          moduleData.resolvedComponents = {}
          for (var key in moduleData.components) {
            moduleData.resolvedComponents[key] = "file://" + moduleDir + "/" + moduleData.components[key]
          }
        }

        loadedModules.push(moduleData)
      } catch (e) {
        console.error("[ModuleRegistry] Failed to parse:", jsonPath, e)
      }
    }

    // Sort by order (lower = first)
    loadedModules.sort(function(a, b) {
      return (a.order || 100) - (b.order || 100)
    })

    registry.modules = loadedModules
    registry.ready = true

    console.log("[ModuleRegistry] Discovered", loadedModules.length, "modules:")
    for (var j = 0; j < loadedModules.length; j++) {
      console.log("[ModuleRegistry]   -", loadedModules[j].name)
    }
  }

  // Get modules that have a settings component
  function getSettingsModules() {
    return modules.filter(function(m) {
      return m.components && m.components.settings
    })
  }

  // Get a module by ID
  function getModule(id) {
    for (var i = 0; i < modules.length; i++) {
      if (modules[i].id === id) return modules[i]
    }
    return null
  }

  // Get modules that have a bar component (button or segment)
  function getBarComponents() {
    return modules.filter(function(m) {
      return m.components && (m.components.button || m.components.segment)
    }).map(function(m) {
      var type = m.components.button ? "button" : "segment"
      var file = m.components.button || m.components.segment
      return {
        id: m.id,
        name: m.name,
        icon: m.icon,
        type: type,
        url: "file://" + m.path + "/" + file
      }
    })
  }

  // Get the URL for a bar component by module ID
  function getBarComponentUrl(id) {
    var module = getModule(id)
    if (!module || !module.components) return ""
    var file = module.components.button || module.components.segment
    if (!file) return ""
    return "file://" + module.path + "/" + file
  }

  // Get path relative to config root for a module file
  function getRelPath(module, file) {
    if (!module || !file) return ""
    // module.path is absolute; strip configRoot prefix to get relative path
    var rel = module.path
    if (rel.indexOf(registry.configRoot) === 0) {
      rel = rel.substring(registry.configRoot.length + 1)
    }
    return rel + "/" + file
  }

  // Get the relative path for a bar component (from shell root)
  // Used to avoid file:// singleton isolation with Loader.setSource()
  function getBarComponentRelPath(id) {
    var module = getModule(id)
    if (!module || !module.components) return ""
    var file = module.components.button || module.components.segment
    if (!file) return ""
    return getRelPath(module, file)
  }

  // Get the relative path for a settings component (from shell root)
  function getSettingsRelPath(id) {
    var module = getModule(id)
    if (!module || !module.components || !module.components.settings) return ""
    return getRelPath(module, module.components.settings)
  }

  // Check if a module exists and has a bar component
  function hasBarComponent(id) {
    var module = getModule(id)
    return module && module.components && (module.components.button || module.components.segment)
  }

  // Check if a module's bar component is a button (vs segment)
  function isButton(id) {
    var module = getModule(id)
    return module && module.components && module.components.button
  }

  // Check if a module has a popup component
  function hasPopup(id) {
    var module = getModule(id)
    return module && module.components && module.components.popup
  }

  // Get IDs of all modules that have a popup component
  function getPopupModuleIds() {
    return modules.filter(function(m) {
      return m.components && m.components.popup
    }).map(function(m) { return m.id })
  }

  // Get the relative path for a popup component (from shell root)
  function getPopupRelPath(id) {
    var module = getModule(id)
    if (!module || !module.components || !module.components.popup) return ""
    return getRelPath(module, module.components.popup)
  }

  // Get modules that have a popup component
  function getPopupModules() {
    return modules.filter(function(m) {
      return m.components && m.components.popup
    })
  }

  // Get IDs of modules that should be skipped during bar keyboard navigation
  function getSkipBarFocusIds() {
    return modules.filter(function(m) {
      return m.skipBarFocus === true
    }).map(function(m) { return m.id })
  }

  // Get all root component entries across modules.
  // Returns array of { dirName, file } for each declared root component.
  function getRootComponents() {
    var result = []
    for (var i = 0; i < modules.length; i++) {
      var m = modules[i]
      if (!m.rootComponents) continue
      for (var j = 0; j < m.rootComponents.length; j++) {
        result.push({ module: m, file: m.rootComponents[j] })
      }
    }
    return result
  }
}
