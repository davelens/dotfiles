import QtQuick
import "../.."

// Reusable bar section that dynamically loads module components from a
// filtered StatusbarManager items list. Used for the left and center
// sections of the status bar.
Row {
  id: section

  required property var items
  required property var buildProps

  anchors.verticalCenter: parent.verticalCenter

  Repeater {
    model: section.items.filter(function(i) { return i.enabled })

    Row {
      required property var modelData
      anchors.verticalCenter: parent.verticalCenter
      spacing: 0

      Item { width: modelData.marginLeft; height: 1 }

      Loader {
        anchors.verticalCenter: parent.verticalCenter

        Component.onCompleted: {
          var url = ModuleRegistry.getBarComponentUrl(modelData.id)
          if (url) {
            setSource(url, section.buildProps(modelData.id))
          }
        }
      }

      Item { width: modelData.marginRight; height: 1 }
    }
  }
}
