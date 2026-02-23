import Quickshell
import Quickshell.Wayland
import QtQuick
import "../.."

// Shared PanelWindow base for popup modules. Provides layer shell config,
// ESC/ctrl+[ key handling, click-outside close, and a positioned content
// rectangle with a bordered Column inside.
//
// Usage: place content items directly inside PopupBase — they become
// children of the internal Column via the default property alias.
PanelWindow {
  id: popupBase

  required property var modelData
  required property int popupWidth

  // Override for popups with complex height calculations (default: auto-fit)
  property int popupHeight: -1

  // Content column spacing (default 8, override for 12 etc.)
  property int contentSpacing: 8

  // Alias so child items land inside the content column
  default property alias content: contentColumn.data

  // Alias for popups that need to reference the column (e.g. for implicitHeight)
  readonly property alias contentColumn: contentColumn

  screen: modelData

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  margins.top: 42
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  contentItem {
    focus: true
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape
          || (event.key === Qt.Key_BracketLeft && (event.modifiers & Qt.ControlModifier))) {
        PopupManager.close()
        event.accepted = true
      }
    }
  }

  // Click outside to close
  MouseArea {
    anchors.fill: parent
    onClicked: PopupManager.close()
  }

  // Popup content rectangle
  Rectangle {
    x: PopupManager.anchorRight - width
    y: 0
    width: popupBase.popupWidth
    height: popupBase.popupHeight > 0
      ? popupBase.popupHeight
      : contentColumn.implicitHeight + 48
    color: Colors.base
    border.width: 1
    border.color: Colors.surface2

    Column {
      id: contentColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 24
      spacing: popupBase.contentSpacing
    }
  }
}
