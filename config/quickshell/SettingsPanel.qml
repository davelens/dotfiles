import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property bool visible: false
    property string searchQuery: ""
    property string activeCategory: "wireless"

    // Categories configuration with searchable keywords
    readonly property var categories: [
        { id: "wireless", name: "Wireless", icon: "󰤨", keywords: "wifi network ssid available networks connected signal strength download upload speed settings" },
        { id: "bluetooth", name: "Bluetooth", icon: "󰂯", keywords: "devices paired connected headphones speaker mouse keyboard settings" },
        { id: "displays", name: "Displays", icon: "󰍹", keywords: "monitor screen resolution wallpaper background settings coming soon" },
        { id: "audio", name: "Audio", icon: "󰕾", keywords: "sound volume speaker microphone output input settings coming soon" },
        { id: "power", name: "Power", icon: "󰌪", keywords: "battery sleep suspend hibernate shutdown settings coming soon" }
    ]

    // Clear search when panel is hidden
    onVisibleChanged: {
        if (!visible) {
            searchQuery = ""
        }
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

    // IPC handler to toggle visibility
    IpcHandler {
        target: "settings"

        function toggle(): void { root.visible = !root.visible }
        function show(): void { root.visible = true }
        function hide(): void { root.visible = false }
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
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.visible = false
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
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.icon
                                                color: root.activeCategory === modelData.id ? Colors.blue : Colors.text
                                                font.pixelSize: 16
                                                font.family: "Symbols Nerd Font"
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
                                anchors.fill: parent
                                anchors.margins: 24
                                sourceComponent: {
                                    switch (root.activeCategory) {
                                        case "wireless": return wirelessContent
                                        case "bluetooth": return bluetoothContent
                                        case "displays": return displaysContent
                                        case "audio": return audioContent
                                        case "power": return powerContent
                                        default: return placeholderContent
                                    }
                                }
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

        Column {
            spacing: 16

            Row {
                spacing: 16

                Text {
                    text: "Wireless"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 22
                    radius: 11
                    color: WirelessManager.enabled ? Colors.blue : Colors.surface0

                    Rectangle {
                        x: WirelessManager.enabled ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.text
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WirelessManager.toggleEnabled()
                    }
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

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Disconnect"
                    color: wifiDisconnectArea.containsMouse ? Colors.red : Colors.overlay0
                    font.pixelSize: 13

                    MouseArea {
                        id: wifiDisconnectArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WirelessManager.disconnect()
                    }
                }
            }

            Row {
                spacing: 8
                visible: WirelessManager.enabled

                Text {
                    text: WirelessManager.scanning ? "Scanning..." : root.highlightText("Available Networks", root.searchQuery)
                    textFormat: Text.RichText
                    color: Colors.overlay0
                    font.pixelSize: 12
                }

                Text {
                    text: "󰑐"
                    color: wifiRefreshArea.containsMouse ? Colors.blue : Colors.overlay0
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                    visible: !WirelessManager.scanning

                    MouseArea {
                        id: wifiRefreshArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WirelessManager.startScan()
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                visible: WirelessManager.enabled

                Repeater {
                    model: WirelessManager.networks.filter(function(n) { return !n.active })

                    Rectangle {
                        required property var modelData

                        width: parent.width
                        height: 48
                        radius: 6
                        color: wifiNetArea.containsMouse ? Colors.surface0 : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: WirelessManager.getSignalIcon(modelData.signal)
                                color: Colors.overlay0
                                font.pixelSize: 16
                                font.family: "Symbols Nerd Font"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.ssid
                                color: Colors.text
                                font.pixelSize: 14
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.security ? "󰌾" : ""
                            color: Colors.overlay0
                            font.pixelSize: 14
                            font.family: "Symbols Nerd Font"
                        }

                        MouseArea {
                            id: wifiNetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WirelessManager.connect(modelData.ssid)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothContent

        Column {
            spacing: 16

            Row {
                spacing: 16

                Text {
                    text: "Bluetooth"
                    color: Colors.text
                    font.pixelSize: 24
                    font.bold: true
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 22
                    radius: 11
                    color: BluetoothManager.powered ? Colors.blue : Colors.surface0

                    Rectangle {
                        x: BluetoothManager.powered ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.text
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothManager.togglePower()
                    }
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

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Disconnect"
                            color: btDisconnectArea.containsMouse ? Colors.red : Colors.overlay0
                            font.pixelSize: 13

                            MouseArea {
                                id: btDisconnectArea
                                anchors.fill: parent
                                anchors.margins: -8
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothManager.disconnect(modelData.address)
                            }
                        }
                    }
                }
            }

            // Devices header with scan status
            Row {
                spacing: 8
                visible: BluetoothManager.powered

                Text {
                    text: BluetoothManager.scanning ? "Scanning..." : root.highlightText("Available Devices", root.searchQuery)
                    textFormat: Text.RichText
                    color: Colors.overlay0
                    font.pixelSize: 12
                }

                Text {
                    text: "󰑐"
                    color: btRefreshArea.containsMouse ? Colors.blue : Colors.overlay0
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                    visible: !BluetoothManager.scanning

                    MouseArea {
                        id: btRefreshArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothManager.startScan()
                    }
                }
            }

            // Device list (paired but not connected, and discovered)
            Column {
                width: parent.width
                spacing: 2
                visible: BluetoothManager.powered

                Repeater {
                    model: BluetoothManager.devices.filter(function(d) { return !d.connected })

                    Rectangle {
                        required property var modelData

                        width: parent.width
                        height: 48
                        radius: 6
                        color: btDeviceArea.containsMouse ? Colors.surface0 : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.paired ? "󰂰" : "󰂯"
                                color: modelData.paired ? Colors.blue : Colors.overlay0
                                font.pixelSize: 16
                                font.family: "Symbols Nerd Font"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: modelData.paired ? "Paired" : "Not paired"
                                    color: Colors.overlay0
                                    font.pixelSize: 11
                                }
                            }
                        }

                        MouseArea {
                            id: btDeviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: BluetoothManager.busy ? Qt.WaitCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!BluetoothManager.busy) {
                                    BluetoothManager.connect(modelData.address)
                                }
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

    Component {
        id: displaysContent

        Column {
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

    Component {
        id: audioContent

        Column {
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

    Component {
        id: powerContent

        Column {
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

    Component {
        id: placeholderContent

        Column {
            spacing: 16

            Text {
                text: "Select a category"
                color: Colors.overlay0
                font.pixelSize: 14
            }
        }
    }
}
