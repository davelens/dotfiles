pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: manager

  property int cpuPercent: 0
  property int ramPercent: 0
  property real ramUsedGb: 0
  property real ramTotalGb: 0

  // Previous CPU sample for delta calculation
  property var _prevCpu: null

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      pollProc.command = ["sh", "-c", "head -1 /proc/stat && grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
      pollProc.running = true
    }
  }

  Process {
    id: pollProc
    property string output: ""
    onStarted: output = ""
    stdout: SplitParser {
      onRead: data => pollProc.output += data + "\n"
    }
    onExited: {
      var lines = pollProc.output.trim().split("\n")
      if (lines.length < 3) return

      // Parse CPU from /proc/stat (first line: cpu user nice system idle iowait irq softirq steal)
      var cpuParts = lines[0].split(/\s+/)
      if (cpuParts[0] === "cpu" && cpuParts.length >= 5) {
        var user = parseInt(cpuParts[1]) || 0
        var nice = parseInt(cpuParts[2]) || 0
        var system = parseInt(cpuParts[3]) || 0
        var idle = parseInt(cpuParts[4]) || 0
        var iowait = parseInt(cpuParts[5]) || 0
        var irq = parseInt(cpuParts[6]) || 0
        var softirq = parseInt(cpuParts[7]) || 0
        var steal = parseInt(cpuParts[8]) || 0

        var totalIdle = idle + iowait
        var total = user + nice + system + idle + iowait + irq + softirq + steal

        if (manager._prevCpu !== null) {
          var diffTotal = total - manager._prevCpu.total
          var diffIdle = totalIdle - manager._prevCpu.idle
          if (diffTotal > 0) {
            manager.cpuPercent = Math.round((diffTotal - diffIdle) / diffTotal * 100)
          }
        }

        manager._prevCpu = { total: total, idle: totalIdle }
      }

      // Parse memory from /proc/meminfo
      var memTotal = 0
      var memAvailable = 0
      for (var i = 1; i < lines.length; i++) {
        var parts = lines[i].split(/\s+/)
        if (parts[0] === "MemTotal:") memTotal = parseInt(parts[1]) || 0
        else if (parts[0] === "MemAvailable:") memAvailable = parseInt(parts[1]) || 0
      }

      if (memTotal > 0) {
        var used = memTotal - memAvailable
        manager.ramPercent = Math.round(used / memTotal * 100)
        manager.ramUsedGb = parseFloat((used / 1048576).toFixed(1))
        manager.ramTotalGb = parseFloat((memTotal / 1048576).toFixed(1))
      }
    }
  }
}
