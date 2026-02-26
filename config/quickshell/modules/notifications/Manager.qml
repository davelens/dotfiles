pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../.."

Singleton {
  id: notificationManager

  // =========================================================================
  // SETTINGS (persisted to file via JsonAdapter)
  // =========================================================================

  // Property aliases for external access (bind to adapter properties)
  property alias popupTimeout: settingsAdapter.popupTimeout
  property alias maxHistorySize: settingsAdapter.maxHistorySize
  property alias dndScheduleEnabled: settingsAdapter.dndScheduleEnabled
  property alias dndStartHour: settingsAdapter.dndStartHour
  property alias dndStartMinute: settingsAdapter.dndStartMinute
  property alias dndEndHour: settingsAdapter.dndEndHour
  property alias dndEndMinute: settingsAdapter.dndEndMinute
  property alias criticalBypassDnd: settingsAdapter.criticalBypassDnd

  // File-based persistence
  FileView {
    id: settingsFile
    path: DataManager.notificationSettingsPath
    blockLoading: !DataManager.ready

    // Reload file when it changes on disk
    watchChanges: true
    onFileChanged: reload()

    // Save when adapter properties change
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: settingsAdapter
      property int popupTimeout: 5000              // ms before auto-dismiss
      property int maxHistorySize: 50              // max notifications in history
      property bool dndScheduleEnabled: false      // enable time-based DND
      property int dndStartHour: 22                // schedule start hour (0-23)
      property int dndStartMinute: 0               // schedule start minute (0, 15, 30, 45)
      property int dndEndHour: 8                   // schedule end hour (0-23)
      property int dndEndMinute: 0                 // schedule end minute (0, 15, 30, 45)
      property bool criticalBypassDnd: true        // critical notifications bypass DND
    }
  }

  // =========================================================================
  // RUNTIME STATE
  // =========================================================================

  property bool dndEnabled: false              // manual DND toggle
  property bool panelOpen: false               // history panel visibility

  // Use ListModel for proper add/remove animations
  property alias visibleNotifications: popupModel
  ListModel { id: popupModel }
  property var history: []                     // all notifications grouped by app
  property int unreadCount: 0                  // unread notification count

  // Computed: is DND currently active?
  readonly property bool isDndActive: dndEnabled || isInDndSchedule()

  // =========================================================================
  // ICONS
  // =========================================================================

  readonly property string iconNone: "󰂚"       // no notifications
  readonly property string iconHas: "󰂚"        // has notifications (same icon, badge shows count)
  readonly property string iconDnd: "󰂠"        // DND enabled

  function getIcon() {
    if (isDndActive) return iconDnd
    return iconNone
  }

  // =========================================================================
  // NOTIFICATION SERVER
  // =========================================================================

  NotificationServer {
    id: server

    bodySupported: true
    actionsSupported: true           // support notification actions (e.g., Discord "open conversation")
    imageSupported: true             // for app icons
    persistenceSupported: true       // for history
    keepOnReload: true

    onNotification: function(notification) {
      notification.tracked = true
      addToHistory(notification)

      // Show popup unless DND active (critical bypasses DND)
      var isCritical = notification.urgency === NotificationUrgency.Critical
      if (!notificationManager.isDndActive || (isCritical && notificationManager.criticalBypassDnd)) {
        showPopup(notification)
      }
    }
  }

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  function getAppName(notification) {
    var appName = notification.appName || ""

    // If appName looks like an app ID (e.g., "Com.discordapp.Discord"), extract last part
    if (appName.indexOf(".") !== -1) {
      var parts = appName.split(".")
      return parts[parts.length - 1]
    }

    // If no appName or it's "notify-send", try desktopEntry
    if (!appName || appName === "notify-send") {
      if (notification.desktopEntry) {
        var entry = notification.desktopEntry
        // desktopEntry can also be an app ID, so extract last part
        if (entry.indexOf(".") !== -1) {
          var parts = entry.split(".")
          return parts[parts.length - 1]
        }
        return entry.charAt(0).toUpperCase() + entry.slice(1)
      }
    }

    return appName || "Unknown"
  }

  function getAppIcon(notification) {
    // Helper to resolve an icon name/path
    function resolveIcon(name) {
      if (!name) return ""
      // Absolute path - use directly
      if (name.startsWith("/")) return name
      // Try as icon name
      var icon = Quickshell.iconPath(name, true)
      if (icon) return icon
      // If it's an app ID (e.g., "com.discordapp.Discord"), try lowercase last part
      if (name.indexOf(".") !== -1) {
        var parts = name.split(".")
        var appName = parts[parts.length - 1].toLowerCase()
        icon = Quickshell.iconPath(appName, true)
        if (icon) return icon
      }
      return ""
    }

    // Try appIcon first, then desktopEntry
    var icon = resolveIcon(notification.appIcon)
    if (icon) return icon

    icon = resolveIcon(notification.desktopEntry)
    if (icon) return icon

    return ""
  }

  function getImage(notification) {
    var hints = notification.hints || {}
    if (hints["image-path"]) return "file://" + hints["image-path"]
    return ""
  }

  function showPopup(notification) {
    // Insert at beginning (max 5)
    popupModel.insert(0, {
      notificationId: notification.id,
      appName: getAppName(notification),
      appIcon: getAppIcon(notification),
      image: getImage(notification),
      summary: notification.summary || "",
      body: notification.body || "",
      urgency: notification.urgency,
      timestamp: new Date()
    })

    // Remove excess
    while (popupModel.count > 5) {
      popupModel.remove(popupModel.count - 1)
    }
  }

  function dismissPopup(notificationId) {
    // Remove from visible
    for (var i = 0; i < popupModel.count; i++) {
      if (popupModel.get(i).notificationId === notificationId) {
        popupModel.remove(i)
        break
      }
    }

    // Find and dismiss the actual notification
    for (var j = 0; j < server.trackedNotifications.values.length; j++) {
      var n = server.trackedNotifications.values[j]
      if (n.id === notificationId) {
        n.dismiss()
        break
      }
    }
  }

  function expirePopup(notificationId) {
    // Remove from visible
    for (var i = 0; i < popupModel.count; i++) {
      if (popupModel.get(i).notificationId === notificationId) {
        popupModel.remove(i)
        break
      }
    }

    // Find and expire the actual notification
    for (var j = 0; j < server.trackedNotifications.values.length; j++) {
      var n = server.trackedNotifications.values[j]
      if (n.id === notificationId) {
        n.expire()
        break
      }
    }
  }

  function invokeDefaultAction(notificationId) {
    // Remove from visible popups
    for (var i = 0; i < popupModel.count; i++) {
      if (popupModel.get(i).notificationId === notificationId) {
        popupModel.remove(i)
        break
      }
    }

    // Find the notification and invoke its default action
    for (var j = 0; j < server.trackedNotifications.values.length; j++) {
      var n = server.trackedNotifications.values[j]
      if (n.id === notificationId) {
        // Look for "default" action (clicking the notification body)
        if (n.actions) {
          for (var k = 0; k < n.actions.length; k++) {
            if (n.actions[k].identifier === "default") {
              n.actions[k].invoke()
              // Focus the app's window to switch to its workspace
              focusAppWindow(n.desktopEntry)
              return
            }
          }
        }
        // No default action found, just dismiss
        n.dismiss()
        return
      }
    }
  }

  function invokeAction(notificationId, actionIdentifier) {
    // Remove from visible popups
    for (var i = 0; i < popupModel.count; i++) {
      if (popupModel.get(i).notificationId === notificationId) {
        popupModel.remove(i)
        break
      }
    }

    // Find the notification and invoke the matching action
    for (var j = 0; j < server.trackedNotifications.values.length; j++) {
      var n = server.trackedNotifications.values[j]
      if (n.id === notificationId) {
        if (n.actions) {
          for (var k = 0; k < n.actions.length; k++) {
            if (n.actions[k].identifier === actionIdentifier) {
              n.actions[k].invoke()
              return
            }
          }
        }
        n.dismiss()
        return
      }
    }
  }

  // Return non-default actions for a notification (for rendering buttons)
  function getActions(notificationId) {
    for (var i = 0; i < server.trackedNotifications.values.length; i++) {
      var n = server.trackedNotifications.values[i]
      if (n.id === notificationId) {
        var result = []
        if (n.actions) {
          for (var j = 0; j < n.actions.length; j++) {
            if (n.actions[j].identifier !== "default") {
              result.push({ identifier: n.actions[j].identifier, text: n.actions[j].text })
            }
          }
        }
        return result
      }
    }
    return []
  }

  // Focus an app's window by its desktop entry (app_id in Sway)
  function focusAppWindow(desktopEntry) {
    if (!desktopEntry) return
    focusProc.command = ["swaymsg", "[app_id=" + desktopEntry + "] focus"]
    focusProc.running = true
  }

  Process {
    id: focusProc
  }

  function addToHistory(notification) {
    var appName = getAppName(notification)
    var appIcon = getAppIcon(notification)
    var entry = {
      id: notification.id,
      appName: appName,
      appIcon: appIcon,
      summary: notification.summary || "",
      body: notification.body || "",
      urgency: notification.urgency,
      timestamp: new Date(),
      read: false
    }

    // Find or create app group
    var newHistory = history.slice()
    var found = false

    for (var i = 0; i < newHistory.length; i++) {
      if (newHistory[i].appName === appName) {
        // Add to existing group
        newHistory[i].notifications.unshift(entry)
        newHistory[i].expanded = true  // Auto-expand when new notification arrives
        found = true
        break
      }
    }

    if (!found) {
      // Create new group
      newHistory.unshift({
        appName: appName,
        appIcon: appIcon,
        notifications: [entry],
        expanded: true
      })
    }

    // Enforce max history size (count total notifications)
    var totalCount = 0
    for (var j = 0; j < newHistory.length; j++) {
      totalCount += newHistory[j].notifications.length
    }

    while (totalCount > maxHistorySize && newHistory.length > 0) {
      // Remove oldest notification from last group
      var lastGroup = newHistory[newHistory.length - 1]
      if (lastGroup.notifications.length > 0) {
        lastGroup.notifications.pop()
        totalCount--
      }
      // Remove empty groups
      if (lastGroup.notifications.length === 0) {
        newHistory.pop()
      }
    }

    history = newHistory
    updateUnreadCount()
  }

  function removeFromHistory(notificationId) {
    var newHistory = history.slice()

    for (var i = 0; i < newHistory.length; i++) {
      var group = newHistory[i]
      group.notifications = group.notifications.filter(function(n) {
        return n.id !== notificationId
      })
    }

    // Remove empty groups
    newHistory = newHistory.filter(function(g) {
      return g.notifications.length > 0
    })

    history = newHistory
    updateUnreadCount()
  }

  function clearHistory() {
    // Dismiss all tracked notifications
    var notifications = server.trackedNotifications.values.slice()
    for (var i = 0; i < notifications.length; i++) {
      notifications[i].dismiss()
    }

    history = []
    popupModel.clear()
    unreadCount = 0
  }

  function markAllAsRead() {
    var newHistory = history.slice()

    for (var i = 0; i < newHistory.length; i++) {
      for (var j = 0; j < newHistory[i].notifications.length; j++) {
        newHistory[i].notifications[j].read = true
      }
    }

    history = newHistory
    unreadCount = 0
  }

  function toggleGroup(appName) {
    var newHistory = history.slice()

    for (var i = 0; i < newHistory.length; i++) {
      if (newHistory[i].appName === appName) {
        newHistory[i].expanded = !newHistory[i].expanded
        break
      }
    }

    history = newHistory
  }

  function toggleDnd() {
    dndEnabled = !dndEnabled
  }

  function togglePanel() {
    panelOpen = !panelOpen
    if (panelOpen) {
      markAllAsRead()
    }
  }

  function closePanel() {
    panelOpen = false
  }

  function openSettingsNotifications() {
    // Close notification panel, open settings panel to Notifications category
    panelOpen = false
    // Use IPC to open settings panel
    settingsIpcProc.running = true
  }

  Process {
    id: settingsIpcProc
    command: ["qs", "ipc", "call", "settings", "showNotifications"]
  }

  // IPC handler for external control (e.g. qs ipc call notifications toggle)
  IpcHandler {
    target: "notifications"

    function toggle(): void { notificationManager.togglePanel() }
    function show(): void {
      notificationManager.panelOpen = true
      notificationManager.markAllAsRead()
    }
    function hide(): void { notificationManager.closePanel() }
  }

  // =========================================================================
  // DND SCHEDULE LOGIC
  // =========================================================================

  function isInDndSchedule() {
    if (!dndScheduleEnabled) return false

    var now = new Date()
    var currentMinutes = now.getHours() * 60 + now.getMinutes()
    var startMinutes = dndStartHour * 60 + dndStartMinute
    var endMinutes = dndEndHour * 60 + dndEndMinute

    // Handle overnight range (e.g., 22:00 - 08:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes
    }
    return currentMinutes >= startMinutes && currentMinutes < endMinutes
  }

  function formatTime(hour, minute) {
    var h = hour.toString().padStart(2, '0')
    var m = minute.toString().padStart(2, '0')
    return h + ":" + m
  }

  readonly property string dndScheduleText: {
    if (!dndScheduleEnabled) return "Schedule disabled"
    return formatTime(dndStartHour, dndStartMinute) + " - " + formatTime(dndEndHour, dndEndMinute)
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  function updateUnreadCount() {
    var count = 0
    for (var i = 0; i < history.length; i++) {
      for (var j = 0; j < history[i].notifications.length; j++) {
        if (!history[i].notifications[j].read) {
          count++
        }
      }
    }
    unreadCount = count
  }

  function getTotalHistoryCount() {
    var count = 0
    for (var i = 0; i < history.length; i++) {
      count += history[i].notifications.length
    }
    return count
  }

  // Check DND schedule every minute
  Timer {
    interval: 60000
    running: dndScheduleEnabled
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      // Force re-evaluation of isDndActive
      notificationManager.dndScheduleEnabled = notificationManager.dndScheduleEnabled
    }
  }
}
