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

  // Path to modules directory
  readonly property string modulesPath: Quickshell.env("HOME") + "/.config/quickshell/modules"

  // Single discovery process - find and cat all module.json files
  Process {
    id: discoveryProc
    command: [
      "sh", "-c",
      "for f in " + registry.modulesPath + "/*/module.json; do " +
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
}
