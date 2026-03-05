import QtQuick
import "../.."

// Reusable bar section that dynamically loads module components from a
// filtered StatusbarManager items list. Used for the left and center
// sections of the status bar.
Row {
  id: section

  required property var items
  required property var buildProps

  // Keyboard focus: which local delegate index has the focus ring (-1 = none)
  property int focusLocalIndex: -1

  // Expose repeater for external access (e.g., focus management)
  property alias repeater: sectionRepeater

  // Get the loaded item at a given repeater index, or null
  function itemAt(index) {
    if (index < 0 || index >= sectionRepeater.count) return null
    var delegate = sectionRepeater.itemAt(index)
    if (!delegate) return null
    // delegate children: [marginLeft Item, wrapper Item, marginRight Item]
    var wrapper = delegate.children[1]
    if (!wrapper) return null
    var loader = wrapper.children[0]
    return loader && loader.item ? loader.item : null
  }

  anchors.verticalCenter: parent.verticalCenter

  Repeater {
    id: sectionRepeater
    model: section.items.filter(function(i) { return i.enabled })

    Row {
      required property var modelData
      required property int index
      visible: !sectionLoader.item || (sectionLoader.item.showInBar !== undefined ? sectionLoader.item.showInBar : true)
      anchors.verticalCenter: parent.verticalCenter
      spacing: 0

      Item { width: modelData.marginLeft; height: 1 }

      // Wrapper for Loader + focus highlight ring
      Item {
        width: sectionLoader.width
        height: sectionLoader.height
        anchors.verticalCenter: parent.verticalCenter

        Loader {
          id: sectionLoader
          anchors.verticalCenter: parent.verticalCenter

          Component.onCompleted: {
            var relPath = ModuleRegistry.getBarComponentRelPath(modelData.id)
            if (relPath) {
              setSource("../../" + relPath, section.buildProps(modelData.id))
            }
          }
        }

        // Focus highlight ring
        Rectangle {
          anchors.fill: parent
          anchors.margins: -3
          radius: 6
          color: "transparent"
          border.width: 2
          border.color: Colors.peach
          visible: section.focusLocalIndex === index
        }
      }

      Item { width: modelData.marginRight; height: 1 }
    }
  }
}
