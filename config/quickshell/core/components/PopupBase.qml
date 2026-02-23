import Quickshell
import Quickshell.Wayland
import QtQuick
import "../.."

// Shared PanelWindow base for popup modules. Provides layer shell config,
// ESC/ctrl+[ key handling, click-outside close, and a positioned content
// rectangle with a bordered Column inside. A narrow stem connector
// attaches the popup to the bar for a visually "connected" look.
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

  // Stem connector dimensions
  property int stemWidth: 28
  property int stemHeight: 20
  property int stemRadius: 12

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

  margins.top: StatusbarManager.popupStem ? 28 : 52
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
    id: popupRect
    x: PopupManager.anchorRight - width
    y: StatusbarManager.popupStem ? popupBase.stemHeight : 0
    width: popupBase.popupWidth
    height: popupBase.popupHeight > 0
      ? popupBase.popupHeight
      : contentColumn.implicitHeight + 48
    radius: 5
    topRightRadius: StatusbarManager.popupStem ? 0 : 5
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

  // Stem connector with inverted left corner, flush right edge.
  // The stem's right edge aligns with the popup's right edge so the
  // right border continues straight from bar to popup bottom.
  Canvas {
    visible: StatusbarManager.popupStem
    id: stemCanvas

    // The stem left edge (absolute x), used for positioning
    property real stemLeftX: PopupManager.anchorRight - popupBase.stemWidth

    // Canvas covers from stem left minus the radius (for the inverted
    // corner arc) to the popup's right edge, and from y=0 down past
    // the junction with the popup rect
    x: stemLeftX - popupBase.stemRadius
    y: 0
    width: popupBase.stemWidth + popupBase.stemRadius + 1
    height: popupBase.stemHeight + popupBase.stemRadius

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var r = popupBase.stemRadius
      var sh = popupBase.stemHeight
      var sw = popupBase.stemWidth

      // Stem left edge relative to this canvas = r (since canvas x = stemLeftX - r)
      var sl = r
      // Stem right edge relative to this canvas
      var sr = r + sw

      // Fill the stem body
      ctx.fillStyle = Colors.base.toString()
      ctx.beginPath()
      ctx.rect(sl, 0, sw, sh)
      ctx.fill()

      // Fill the inverted corner area (triangle + arc cutout on the left)
      ctx.beginPath()
      ctx.moveTo(0, sh)
      ctx.lineTo(sl, sh)
      ctx.lineTo(sl, sh - r)
      ctx.arcTo(sl, sh, 0, sh, r)
      ctx.closePath()
      ctx.fill()

      // Stroke: left border of stem + inverted corner curve
      ctx.strokeStyle = Colors.surface2.toString()
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.moveTo(sl + 0.5, 0)
      ctx.lineTo(sl + 0.5, sh - r)
      ctx.arcTo(sl + 0.5, sh, 0, sh, r)
      ctx.stroke()

      // Stroke: right border of stem (continues the popup's right border)
      ctx.beginPath()
      ctx.moveTo(sr - 0.5, 0)
      ctx.lineTo(sr - 0.5, sh)
      ctx.stroke()
    }

    onXChanged: requestPaint()
    Component.onCompleted: requestPaint()
  }

  // Cover the popup's top border under the stem (between the two border strokes)
  Rectangle {
    visible: StatusbarManager.popupStem
    x: stemCanvas.stemLeftX - 10
    y: popupBase.stemHeight
    width: popupBase.stemWidth + 9
    height: 1
    color: Colors.base
  }
}
