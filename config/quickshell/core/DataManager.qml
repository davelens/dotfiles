pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Manages user data files in $XDG_DATA_HOME/quickshell/
// Copies defaults from shellDir/defaults/ if files don't exist
Singleton {
  id: dataManager

  readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/quickshell"
  readonly property string defaultsDir: Quickshell.shellDir + "/defaults"

  // File paths for consumers
  readonly property string displaysPath: dataDir + "/displays.json"
  readonly property string notificationSettingsPath: dataDir + "/notification-settings.json"
  readonly property string statusbarPath: dataDir + "/statusbar.json"

  // Track initialization
  property bool ready: false

  Component.onCompleted: {
    ensureDataDir.running = true
  }

  // Step 1: Ensure data directory exists
  Process {
    id: ensureDataDir
    command: ["mkdir", "-p", dataDir]
    onExited: (code) => {
      checkDisplays.running = true
      checkNotificationSettings.running = true
      checkStatusbar.running = true
    }
  }

  // Step 2: Check if displays.json exists
  Process {
    id: checkDisplays
    command: ["test", "-f", dataManager.displaysPath]
    onExited: (code) => {
      if (code !== 0) {
        copyDisplays.running = true
      } else {
        displaysReady = true
        checkReady()
      }
    }
  }
  property bool displaysReady: false

  // Step 3: Copy displays.json if missing
  Process {
    id: copyDisplays
    command: ["cp", dataManager.defaultsDir + "/displays.json", dataManager.displaysPath]
    onExited: {
      displaysReady = true
      checkReady()
    }
  }

  // Step 2b: Check if notification-settings.json exists
  Process {
    id: checkNotificationSettings
    command: ["test", "-f", dataManager.notificationSettingsPath]
    onExited: (code) => {
      if (code !== 0) {
        copyNotificationSettings.running = true
      } else {
        notificationSettingsReady = true
        checkReady()
      }
    }
  }
  property bool notificationSettingsReady: false

  // Step 3b: Copy notification-settings.json if missing
  Process {
    id: copyNotificationSettings
    command: ["cp", dataManager.defaultsDir + "/notification-settings.json", dataManager.notificationSettingsPath]
    onExited: {
      notificationSettingsReady = true
      checkReady()
    }
  }

  // Check if statusbar.json exists
  Process {
    id: checkStatusbar
    command: ["test", "-f", dataManager.statusbarPath]
    onExited: (code) => {
      if (code !== 0) {
        copyStatusbar.running = true
      } else {
        statusbarReady = true
        checkReady()
      }
    }
  }
  property bool statusbarReady: false

  // Copy statusbar.json if missing
  Process {
    id: copyStatusbar
    command: ["cp", dataManager.defaultsDir + "/statusbar.json", dataManager.statusbarPath]
    onExited: {
      statusbarReady = true
      checkReady()
    }
  }

  function checkReady() {
    if (displaysReady && notificationSettingsReady && statusbarReady) {
      ready = true
    }
  }
}
