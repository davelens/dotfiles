import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls

Scope {
    id: root

    property bool visible: false
    property string searchQuery: ""
    property string activeCategory: "wireless"

    // Focus mode: "categories" or "content"
    property string focusMode: "categories"
    property var contentFocusables: []  // List of focusable items in current panel
    property int contentFocusIndex: -1  // Current focused item index in content

    // Categories configuration with searchable keywords
    readonly property var categories: [
        { id: "wireless", name: "Wireless", icon: "󰤨", keywords: "wifi network ssid available networks connected signal strength download upload speed settings" },
        { id: "bluetooth", name: "Bluetooth", icon: "󰂯", keywords: "devices paired connected headphones speaker mouse keyboard settings" },
        { id: "notifications", name: "Notifications", icon: "󰂚", keywords: "alerts dnd do not disturb popup history timeout schedule settings" },
        { id: "displays", name: "Displays", icon: "󰍹", keywords: "monitor screen resolution wallpaper background settings coming soon" },
        { id: "audio", name: "Audio", icon: "󰕾", keywords: "sound volume speaker microphone output input settings coming soon" },
        { id: "power", name: "Power", icon: "󰌪", keywords: "battery sleep suspend hibernate shutdown settings coming soon" }
    ]

    // Clear search and reset focus when panel is hidden
    onVisibleChanged: {
        if (!visible) {
            searchQuery = ""
            focusMode = "categories"
            contentFocusIndex = -1
        }
    }

    // Reset content focus when category changes
    onActiveCategoryChanged: {
        contentFocusIndex = -1
        contentFocusables = []
    }

    // Filter categories based on search (matches name or keywords)
    function matchesSearch(category) {
        if (!searchQuery) return true
        var query = searchQuery.toLowerCase()
        return category.name.toLowerCase().indexOf(query) !== -1 ||
               category.keywords.toLowerCase().indexOf(query) !== -1
    }

    // Highlight matching text with yellow background
    function highlightText(text, query) {
        if (!query) return text
        var lowerText = text.toLowerCase()
        var lowerQuery = query.toLowerCase()
        var idx = lowerText.indexOf(lowerQuery)
        if (idx === -1) return text
        var before = text.substring(0, idx)
        var match = text.substring(idx, idx + query.length)
        var after = text.substring(idx + query.length)
        return before + '<span style="background-color: ' + Colors.yellow + '; color: ' + Colors.crust + ';">' + match + '</span>' + after
    }

    // Get visible categories (filtered by search)
    function getVisibleCategories() {
        return categories.filter(function(cat) { return matchesSearch(cat) })
    }

    // Select next category
    function selectNextCategory() {
        var visible = getVisibleCategories()
        if (visible.length === 0) return
        var currentIndex = visible.findIndex(function(cat) { return cat.id === activeCategory })
        var nextIndex = (currentIndex + 1) % visible.length
        activeCategory = visible[nextIndex].id
    }

    // Select previous category
    function selectPreviousCategory() {
        var visible = getVisibleCategories()
        if (visible.length === 0) return
        var currentIndex = visible.findIndex(function(cat) { return cat.id === activeCategory })
        var prevIndex = (currentIndex - 1 + visible.length) % visible.length
        activeCategory = visible[prevIndex].id
    }

    // Reference to current content loader
    property var currentContentLoader: null

    // Find all focusable items in the current content
    function findFocusables(item, result) {
        if (!item) return
        // Only include items that have showFocusRing property (our custom focusable components)
        if (item.showFocusRing !== undefined) {
            result.push(item)
        }
        // Recurse into children
        if (item.children) {
            for (var i = 0; i < item.children.length; i++) {
                findFocusables(item.children[i], result)
            }
        }
        // Also check data (for Repeater items)
        if (item.contentItem) {
            findFocusables(item.contentItem, result)
        }
    }

    // Refresh the list of focusable items
    function refreshFocusables() {
        contentFocusables = []
        if (currentContentLoader && currentContentLoader.item) {
            findFocusables(currentContentLoader.item, contentFocusables)
        }
    }

    // Focus an item via keyboard (sets keyboardFocus flag)
    function focusItemViaKeyboard(item) {
        if (item) {
            if (item.keyboardFocus !== undefined) item.keyboardFocus = true
            if (item.forceActiveFocus) item.forceActiveFocus()
        }
    }

    // Focus next item in content
    function focusNextContent() {
        refreshFocusables()
        if (contentFocusables.length === 0) return
        contentFocusIndex = (contentFocusIndex + 1) % contentFocusables.length
        focusItemViaKeyboard(contentFocusables[contentFocusIndex])
    }

    // Focus previous item in content
    function focusPreviousContent() {
        refreshFocusables()
        if (contentFocusables.length === 0) return
        if (contentFocusIndex < 0) contentFocusIndex = contentFocusables.length - 1
        else contentFocusIndex = (contentFocusIndex - 1 + contentFocusables.length) % contentFocusables.length
        focusItemViaKeyboard(contentFocusables[contentFocusIndex])
    }

    // Enter content focus mode
    function enterContentMode() {
        focusMode = "content"
        refreshFocusables()
        // Re-enable focus rings on all content items
        for (var i = 0; i < contentFocusables.length; i++) {
            var item = contentFocusables[i]
            if (item && item.showFocusRing !== undefined) {
                item.showFocusRing = true
            }
        }
        contentFocusIndex = -1
        // Focus first item if available
        if (contentFocusables.length > 0) {
            contentFocusIndex = 0
            focusItemViaKeyboard(contentFocusables[0])
        }
    }

    // Return to category focus mode
    function enterCategoryMode() {
        focusMode = "categories"
        // Hide focus rings on all content items
        for (var i = 0; i < contentFocusables.length; i++) {
            var item = contentFocusables[i]
            if (item && item.showFocusRing !== undefined) {
                item.showFocusRing = false
            }
        }
        contentFocusIndex = -1
        // Return focus to panel root
        if (panelRoot) panelRoot.forceActiveFocus()
    }

    // Reference to panel root for focus management
    property var panelRoot: null

    // Reference to search input
    property var searchInputRef: null

    // Focus the search input
    function focusSearch() {
        if (searchInputRef) {
            searchInputRef.forceActiveFocus()
        }
    }

    // IPC handler to toggle visibility
    IpcHandler {
        target: "settings"

        function toggle(): void { root.visible = !root.visible }
        function show(): void { root.visible = true }
        function hide(): void { root.visible = false }
        function showNotifications(): void {
            root.activeCategory = "notifications"
            root.visible = true
        }
    }

    // Full-screen overlay with centered panel
    Variants {
        model: root.visible && DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "#80000000"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Handle keyboard input
            contentItem {
                id: panelRootItem
                focus: true
                Component.onCompleted: root.panelRoot = panelRootItem
                Keys.onPressed: event => {
                    // Ctrl+[: drop focus from search input (vim escape)
                    if (event.key === Qt.Key_BracketLeft && (event.modifiers & Qt.ControlModifier)) {
                        panelRootItem.forceActiveFocus()
                        event.accepted = true
                    }
                    // Q or Escape: close settings
                    else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                        root.visible = false
                        event.accepted = true
                    }
                    // Ctrl+L: enter content mode (focus panel content)
                    else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
                        root.enterContentMode()
                        event.accepted = true
                    }
                    // Ctrl+H: return to category mode
                    else if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
                        root.enterCategoryMode()
                        event.accepted = true
                    }
                    // Ctrl+N: next (category or content item depending on mode)
                    else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                        if (root.focusMode === "categories") {
                            root.selectNextCategory()
                        } else {
                            root.focusNextContent()
                        }
                        event.accepted = true
                    }
                    // Ctrl+P: previous (category or content item depending on mode)
                    else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
                        if (root.focusMode === "categories") {
                            root.selectPreviousCategory()
                        } else {
                            root.focusPreviousContent()
                        }
                        event.accepted = true
                    }
                    // Ctrl+F: focus search input
                    else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
                        root.focusSearch()
                        event.accepted = true
                    }
                }
            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.visible = false
            }

            // Centered panel
            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: parent.width * 0.6
                height: parent.height * 0.7
                color: Colors.base
                radius: 8

                // Prevent clicks inside panel from closing
                MouseArea {
                    anchors.fill: parent
                    onClicked: {} // absorb click
                }

                // Border
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.surface2
                    radius: parent.radius
                    z: 100
                }

                // Main layout
                Column {
                    anchors.fill: parent

                    // Search bar
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Colors.mantle
                        radius: 8

                        // Cover bottom corners
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 8
                            color: Colors.mantle
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍉"
                                color: Colors.overlay0
                                font.pixelSize: 18
                                font.family: "Symbols Nerd Font"
                            }

                            TextInput {
                                id: searchInput
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 40
                                color: Colors.text
                                font.pixelSize: 14
                                clip: true
                                focus: true
                                Component.onCompleted: root.searchInputRef = searchInput

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: searchInput.forceActiveFocus()
                                }

                                Text {
                                    anchors.fill: parent
                                    text: "Search settings..."
                                    color: Colors.overlay0
                                    font.pixelSize: 14
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }

                                onTextChanged: root.searchQuery = text
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Colors.surface0
                        }
                    }

                    // Content area
                    Row {
                        width: parent.width
                        height: parent.height - 56

                        // Sidebar
                        Rectangle {
                            id: sidebar
                            width: 200
                            height: parent.height
                            color: Colors.mantle

                            // Cover bottom-left corner
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: 8
                                height: 8
                                color: Colors.mantle
                                radius: 8

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    width: 8
                                    height: 8
                                    color: Colors.mantle
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.topMargin: 8
                                spacing: 2

                                Repeater {
                                    model: root.categories

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        width: sidebar.width
                                        height: visible ? 44 : 0
                                        visible: root.matchesSearch(modelData)
                                        color: root.activeCategory === modelData.id ? Colors.surface0 :
                                               categoryArea.containsMouse ? Colors.surface0 : "transparent"

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 3
                                            height: 24
                                            radius: 2
                                            color: Colors.blue
                                            visible: root.activeCategory === modelData.id
                                        }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 12

                                            Text {
                                                width: 20
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.icon
                                                color: root.activeCategory === modelData.id ? Colors.blue : Colors.text
                                                font.pixelSize: 16
                                                font.family: "Symbols Nerd Font"
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.name
                                                color: root.activeCategory === modelData.id ? Colors.text : Colors.subtext0
                                                font.pixelSize: 14
                                            }
                                        }

                                        MouseArea {
                                            id: categoryArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.activeCategory = modelData.id
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                width: 1
                                height: parent.height
                                color: Colors.surface0
                            }
                        }

                        // Main content
                        Rectangle {
                            width: parent.width - sidebar.width
                            height: parent.height
                            color: Colors.base
                            radius: 8

                            // Only round bottom-right
                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: parent.radius
                                color: Colors.base
                            }
                            Rectangle {
                                anchors.left: parent.left
                                width: parent.radius
                                height: parent.height
                                color: Colors.base
                            }

                            Loader {
                                id: contentLoader
                                anchors.fill: parent
                                anchors.margins: 24
                                sourceComponent: {
                                    switch (root.activeCategory) {
                                        case "wireless": return wirelessContent
                                        case "bluetooth": return bluetoothContent
                                        case "notifications": return notificationsContent
                                        case "displays": return displaysContent
                                        case "audio": return audioContent
                                        case "power": return powerContent
                                        default: return placeholderContent
                                    }
                                }
                                onLoaded: root.currentContentLoader = contentLoader
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== Content Components ====================

    Component {
        id: wirelessContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Row {
                    spacing: 16

                    Text {
                        text: "Wireless"
                        color: Colors.text
                        font.pixelSize: 24
                        font.bold: true
                    }

                SwitchToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: WirelessManager.enabled
                    onClicked: WirelessManager.toggleEnabled()
                }
            }

            Rectangle {
                width: parent.width
                height: 80
                radius: 8
                color: Colors.surface0
                visible: WirelessManager.connectedNetwork !== null

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : ""
                        color: Colors.text
                        font.pixelSize: 16
                    }

                    Text {
                        text: root.highlightText("Connected", root.searchQuery)
                        textFormat: Text.RichText
                        color: Colors.green
                        font.pixelSize: 12
                    }

                    Row {
                        spacing: 16

                        Text {
                            text: "Down: " + WirelessManager.formatSpeed(WirelessManager.downloadSpeed)
                            color: Colors.overlay0
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Up: " + WirelessManager.formatSpeed(WirelessManager.uploadSpeed)
                            color: Colors.overlay0
                            font.pixelSize: 12
                        }
                    }
                }

                FocusLink {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Disconnect"
                    onClicked: WirelessManager.disconnect()
                }
            }

            // Separator after connected network
            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surface1
                visible: WirelessManager.connectedNetwork !== null
            }

            Column {
                width: parent.width
                spacing: 6
                visible: WirelessManager.enabled

                Row {
                    spacing: 8

                    Text {
                        text: WirelessManager.scanning ? "Scanning..." : root.highlightText("Available Networks", root.searchQuery)
                        textFormat: Text.RichText
                        color: Colors.subtext0
                        font.pixelSize: 14
                    }

                    FocusIconButton {
                        icon: "󰑐"
                        visible: !WirelessManager.scanning
                        onClicked: WirelessManager.startScan()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: WirelessManager.networks.filter(function(n) { return !n.active })

                        FocusListItem {
                            required property var modelData

                            icon: WirelessManager.getSignalIcon(modelData.signal)
                            text: modelData.ssid
                            rightIcon: modelData.security ? "󰌾" : ""
                            onClicked: WirelessManager.connect(modelData.ssid)
                        }
                    }
                }
            }
            }
        }
    }

    Component {
        id: bluetoothContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Row {
                    spacing: 16

                    Text {
                        text: "Bluetooth"
                        color: Colors.text
                        font.pixelSize: 24
                        font.bold: true
                    }

                SwitchToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: BluetoothManager.powered
                    onClicked: BluetoothManager.togglePower()
                }
            }

            // Connected devices list
            Column {
                width: parent.width
                spacing: 4
                visible: BluetoothManager.powered && BluetoothManager.connectedDevices.length > 0

                Repeater {
                    model: BluetoothManager.connectedDevices

                    Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 64
                        radius: 8
                        color: Colors.surface0

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂱"
                                color: Colors.blue
                                font.pixelSize: 18
                                font.family: "Symbols Nerd Font"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: root.highlightText("Connected", root.searchQuery)
                                    textFormat: Text.RichText
                                    color: Colors.green
                                    font.pixelSize: 12
                                }
                            }
                        }

                        FocusLink {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Disconnect"
                            onClicked: BluetoothManager.disconnect(modelData.address)
                        }
                    }
                }
            }

            // Separator after connected devices
            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surface1
                visible: BluetoothManager.powered && BluetoothManager.connectedDevices.length > 0
            }

            // Devices section with header and list
            Column {
                width: parent.width
                spacing: 6
                visible: BluetoothManager.powered

                Row {
                    spacing: 8

                    Text {
                        text: BluetoothManager.scanning ? "Scanning..." : root.highlightText("Available Devices", root.searchQuery)
                        textFormat: Text.RichText
                        color: Colors.subtext0
                        font.pixelSize: 14
                    }

                    FocusIconButton {
                        icon: "󰑐"
                        visible: !BluetoothManager.scanning
                        onClicked: BluetoothManager.startScan()
                    }
                }

                // Device list (paired but not connected, and discovered)
                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: BluetoothManager.devices.filter(function(d) { return !d.connected })

                        FocusListItem {
                            required property var modelData

                            icon: modelData.paired ? "󰂰" : "󰂯"
                            iconColor: modelData.paired ? Colors.blue : Colors.overlay0
                            text: modelData.name
                            subtitle: modelData.paired ? "Paired" : "Not paired"
                            onClicked: {
                                if (!BluetoothManager.busy) {
                                    BluetoothManager.connect(modelData.address)
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        text: BluetoothManager.scanning ? "Looking for devices..." : "No devices found"
                        color: Colors.overlay0
                        font.pixelSize: 13
                        visible: BluetoothManager.devices.filter(function(d) { return !d.connected }).length === 0
                        topPadding: 8
                    }
                }
            }

            // Bluetooth off state
            Column {
                width: parent.width
                spacing: 8
                visible: !BluetoothManager.powered

                Text {
                    text: "Bluetooth is off"
                    color: Colors.overlay0
                    font.pixelSize: 14
                    topPadding: 16
                }

                Text {
                    text: "Turn on Bluetooth to connect to devices"
                    color: Colors.overlay1
                    font.pixelSize: 12
                }
            }
            }
        }
    }

    Component {
        id: notificationsContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 20

                Text {
                    text: "Notifications"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                // Preview section
                Rectangle {
                    width: parent.width
                    height: previewColumn.height + 32
                    radius: 8
                    color: Colors.mantle

                Column {
                    id: previewColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "Preview"
                        color: Colors.overlay0
                        font.pixelSize: 12
                    }

                    // Preview notification card
                    NotificationCard {
                        width: Math.min(parent.width, 360)
                        appName: "Example App"
                        appIcon: ""
                        summary: "This is a notification"
                        body: "Here's what your notifications look like when they appear."
                        urgency: NotificationUrgency.Normal
                        showCloseButton: true
                        compact: false
                    }

                    // Test notification button
                    FocusButton {
                        text: "Send Test Notification"
                        onClicked: testNotifyProc.running = true
                    }

                    Process {
                        id: testNotifyProc
                        command: ["notify-send", "-a", "Quickshell", "Test Notification", "This is a test notification from the settings panel."]
                    }
                }
            }

            // Popup Settings
            Text {
                text: root.highlightText("Popup Settings", root.searchQuery)
                textFormat: Text.RichText
                color: Colors.subtext0
                font.pixelSize: 14
            }

            Rectangle {
                width: parent.width
                height: popupSettingsColumn.height + 24
                radius: 8
                color: Colors.surface0

                Column {
                    id: popupSettingsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 16

                    // Timeout slider
                    Column {
                        width: parent.width
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 20

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Auto-dismiss timeout"
                                color: Colors.subtext1
                                font.pixelSize: 15
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (NotificationManager.popupTimeout / 1000) + "s"
                                color: Colors.text
                                font.pixelSize: 15
                            }
                        }

                        FocusSlider {
                            width: parent.width
                            from: 1000
                            to: 30000
                            stepSize: 1000
                            value: NotificationManager.popupTimeout
                            onValueChanged: NotificationManager.popupTimeout = value
                        }
                    }
                }
            }

            // History Settings
            Text {
                text: root.highlightText("History", root.searchQuery)
                textFormat: Text.RichText
                color: Colors.subtext0
                font.pixelSize: 15
            }

            Rectangle {
                width: parent.width
                height: historySettingsColumn.height + 24
                radius: 8
                color: Colors.surface0

                Column {
                    id: historySettingsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 16

                    // Max history size slider
                    Column {
                        width: parent.width
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 20

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Maximum history size"
                                color: Colors.subtext1
                                font.pixelSize: 15
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: NotificationManager.maxHistorySize + " notifications"
                                color: Colors.text
                                font.pixelSize: 15
                            }
                        }

                        FocusSlider {
                            width: parent.width
                            from: 10
                            to: 200
                            stepSize: 10
                            value: NotificationManager.maxHistorySize
                            onValueChanged: NotificationManager.maxHistorySize = value
                        }
                    }

                    // Clear history button
                    FocusButton {
                        width: 140
                        text: "Clear History"
                        backgroundColor: Colors.surface2
                        textHoverColor: Colors.red
                        visible: NotificationManager.getTotalHistoryCount() > 0
                        onClicked: NotificationManager.clearHistory()
                    }
                }
            }

            // Do Not Disturb Settings
            Text {
                text: root.highlightText("Do Not Disturb", root.searchQuery)
                textFormat: Text.RichText
                color: Colors.subtext0
                font.pixelSize: 14
            }

            Rectangle {
                width: parent.width
                height: dndSettingsColumn.height + 24
                radius: 8
                color: Colors.surface0

                Column {
                    id: dndSettingsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 16

                    // DND Schedule toggle
                    Row {
                        width: parent.width
                        spacing: 12

                        SwitchToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: NotificationManager.dndScheduleEnabled
                            onClicked: NotificationManager.dndScheduleEnabled = !NotificationManager.dndScheduleEnabled
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enable DND schedule"
                            color: Colors.text
                            font.pixelSize: 14
                        }
                    }

                    // Time pickers (visible when schedule enabled)
                    Column {
                        width: parent.width
                        spacing: 16
                        visible: NotificationManager.dndScheduleEnabled

                        // Start time
                        Row {
                            spacing: 16

                            Text {
                                width: 80
                                text: "Start time"
                                color: Colors.text
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TimePicker {
                                hours: NotificationManager.dndStartHour
                                minutes: NotificationManager.dndStartMinute
                                onHoursChanged: NotificationManager.dndStartHour = hours
                                onMinutesChanged: NotificationManager.dndStartMinute = minutes
                            }
                        }

                        // End time
                        Row {
                            spacing: 16

                            Text {
                                width: 80
                                text: "End time"
                                color: Colors.text
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TimePicker {
                                hours: NotificationManager.dndEndHour
                                minutes: NotificationManager.dndEndMinute
                                onHoursChanged: NotificationManager.dndEndHour = hours
                                onMinutesChanged: NotificationManager.dndEndMinute = minutes
                            }
                        }

                        // Schedule status
                        Text {
                            text: "DND will be active from " + NotificationManager.formatTime(NotificationManager.dndStartHour, NotificationManager.dndStartMinute) +
                                  " to " + NotificationManager.formatTime(NotificationManager.dndEndHour, NotificationManager.dndEndMinute)
                            color: Colors.overlay0
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Advanced Settings
            Text {
                text: root.highlightText("Advanced", root.searchQuery)
                textFormat: Text.RichText
                color: Colors.subtext0
                font.pixelSize: 14
            }

            Rectangle {
                width: parent.width
                height: advancedSettingsColumn.height + 24
                radius: 8
                color: Colors.surface0

                Column {
                    id: advancedSettingsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 12

                    // Critical bypass DND toggle
                    Row {
                        width: parent.width
                        spacing: 12

                        SwitchToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: NotificationManager.criticalBypassDnd
                            onClicked: NotificationManager.criticalBypassDnd = !NotificationManager.criticalBypassDnd
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Critical notifications bypass DND"
                                color: Colors.text
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Show critical notifications even when Do Not Disturb is enabled"
                                color: Colors.overlay0
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
            }
        }
    }

    Component {
        id: displaysContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Text {
                    text: "Displays"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text: root.highlightText("Display settings coming soon", root.searchQuery)
                    textFormat: Text.RichText
                    color: Colors.overlay0
                    font.pixelSize: 14
                }
            }
        }
    }

    Component {
        id: audioContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Text {
                    text: "Audio"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text: root.highlightText("Audio settings coming soon", root.searchQuery)
                    textFormat: Text.RichText
                    color: Colors.overlay0
                    font.pixelSize: 14
                }
            }
        }
    }

    Component {
        id: powerContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Text {
                    text: "Power"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text: root.highlightText("Power settings coming soon", root.searchQuery)
                    textFormat: Text.RichText
                    color: Colors.overlay0
                    font.pixelSize: 14
                }
            }
        }
    }

    Component {
        id: placeholderContent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 16

                Text {
                    text: "Select a category"
                    color: Colors.overlay0
                    font.pixelSize: 14
                }
            }
        }
    }
}
