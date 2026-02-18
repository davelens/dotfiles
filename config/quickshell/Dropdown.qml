import QtQuick

// Reusable expandable dropdown component
// Can display any list of items with customizable display
Column {
    id: dropdown
    spacing: 2

    // Required properties
    required property var items           // Array of items to display
    required property string headerIcon   // Icon shown in header
    required property string headerLabel  // Label shown in header

    // Optional properties
    property var currentItem: null        // Currently selected item (for highlighting)
    property string textRole: ""          // Property name to use for display text (if items are objects)
    property string valueRole: ""         // Property name to use for comparison (if items are objects)
    property string itemIcon: ""          // Icon to show for each item (empty = use headerIcon)
    property string selectedIcon: "\uf00c" // Icon to show for selected item

    // State
    property bool expanded: false

    // Signals
    signal itemSelected(var item)
    signal toggled(bool expanded)

    // Helper function to get display text from an item
    function getItemText(item) {
        if (!item) return "None"
        if (typeof item === "string") return item
        if (textRole && item[textRole]) return item[textRole]
        // Fallback: try common property names
        return item.description || item.name || item.text || item.label || String(item)
    }

    // Helper function to check if an item is selected
    function isItemSelected(item) {
        if (!currentItem || !item) return false
        if (valueRole) return item[valueRole] === currentItem[valueRole]
        if (typeof item === "string") return item === currentItem
        // Fallback: try common id properties
        if (item.id !== undefined && currentItem.id !== undefined) return item.id === currentItem.id
        return item === currentItem
    }

    // Header
    Rectangle {
        width: dropdown.width
        height: 28
        radius: 4
        color: headerArea.containsMouse ? Colors.surface0 : "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.headerIcon
                color: Colors.blue
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.headerLabel
                color: Colors.overlay0
                font.pixelSize: 14
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.getItemText(dropdown.currentItem)
                color: Colors.text
                font.pixelSize: 13
                elide: Text.ElideRight
                width: parent.width - 90
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.expanded ? "\uf106" : "\uf107"
                color: Colors.overlay0
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                dropdown.expanded = !dropdown.expanded
                dropdown.toggled(dropdown.expanded)
            }
        }
    }

    // Items list (shown when expanded)
    Column {
        width: dropdown.width
        spacing: 2
        visible: dropdown.expanded

        Repeater {
            model: dropdown.items

            Rectangle {
                required property var modelData
                property bool isSelected: dropdown.isItemSelected(modelData)

                width: dropdown.width
                height: 32
                radius: 4
                color: isSelected ? Colors.surface1 : (itemArea.containsMouse ? Colors.surface0 : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: isSelected ? dropdown.selectedIcon : (dropdown.itemIcon || dropdown.headerIcon)
                        color: isSelected ? Colors.green : Colors.overlay0
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: dropdown.getItemText(modelData)
                        color: isSelected ? Colors.text : Colors.subtext0
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 40
                    }
                }

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dropdown.itemSelected(modelData)
                }
            }
        }
    }
}
