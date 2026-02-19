pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: bluetoothManager

    // =========================================================================
    // PUBLIC STATE
    // =========================================================================

    // Bluetooth adapter power state
    property bool powered: false

    // Currently scanning for devices
    property bool scanning: false

    // Connected devices list
    property var connectedDevices: []

    // List of discovered devices
    // Each: { address: string, name: string, paired: bool, connected: bool }
    property var devices: []

    // Operation in progress (for UI feedback)
    property bool busy: false
    
    // Suppress refreshes briefly after disconnect (to prevent overwriting optimistic update)
    property bool suppressRefresh: false

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    function togglePower() {
        if (powered) {
            // Optimistic update
            powered = false
            scanning = false
            connectedDevices = []
            devices = []
            powerOffProc.running = true
        } else {
            // Optimistic update
            powered = true
            scanning = true
            devices = []
            powerOnProc.running = true
        }
    }

    function startScan() {
        if (!powered || scanning) return
        scanning = true
        devices = []
        scanProc.running = true
    }

    function stopScan() {
        if (!scanning) return
        scanStopProc.running = true
    }

    function connect(address) {
        busy = true
        connectProc.address = address
        connectProc.running = true
    }

    function disconnect(address) {
        busy = true
        suppressRefresh = true
        // Optimistic update - remove from connected devices and update devices list
        connectedDevices = connectedDevices.filter(d => d.address !== address)
        var updatedDevices = devices.slice()
        for (var i = 0; i < updatedDevices.length; i++) {
            if (updatedDevices[i].address === address) {
                updatedDevices[i].connected = false
                break
            }
        }
        devices = updatedDevices
        disconnectProc.address = address
        disconnectProc.running = true
    }

    function refresh() {
        statusProc.running = true
    }

    // =========================================================================
    // ICONS
    // =========================================================================

    readonly property string iconOff: "󰂲"
    readonly property string iconOn: "󰂰"
    readonly property string iconConnected: "󰂱"
    readonly property string iconScanning: "󰂯"

    function getIcon() {
        if (!powered) return iconOff
        if (connectedDevices.length > 0) return iconConnected
        if (scanning) return iconScanning
        return iconOn
    }

    // Get icon for a device (generic bluetooth device icon)
    function getDeviceIcon(iconType) {
        // iconType is not currently tracked, so return generic icon
        return "󰂱"
    }

    // =========================================================================
    // PROCESSES
    // =========================================================================

    // Check bluetooth status
    Process {
        id: statusProc
        command: ["bash", "-c", "echo 'show' | bluetoothctl"]
        running: true
        property string output: ""
        onStarted: output = ""
        stdout: SplitParser {
            onRead: data => statusProc.output += data + "\n"
        }
        onExited: {
            var poweredMatch = statusProc.output.match(/Powered:\s*(yes|no)/)
            bluetoothManager.powered = poweredMatch && poweredMatch[1] === "yes"

            // If powered, check for connected devices
            if (bluetoothManager.powered) {
                connectedCheckProc.running = true
            } else {
                bluetoothManager.connectedDevices = []
                bluetoothManager.devices = []
            }
        }
    }

    // Check for connected devices
    Process {
        id: connectedCheckProc
        command: ["bash", "-c", "echo 'devices Connected' | bluetoothctl"]
        property string output: ""
        onStarted: output = ""
        stdout: SplitParser {
            onRead: data => connectedCheckProc.output += data + "\n"
        }
        onExited: {
            var lines = connectedCheckProc.output.trim().split("\n").filter(l => l.includes("Device"))
            var connected = []
            for (var i = 0; i < lines.length; i++) {
                var match = lines[i].match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/)
                if (match) {
                    connected.push({
                        address: match[1],
                        name: match[2]
                    })
                }
            }
            bluetoothManager.connectedDevices = connected
        }
    }

    // Power on
    Process {
        id: powerOnProc
        command: ["bash", "-c", "echo 'power on' | bluetoothctl"]
        onExited: {
            // Delay scan start to allow bluetooth to actually power on
            powerOnScanTimer.restart()
        }
    }
    
    Timer {
        id: powerOnScanTimer
        interval: 500
        onTriggered: {
            scanProc.running = true
        }
    }

    // Power off
    Process {
        id: powerOffProc
        command: ["bash", "-c", "echo 'power off' | bluetoothctl"]
        onExited: {
            bluetoothManager.powered = false
            bluetoothManager.scanning = false
            bluetoothManager.connectedDevice = null
            bluetoothManager.devices = []
        }
    }

    // Scan for devices (runs for scanDuration then stops)
    Process {
        id: scanProc
        command: ["bash", "-c", "bluetoothctl --timeout 10 scan on"]
        onExited: {
            bluetoothManager.scanning = false
            // Get final device list
            deviceListProc.running = true
        }
    }

    // Stop scan
    Process {
        id: scanStopProc
        command: ["bash", "-c", "echo 'scan off' | bluetoothctl"]
        onExited: {
            bluetoothManager.scanning = false
        }
    }

    // Get device list
    Process {
        id: deviceListProc
        command: ["bash", "-c", "echo 'devices' | bluetoothctl"]
        property string output: ""
        onStarted: output = ""
        stdout: SplitParser {
            onRead: data => deviceListProc.output += data + "\n"
        }
        onExited: {
            var lines = deviceListProc.output.trim().split("\n").filter(l => l.includes("Device"))
            var connectedAddresses = bluetoothManager.connectedDevices.map(d => d.address)
            var newDevices = []
            for (var i = 0; i < lines.length; i++) {
                var match = lines[i].match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/)
                if (match) {
                    newDevices.push({
                        address: match[1],
                        name: match[2],
                        paired: false,
                        connected: connectedAddresses.indexOf(match[1]) >= 0
                    })
                }
            }
            bluetoothManager.devices = newDevices
            
            // Check paired status for each device
            pairedCheckProc.running = true
        }
    }

    // Check paired devices
    Process {
        id: pairedCheckProc
        command: ["bash", "-c", "echo 'devices Paired' | bluetoothctl"]
        property string output: ""
        onStarted: output = ""
        stdout: SplitParser {
            onRead: data => pairedCheckProc.output += data + "\n"
        }
        onExited: {
            var pairedAddresses = []
            var lines = pairedCheckProc.output.trim().split("\n").filter(l => l.includes("Device"))
            for (var i = 0; i < lines.length; i++) {
                var match = lines[i].match(/Device\s+([0-9A-Fa-f:]+)/)
                if (match) {
                    pairedAddresses.push(match[1])
                }
            }
            
            // Update devices with paired status
            var updatedDevices = bluetoothManager.devices.slice()
            for (var j = 0; j < updatedDevices.length; j++) {
                updatedDevices[j].paired = pairedAddresses.indexOf(updatedDevices[j].address) >= 0
            }
            bluetoothManager.devices = updatedDevices
        }
    }

    // Connect to device
    Process {
        id: connectProc
        property string address: ""
        command: ["bash", "-c", "echo 'connect " + address + "' | bluetoothctl"]
        onExited: exitCode => {
            bluetoothManager.busy = false
            bluetoothManager.refresh()
        }
    }

    // Disconnect from device
    Process {
        id: disconnectProc
        property string address: ""
        command: ["bash", "-c", "echo 'disconnect " + address + "' | bluetoothctl"]
        onExited: {
            bluetoothManager.busy = false
            // Delay refresh to allow disconnect to complete
            disconnectRefreshTimer.restart()
        }
    }
    
    Timer {
        id: disconnectRefreshTimer
        interval: 2000
        onTriggered: {
            bluetoothManager.suppressRefresh = false
            bluetoothManager.refresh()
        }
    }

    // =========================================================================
    // TIMERS
    // =========================================================================

    // Periodic device list refresh during scan
    Timer {
        interval: 2000
        running: bluetoothManager.scanning && !bluetoothManager.suppressRefresh
        repeat: true
        onTriggered: deviceListProc.running = true
    }

    // Periodic status refresh
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: bluetoothManager.refresh()
    }
}
