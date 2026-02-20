pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.I3
import QtQuick

Singleton {
    id: displayConfig

    // =========================================================================
    // PERSISTED CONFIG (FileView + JsonAdapter)
    // =========================================================================

    FileView {
        id: configFile
        path: Qt.resolvedUrl("./displays.json")
        blockLoading: true

        watchChanges: true
        onFileChanged: reload()

        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            // Stable display identifier: "model:serialNumber"
            // Empty string means "no preference" -> use first available screen
            property string primaryDisplayId: ""
        }
    }

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    // Stable identifier for a ShellScreen: "model:serialNumber"
    function screenId(screen) {
        if (!screen) return ""
        return screen.model + ":" + screen.serialNumber
    }

    // Human-friendly name for a ShellScreen
    // eDP connectors -> "Built-in Display", externals -> model name
    function friendlyName(screen) {
        if (!screen) return ""
        if (screen.name.startsWith("eDP")) return "Built-in Display"
        // Use model if available, otherwise the connector name
        return screen.model || screen.name
    }

    // The persisted primary display ID
    readonly property string primaryDisplayId: adapter.primaryDisplayId

    // The resolved primary screen object (with fallback)
    readonly property var primaryScreen: {
        var screens = Quickshell.screens
        if (screens.length === 0) return null

        // If no preference set, use first screen
        if (adapter.primaryDisplayId === "") return screens[0]

        // Find the saved primary among connected screens
        for (var i = 0; i < screens.length; i++) {
            if (screenId(screens[i]) === adapter.primaryDisplayId) {
                return screens[i]
            }
        }

        // Fallback: saved primary not connected, use first available
        return screens[0]
    }

    // Check if a screen is the primary
    function isPrimary(screen) {
        if (!screen || !primaryScreen) return false
        return screenId(screen) === screenId(primaryScreen)
    }

    // Set a screen as the primary display and persist
    function setPrimary(screen) {
        if (!screen) return
        adapter.primaryDisplayId = screenId(screen)
    }

    // =========================================================================
    // SWAY-SPECIFIC (isolated for portability)
    // =========================================================================

    Process {
        id: rotateProc
        property string outputName: ""
        property string transform: "normal"
        command: ["swaymsg", "output", outputName, "transform", transform]
        running: false
    }

    // Rotate a screen. degrees: 0, 90, 180, 270
    function setRotation(screen, degrees) {
        if (!screen) return
        var transform = "normal"
        if (degrees === 90) transform = "90"
        else if (degrees === 180) transform = "180"
        else if (degrees === 270) transform = "270"

        rotateProc.outputName = screen.name
        rotateProc.transform = transform
        rotateProc.running = true
    }

    // Track current rotation per screen (by name)
    property var rotations: ({})

    // Rotate 90° clockwise each time
    function toggleRotation(screen) {
        if (!screen) return
        var current = rotations[screen.name] || 0
        var next = (current + 90) % 360
        rotations[screen.name] = next
        setRotation(screen, next)
    }
}
