import Quickshell
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    // =========================================================================
    // STATE
    // =========================================================================

    // Popup management - only one popup open at a time, on one screen
    property string activePopup: ""  // "", "volume", "brightness"
    property var activePopupScreen: null  // Track which screen the popup was opened on
    property bool outputDevicesExpanded: false
    property bool inputDevicesExpanded: false

    // Idle inhibitor
    property bool idleInhibited: false

    // Brightness - supports multiple displays
    // Each display: { id: string, name: string, type: "laptop"|"external", brightness: real, displayNum: int }
    property var displays: []
    property bool brightnessUserAdjusting: false
    
    // For bar icon - show average or primary display brightness
    property real brightnessLevel: {
        if (displays.length === 0) return 0.5
        var total = 0
        for (var i = 0; i < displays.length; i++) {
            total += displays[i].brightness
        }
        return total / displays.length
    }

    // Workspace icons
    readonly property var workspaceIcons: ({
        "1": "",
        "2": "󰈹",
        "3": "󰙯",
        "4": "󰎇",
        "5": ""
    })

    // =========================================================================
    // HELPER FUNCTIONS
    // =========================================================================

    function togglePopup(name, screen) {
        if (activePopup === name && activePopupScreen === screen) {
            closePopups()
        } else {
            activePopup = name
            activePopupScreen = screen
            outputDevicesExpanded = false
            inputDevicesExpanded = false
        }
    }

    function closePopups() {
        activePopup = ""
        activePopupScreen = null
        outputDevicesExpanded = false
        inputDevicesExpanded = false
    }

    function setDisplayBrightness(displayId, level) {
        brightnessUserAdjusting = true
        
        // Find the display and set brightness
        for (var j = 0; j < displays.length; j++) {
            if (displays[j].id === displayId) {
                var display = displays[j]
                var percent = Math.round(level * 100)
                if (display.type === "backlight") {
                    backlightSetProc.device = display.deviceId
                    backlightSetProc.targetPercent = percent
                    backlightSetProc.running = true
                } else if (display.type === "ddc") {
                    ddcSetProc.displayNum = display.deviceId
                    ddcSetProc.targetPercent = percent
                    ddcSetProc.running = true
                }
                break
            }
        }
        
        brightnessSettleTimer.restart()
    }

    function getBrightnessIcon(level) {
        if (level < 0.25) return "󰃞"
        if (level < 0.5) return "󰃟"
        if (level < 0.75) return "󰃠"
        return "󰃡"
    }

    function getVolumeIcon(volume, muted) {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.25) return "󰕿"
        if (volume < 0.50) return "󰖀"
        return "󰕾"
    }

    function getBatteryIcon(percentage, charging, fullyCharged) {
        if (charging) return "󰂄"
        if (fullyCharged) return "󰂅"
        if (percentage >= 90) return "󰁹"
        if (percentage >= 80) return "󰂂"
        if (percentage >= 70) return "󰂁"
        if (percentage >= 60) return "󰂀"
        if (percentage >= 50) return "󰁿"
        if (percentage >= 40) return "󰁾"
        if (percentage >= 30) return "󰁽"
        if (percentage >= 20) return "󰁼"
        if (percentage >= 10) return "󰁻"
        return "󰂃"
    }

    function getBatteryColor(percentage, charging, fullyCharged) {
        if (charging || fullyCharged) return Colors.green
        if (percentage <= 10) return Colors.red
        if (percentage <= 25) return Colors.peach
        if (percentage <= 50) return Colors.yellow
        return Colors.green
    }

    // =========================================================================
    // COMPUTED PROPERTIES
    // =========================================================================

    property var audioSinks: {
        var sinks = []
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i]
                if (node.audio && node.isSink && !node.isStream) {
                    sinks.push(node)
                }
            }
        }
        return sinks
    }

    property var audioSources: {
        var sources = []
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            var nodes = Pipewire.nodes.values
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i]
                if (node.audio && !node.isSink && !node.isStream) {
                    sources.push(node)
                }
            }
        }
        return sources
    }

    // =========================================================================
    // PROCESSES
    // =========================================================================

    Process {
        id: idleInhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
        running: false
    }

    Process {
        id: powerMenuProc
        command: ["sh", "-c", "~/.local/bin/rofi-start --powermenu"]
        running: false
    }

    // =========================================================================
    // BRIGHTNESS DETECTION & CONTROL
    // =========================================================================
    
    // Detected DDC display numbers from ddcutil detect
    property var ddcDisplays: []
    
    // Backlight brightness reading (for laptop panels - only if backlight device exists)
    Process {
        id: backlightReadProc
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (root.brightnessUserAdjusting) return
                // Format: device,class,current,percentage%,max
                var parts = data.trim().split(",")
                if (parts.length >= 5 && parts[1] === "backlight") {
                    var deviceName = parts[0]
                    var current = parseInt(parts[2])
                    var max = parseInt(parts[4])
                    if (max > 0) {
                        var brightness = current / max
                        root.updateDisplay("backlight-" + deviceName, "Built-in Display", "backlight", brightness, deviceName)
                    }
                }
            }
        }
        onExited: exitCode => {
            // If no backlight device, that's fine - just means no laptop display
            if (exitCode !== 0) {
                root.removeDisplaysByType("backlight")
            }
        }
    }

    Process {
        id: backlightSetProc
        property string device: ""
        property int targetPercent: 50
        command: ["brightnessctl", "-d", device, "set", targetPercent + "%"]
        running: false
    }

    // DDC display detection - finds all external monitors
    Process {
        id: ddcDetectProc
        command: ["ddcutil", "detect", "--brief"]
        running: true
        property var foundDisplays: []
        onStarted: {
            foundDisplays = []
        }
        stdout: SplitParser {
            onRead: data => {
                // Look for "Display N" lines (may have leading whitespace)
                var match = data.match(/^\s*Display\s+(\d+)/)
                if (match) {
                    ddcDetectProc.foundDisplays.push(parseInt(match[1]))
                }
            }
        }
        onExited: exitCode => {
            root.ddcDisplays = foundDisplays
            // Remove DDC displays that no longer exist
            root.removeStaleDisplays()
            // Read brightness for each detected display
            for (var i = 0; i < foundDisplays.length; i++) {
                root.readDdcBrightness(foundDisplays[i])
            }
        }
    }

    // DDC brightness reading - called per display
    function readDdcBrightness(displayNum) {
        ddcReadProc.displayNum = displayNum
        ddcReadProc.running = true
    }
    
    Process {
        id: ddcReadProc
        property int displayNum: 1
        property bool foundDisplay: false
        property real detectedBrightness: 0
        command: ["ddcutil", "getvcp", "10", "--display", displayNum.toString(), "--brief"]
        running: false
        onStarted: {
            foundDisplay = false
            detectedBrightness = 0
        }
        stdout: SplitParser {
            onRead: data => {
                if (root.brightnessUserAdjusting) return
                // Format: VCP 10 C current max
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 5 && parts[0] === "VCP") {
                    var current = parseInt(parts[3])
                    var max = parseInt(parts[4])
                    if (max > 0) {
                        ddcReadProc.detectedBrightness = current / max
                        ddcReadProc.foundDisplay = true
                    }
                }
            }
        }
        onExited: exitCode => {
            if (exitCode === 0 && foundDisplay) {
                var name = "External Monitor" + (root.ddcDisplays.length > 1 ? " " + displayNum : "")
                root.updateDisplay("ddc-" + displayNum, name, "ddc", detectedBrightness, displayNum)
            } else {
                root.removeDisplay("ddc-" + displayNum)
            }
        }
    }

    Process {
        id: ddcSetProc
        property int displayNum: 1
        property int targetPercent: 50
        command: ["ddcutil", "setvcp", "10", targetPercent.toString(), "--display", displayNum.toString()]
        running: false
    }
    
    // Helper function to update or add a display
    function updateDisplay(id, name, type, brightness, deviceId) {
        var newDisplays = displays.slice()
        var found = false
        for (var i = 0; i < newDisplays.length; i++) {
            if (newDisplays[i].id === id) {
                newDisplays[i] = { id: id, name: name, type: type, brightness: brightness, deviceId: deviceId }
                found = true
                break
            }
        }
        if (!found) {
            newDisplays.push({ id: id, name: name, type: type, brightness: brightness, deviceId: deviceId })
        }
        displays = newDisplays
    }
    
    // Helper function to remove a display
    function removeDisplay(id) {
        var newDisplays = []
        for (var i = 0; i < displays.length; i++) {
            if (displays[i].id !== id) {
                newDisplays.push(displays[i])
            }
        }
        displays = newDisplays
    }
    
    // Remove displays of a specific type
    function removeDisplaysByType(type) {
        var newDisplays = []
        for (var i = 0; i < displays.length; i++) {
            if (displays[i].type !== type) {
                newDisplays.push(displays[i])
            }
        }
        displays = newDisplays
    }
    
    // Remove DDC displays that are no longer detected
    function removeStaleDisplays() {
        var newDisplays = []
        for (var i = 0; i < displays.length; i++) {
            var d = displays[i]
            if (d.type !== "ddc") {
                newDisplays.push(d)
            } else {
                // Check if this DDC display is still in ddcDisplays
                var stillExists = false
                for (var j = 0; j < ddcDisplays.length; j++) {
                    if (d.deviceId === ddcDisplays[j]) {
                        stillExists = true
                        break
                    }
                }
                if (stillExists) {
                    newDisplays.push(d)
                }
            }
        }
        displays = newDisplays
    }

    // =========================================================================
    // TIMERS
    // =========================================================================

    Timer {
        id: brightnessSettleTimer
        interval: 1000
        onTriggered: root.brightnessUserAdjusting = false
    }

    Timer {
        id: brightnessRefreshTimer
        interval: 5000
        running: root.activePopup !== "brightness"  // Pause when brightness popup is open
        repeat: true
        onTriggered: {
            // Re-detect all displays periodically
            backlightReadProc.running = true
            ddcDetectProc.running = true
        }
    }

    // =========================================================================
    // PIPEWIRE TRACKING
    // =========================================================================

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // =========================================================================
    // CLICK-OUTSIDE OVERLAY
    // =========================================================================

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.activePopup !== ""

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell-overlay"
            WlrLayershell.layer: WlrLayer.Top

            MouseArea {
                anchors.fill: parent
                onClicked: root.closePopups()
            }
        }
    }

    // =========================================================================
    // BAR
    // =========================================================================

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: Colors.base

            WlrLayershell.namespace: "quickshell"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: root.activePopup !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            contentItem {
                focus: root.activePopup !== ""
                Keys.onEscapePressed: root.closePopups()
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.closePopups()
            }

            // -----------------------------------------------------------------
            // LEFT SECTION
            // -----------------------------------------------------------------
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Power Menu
                Rectangle {
                    width: 28
                    height: 24
                    radius: 4
                    color: powerMenuArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "󰤄"
                        color: Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: powerMenuArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerMenuProc.running = true
                    }
                }

                // Idle Inhibitor
                Rectangle {
                    width: 28
                    height: 24
                    radius: 4
                    color: idleInhibitorArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: root.idleInhibited ? "󰈈" : "󰈉"
                        color: root.idleInhibited ? Colors.blue : Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: idleInhibitorArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.idleInhibited = !root.idleInhibited
                            if (root.idleInhibited) {
                                idleInhibitProc.running = true
                            } else {
                                idleInhibitProc.signal(15)
                            }
                        }
                    }
                }

                // Workspaces
                Row {
                    spacing: 4

                    Repeater {
                        model: [1, 2, 3, 4, 5]

                        Rectangle {
                            required property int modelData
                            property bool isActive: I3.focusedWorkspace ? I3.focusedWorkspace.name === modelData.toString() : false
                            property bool exists: {
                                if (!I3.workspaces || !I3.workspaces.values) return false
                                var ws = I3.workspaces.values
                                for (var i = 0; i < ws.length; i++) {
                                    if (ws[i].name === modelData.toString()) return true
                                }
                                return false
                            }

                            width: 32
                            height: 24
                            radius: 4
                            color: isActive || exists ? Colors.surface1 : Colors.surface0

                            Text {
                                anchors.centerIn: parent
                                text: root.workspaceIcons[modelData.toString()] || modelData.toString()
                                color: isActive ? Colors.blue : (exists ? Colors.text : Colors.overlay0)
                                font.pixelSize: 16
                                font.family: "Symbols Nerd Font"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: I3.dispatch("workspace number " + modelData)
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // RIGHT SECTION
            // -----------------------------------------------------------------
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Brightness
                Rectangle {
                    id: brightnessButton
                    width: 28
                    height: 24
                    radius: 4
                    color: brightnessArea.containsMouse ? Colors.surface1 : Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: root.getBrightnessIcon(root.brightnessLevel)
                        color: Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: brightnessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePopup("brightness", panel.modelData)
                        onWheel: event => {
                            var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                            root.setBrightness(Math.max(0.01, Math.min(1, root.brightnessLevel + delta)))
                        }
                    }
                }

                // Volume
                Rectangle {
                    id: volumeButton
                    width: 28
                    height: 24
                    radius: 4
                    color: volumeArea.containsMouse ? Colors.surface1 : Colors.surface0

                    property var sink: Pipewire.defaultAudioSink
                    property real volume: sink && sink.audio ? sink.audio.volume : 0
                    property bool muted: sink && sink.audio ? sink.audio.muted : false

                    Text {
                        anchors.centerIn: parent
                        text: root.getVolumeIcon(volumeButton.volume, volumeButton.muted)
                        color: volumeButton.muted ? Colors.overlay0 : Colors.text
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                        id: volumeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePopup("volume", panel.modelData)
                        onWheel: event => {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, Pipewire.defaultAudioSink.audio.volume + delta))
                            }
                        }
                    }
                }

                // Battery
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: UPower.displayDevice && UPower.displayDevice.ready

                    property real percentage: UPower.displayDevice ? UPower.displayDevice.percentage * 100 : 0
                    property int batteryState: UPower.displayDevice ? UPower.displayDevice.state : 0
                    property bool charging: batteryState === 1
                    property bool fullyCharged: batteryState === 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.getBatteryIcon(parent.percentage, parent.charging, parent.fullyCharged)
                        color: root.getBatteryColor(parent.percentage, parent.charging, parent.fullyCharged)
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(parent.percentage) + "%"
                        color: Colors.text
                        font.pixelSize: 14
                    }
                }

                // Clock
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.time
                    color: Colors.text
                    font.pixelSize: 14
                }
            }

            // -----------------------------------------------------------------
            // VOLUME POPUP
            // -----------------------------------------------------------------
            PopupWindow {
                visible: root.activePopup === "volume" && root.activePopupScreen === panel.modelData

                anchor.item: volumeButton
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left

                implicitWidth: 320
                implicitHeight: {
                    var h = 48 + 28 + 16 + 28
                    if (root.outputDevicesExpanded) h += root.audioSinks.length * 36
                    if (root.inputDevicesExpanded) h += root.audioSources.length * 36
                    return h + 16
                }
                color: Colors.base

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    // Volume slider
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 8

                        property var sink: Pipewire.defaultAudioSink
                        property real volume: sink && sink.audio ? sink.audio.volume : 0
                        property bool muted: sink && sink.audio ? sink.audio.muted : false

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.muted ? "󰝟" : "󰕾"
                            color: parent.muted ? Colors.red : Colors.text
                            font.pixelSize: 18
                            font.family: "Symbols Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }
                        }

                        Slider {
                            id: volumeSlider
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 18 - 44 - 16
                            height: 20
                            from: 0
                            to: 1
                            value: parent.volume
                            onMoved: {
                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                    Pipewire.defaultAudioSink.audio.volume = value
                                }
                            }

                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 8
                                width: volumeSlider.availableWidth
                                height: 8
                                radius: 4
                                color: Colors.surface0

                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Colors.blue
                                    radius: 4
                                }
                            }

                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                implicitWidth: 14
                                implicitHeight: 14
                                width: 14
                                height: 14
                                radius: 7
                                color: Colors.text
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(parent.volume * 100) + "%"
                            color: Colors.blue
                            font.pixelSize: 14
                            width: 44
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Output devices
                    DeviceList {
                        width: parent.width
                        devices: root.audioSinks
                        currentDevice: Pipewire.defaultAudioSink
                        headerIcon: "󰓃"
                        headerLabel: "Output"
                        expanded: root.outputDevicesExpanded
                        onToggleExpanded: root.outputDevicesExpanded = expanded
                        onDeviceSelected: device => Pipewire.preferredDefaultAudioSink = device
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colors.surface1
                    }

                    // Input devices
                    DeviceList {
                        width: parent.width
                        devices: root.audioSources
                        currentDevice: Pipewire.defaultAudioSource
                        headerIcon: "󰍬"
                        headerLabel: "Input"
                        expanded: root.inputDevicesExpanded
                        onToggleExpanded: root.inputDevicesExpanded = expanded
                        onDeviceSelected: device => Pipewire.preferredDefaultAudioSource = device
                    }
                }
            }

            // -----------------------------------------------------------------
            // BRIGHTNESS POPUP
            // -----------------------------------------------------------------
            PopupWindow {
                visible: root.activePopup === "brightness" && root.activePopupScreen === panel.modelData

                anchor.item: brightnessButton
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left

                implicitWidth: 280
                implicitHeight: 16 + root.displays.length * 56  // margins + per-display height
                color: Colors.base

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    Repeater {
                        model: root.displays

                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: (modelData.type === "ddc" ? "󰍹  " : "󰌢  ") + modelData.name
                                color: Colors.overlay0
                                font.pixelSize: 11
                                font.family: "Symbols Nerd Font"
                            }

                            Row {
                                width: parent.width
                                height: 32
                                spacing: 8

                                property string displayId: modelData.id
                                property real displayBrightness: modelData.brightness

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.getBrightnessIcon(brightnessSlider.value)
                                    color: Colors.text
                                    font.pixelSize: 18
                                    font.family: "Symbols Nerd Font"
                                }

                                // NOTE: Sliders in Repeaters - modifying the model array while
                                // dragging causes re-render, destroying the Slider mid-drag.
                                // Solutions: don't update array in handler, pause refresh timers
                                // while popup is open, use onMoved (not onValueChanged).
                                // Slider also needs explicit height + implicitWidth/Height on background/handle.
                                Slider {
                                    id: brightnessSlider
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 18 - 44 - 16
                                    height: 20
                                    from: 0.01
                                    to: 1
                                    value: parent.displayBrightness
                                    
                                    onMoved: root.setDisplayBrightness(parent.displayId, value)

                                    background: Rectangle {
                                        x: brightnessSlider.leftPadding
                                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 200
                                        implicitHeight: 8
                                        width: brightnessSlider.availableWidth
                                        height: 8
                                        radius: 4
                                        color: Colors.surface0

                                        Rectangle {
                                            width: brightnessSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: Colors.yellow
                                            radius: 4
                                        }
                                    }

                                    handle: Rectangle {
                                        x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: Colors.text
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(brightnessSlider.value * 100) + "%"
                                    color: Colors.yellow
                                    font.pixelSize: 14
                                    width: 44
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
