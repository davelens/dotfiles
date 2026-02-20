pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: wirelessManager

  // =========================================================================
  // PUBLIC STATE
  // =========================================================================

  // WiFi radio enabled
  property bool enabled: false

  // Currently scanning
  property bool scanning: false

  // Connected network (null if none)
  property var connectedNetwork: null

  // Connection timestamp (Unix timestamp when connected)
  property int connectionTimestamp: 0

  // List of available networks
  // Each: { ssid: string, signal: int, security: string, active: bool }
  property var networks: []

  // Operation in progress
  property bool busy: false

  // Suppress refreshes briefly after operations
  property bool suppressRefresh: false

  // Network speeds (bytes per second)
  property real downloadSpeed: 0
  property real uploadSpeed: 0
  property real lastRxBytes: 0
  property real lastTxBytes: 0

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  function toggleEnabled() {
    if (enabled) {
      // Optimistic update
      enabled = false
      connectedNetwork = null
      networks = []
      disableProc.running = true
    } else {
      // Optimistic update
      enabled = true
      enableProc.running = true
    }
  }

  function startScan() {
    if (!enabled || scanning) return
    scanning = true
    scanProc.running = true
  }

  function connect(ssid) {
    busy = true
    connectProc.ssid = ssid
    connectProc.running = true
  }

  function disconnect() {
    busy = true
    suppressRefresh = true
    // Optimistic update
    connectedNetwork = null
    var updatedNetworks = networks.slice()
    for (var i = 0; i < updatedNetworks.length; i++) {
      updatedNetworks[i].active = false
    }
    networks = updatedNetworks
    disconnectProc.running = true
  }

  function refresh() {
    statusProc.running = true
  }

  // =========================================================================
  // ICONS
  // =========================================================================

  readonly property string iconDisabled: "󰤮"
  readonly property string iconDisconnected: "󰤯"
  readonly property var iconSignal: ["󰤟", "󰤢", "󰤥", "󰤨"]

  function getIcon() {
    if (!enabled) return iconDisabled
    if (!connectedNetwork) return iconDisconnected
    var signal = connectedNetwork.signal || 0
    if (signal >= 75) return iconSignal[3]
    if (signal >= 50) return iconSignal[2]
    if (signal >= 25) return iconSignal[1]
    return iconSignal[0]
  }

  function getSignalIcon(signal) {
    if (signal >= 75) return iconSignal[3]
    if (signal >= 50) return iconSignal[2]
    if (signal >= 25) return iconSignal[1]
    return iconSignal[0]
  }

  function formatDuration(seconds) {
    if (seconds < 60) return "Just now"
    var minutes = Math.floor(seconds / 60)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)

    if (days > 0) {
      hours = hours % 24
      return days + "d " + hours + "h"
    }
    if (hours > 0) {
      minutes = minutes % 60
      return hours + "h " + minutes + "m"
    }
    return minutes + "m"
  }

  function formatDurationLong(seconds) {
    if (seconds < 60) return "Less than a minute"
    var minutes = Math.floor(seconds / 60) % 60
    var hours = Math.floor(seconds / 3600) % 24
    var days = Math.floor(seconds / 86400)

    var parts = []
    if (days > 0) parts.push(days + (days === 1 ? " day" : " days"))
    if (hours > 0) parts.push(hours + (hours === 1 ? " hour" : " hours"))
    if (minutes > 0) parts.push(minutes + (minutes === 1 ? " min" : " mins"))

    return parts.join(", ")
  }

  function getConnectionDuration() {
    if (connectionTimestamp <= 0) return ""
    var now = Math.floor(Date.now() / 1000)
    var seconds = now - connectionTimestamp
    return formatDuration(seconds)
  }

  function getConnectionDurationLong() {
    if (connectionTimestamp <= 0) return ""
    var now = Math.floor(Date.now() / 1000)
    var seconds = now - connectionTimestamp
    return formatDurationLong(seconds)
  }

  function formatSpeed(bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return bytesPerSecond.toFixed(0) + " B/s"
    } else if (bytesPerSecond < 1024 * 1024) {
      return (bytesPerSecond / 1024).toFixed(1) + " KB/s"
    } else {
      return (bytesPerSecond / (1024 * 1024)).toFixed(2) + " MB/s"
    }
  }

  // =========================================================================
  // PROCESSES
  // =========================================================================

  // Check WiFi status
  Process {
    id: statusProc
    command: ["nmcli", "-t", "radio", "wifi"]
    running: true
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => statusProc.output += data
    }
    onExited: {
      wirelessManager.enabled = statusProc.output.trim() === "enabled"
      if (wirelessManager.enabled) {
        networkListProc.running = true
      } else {
        wirelessManager.connectedNetwork = null
        wirelessManager.networks = []
      }
    }
  }

  // Enable WiFi
  Process {
    id: enableProc
    command: ["nmcli", "radio", "wifi", "on"]
    onExited: {
      enableScanTimer.restart()
    }
  }

  Timer {
    id: enableScanTimer
    interval: 1000
    onTriggered: {
      wirelessManager.scanning = true
      scanProc.running = true
    }
  }

  // Disable WiFi
  Process {
    id: disableProc
    command: ["nmcli", "radio", "wifi", "off"]
    onExited: {
      wirelessManager.enabled = false
      wirelessManager.connectedNetwork = null
      wirelessManager.networks = []
    }
  }

  // Scan for networks (with rescan)
  Process {
    id: scanProc
    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => scanProc.output += data + "\n"
    }
    onExited: {
      wirelessManager.scanning = false
      wirelessManager.parseNetworkList(scanProc.output)
    }
  }

  // Get network list (without rescan)
  Process {
    id: networkListProc
    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => networkListProc.output += data + "\n"
    }
    onExited: {
      wirelessManager.parseNetworkList(networkListProc.output)
      // Fetch connection timestamp if connected
      if (wirelessManager.connectedNetwork) {
        timestampProc.running = true
      }
    }
  }

  // Get connection timestamp
  Process {
    id: timestampProc
    command: ["nmcli", "-t", "-f", "NAME,TIMESTAMP", "connection", "show", "--active"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => timestampProc.output += data + "\n"
    }
    onExited: {
      var lines = timestampProc.output.trim().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split(":")
        if (parts.length >= 2 && wirelessManager.connectedNetwork && parts[0] === wirelessManager.connectedNetwork.ssid) {
          wirelessManager.connectionTimestamp = parseInt(parts[1]) || 0
          return
        }
      }
      wirelessManager.connectionTimestamp = 0
    }
  }

  // Connect to network
  Process {
    id: connectProc
    property string ssid: ""
    command: ["nmcli", "dev", "wifi", "connect", ssid]
    onExited: {
      wirelessManager.busy = false
      wirelessManager.refresh()
    }
  }

  // Disconnect
  Process {
    id: disconnectProc
    command: ["nmcli", "dev", "disconnect", "wlan0"]
    onExited: {
      wirelessManager.busy = false
      disconnectRefreshTimer.restart()
    }
  }

  Timer {
    id: disconnectRefreshTimer
    interval: 1000
    onTriggered: {
      wirelessManager.suppressRefresh = false
      wirelessManager.refresh()
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  function parseNetworkList(output) {
    var lines = output.trim().split("\n").filter(function(l) { return l.length > 0 })
    var networksBySsid = {}
    var connected = null

    for (var i = 0; i < lines.length; i++) {
      // Format: ACTIVE:SSID:SIGNAL:SECURITY
      var parts = lines[i].split(":")
      if (parts.length >= 4) {
        var active = parts[0] === "yes"
        var ssid = parts[1]
        var signal = parseInt(parts[2]) || 0
        var security = parts.slice(3).join(":") // Security may contain colons

        // Skip empty SSIDs
        if (!ssid) continue

        var network = {
          ssid: ssid,
          signal: signal,
          security: security,
          active: active
        }

        // If we've seen this SSID, keep the one with active=true or stronger signal
        if (networksBySsid[ssid]) {
          if (active) {
            networksBySsid[ssid] = network
          } else if (!networksBySsid[ssid].active && signal > networksBySsid[ssid].signal) {
            networksBySsid[ssid] = network
          }
        } else {
          networksBySsid[ssid] = network
        }

        if (active) {
          connected = network
        }
      }
    }

    // Convert to array
    var newNetworks = []
    for (var ssidKey in networksBySsid) {
      newNetworks.push(networksBySsid[ssidKey])
    }

    // Sort by signal strength (strongest first), but keep active at top
    newNetworks.sort(function(a, b) {
      if (a.active && !b.active) return -1
      if (!a.active && b.active) return 1
      return b.signal - a.signal
    })

    wirelessManager.networks = newNetworks
    wirelessManager.connectedNetwork = connected
  }

  // =========================================================================
  // NETWORK SPEED TRACKING
  // =========================================================================

  Process {
    id: networkStatsProc
    command: ["cat", "/sys/class/net/wlan0/statistics/rx_bytes", "/sys/class/net/wlan0/statistics/tx_bytes"]
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => networkStatsProc.output += data + "\n"
    }
    onExited: {
      var lines = networkStatsProc.output.trim().split("\n")
      if (lines.length >= 2) {
        var rxBytes = parseInt(lines[0]) || 0
        var txBytes = parseInt(lines[1]) || 0

        if (wirelessManager.lastRxBytes > 0) {
          wirelessManager.downloadSpeed = rxBytes - wirelessManager.lastRxBytes
          wirelessManager.uploadSpeed = txBytes - wirelessManager.lastTxBytes
        }

        wirelessManager.lastRxBytes = rxBytes
        wirelessManager.lastTxBytes = txBytes
      }
    }
  }

  Timer {
    interval: 1000
    running: wirelessManager.enabled && wirelessManager.connectedNetwork
    repeat: true
    onTriggered: networkStatsProc.running = true
  }

  // =========================================================================
  // TIMERS
  // =========================================================================

  // Periodic refresh
  Timer {
    interval: 30000
    running: wirelessManager.enabled && !wirelessManager.suppressRefresh
    repeat: true
    onTriggered: networkListProc.running = true
  }
}
