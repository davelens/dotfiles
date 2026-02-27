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

  // Override to position popup with a fixed right margin from screen edge (-1 = use anchor)
  property int popupRightMargin: -1

  // Per-popup stem override (set to false to force-disable stem)
  property bool stemEnabled: true

  // Resolved stem visibility: global setting AND per-popup override
  readonly property bool showStem: StatusbarManager.popupStem && stemEnabled

  // Stem connector dimensions
  property int stemWidth: 28
  property int stemHeight: 20
  property int stemRadius: 12

  // Alias so child items land inside the content column
  default property alias content: contentColumn.data

  // Alias for popups that need to reference the column (e.g. for implicitHeight)
  readonly property alias contentColumn: contentColumn

  // Keyboard focus cycling state
  property var focusables: []
  property int focusIndex: -1

  // Recursively find visible, enabled items with showFocusRing
  function findFocusables(item, result) {
    if (!item || !item.visible) return
    if (item.showFocusRing !== undefined && item.enabled !== false) {
      result.push(item)
    }
    if (item.children) {
      for (var i = 0; i < item.children.length; i++) {
        findFocusables(item.children[i], result)
      }
    }
    if (item.contentItem) {
      findFocusables(item.contentItem, result)
    }
  }

  function refreshFocusables() {
    focusables = []
    findFocusables(contentColumn, focusables)
  }

  // Find Flickable ancestor for scroll-into-view
  function findFlickable(item) {
    var p = item ? item.parent : null
    while (p) {
      if (p.contentY !== undefined && p.contentHeight !== undefined && p.height !== undefined)
        return p
      p = p.parent
    }
    return null
  }

  function scrollToItem(item) {
    if (!item) return
    var flickable = findFlickable(item)
    if (!flickable) return
    var mapped = item.mapToItem(flickable.contentItem, 0, 0)
    var itemTop = mapped.y
    var itemBottom = itemTop + item.height
    var visibleTop = flickable.contentY
    var visibleBottom = visibleTop + flickable.height
    var padding = 24
    if (itemTop - padding < visibleTop)
      flickable.contentY = Math.max(0, itemTop - padding)
    else if (itemBottom + padding > visibleBottom)
      flickable.contentY = Math.min(flickable.contentHeight - flickable.height, itemBottom + padding - flickable.height)
  }

  function focusItem(item) {
    if (!item) return
    if (item.keyboardFocus !== undefined) item.keyboardFocus = true
    if (item.showFocusRing !== undefined) item.showFocusRing = true
    if (item.forceActiveFocus) item.forceActiveFocus()
    scrollToItem(item)
  }

  function focusNext() {
    refreshFocusables()
    if (focusables.length === 0) return
    focusIndex = (focusIndex + 1) % focusables.length
    focusItem(focusables[focusIndex])
  }

  function focusPrevious() {
    refreshFocusables()
    if (focusables.length === 0) return
    if (focusIndex < 0) focusIndex = focusables.length - 1
    else focusIndex = (focusIndex - 1 + focusables.length) % focusables.length
    focusItem(focusables[focusIndex])
  }

  function resetFocus() {
    for (var i = 0; i < focusables.length; i++) {
      if (focusables[i].keyboardFocus !== undefined)
        focusables[i].keyboardFocus = false
    }
    focusIndex = -1
    focusables = []
  }

  screen: modelData

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  // Vertical offset for content (keeps popup below the bar)
  readonly property int contentOffset: popupBase.showStem ? 28 : 52

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
        popupBase.resetFocus()
        PopupManager.close()
        event.accepted = true
      } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
        popupBase.focusNext()
        event.accepted = true
      } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
        popupBase.focusPrevious()
        event.accepted = true
      }
    }
  }

  // Dimming overlay below the bar (bar stays fully visible)
  Rectangle {
    x: 0
    y: 32
    width: popupBase.width
    height: popupBase.height - 32
    color: "#80000000"
  }

  // Click outside to close
  MouseArea {
    anchors.fill: parent
    onClicked: PopupManager.close()
  }

  // Popup content rectangle
  Rectangle {
    id: popupRect
    x: {
      if (popupBase.popupRightMargin >= 0)
        return popupBase.width - width - popupBase.popupRightMargin
      var ideal = PopupManager.anchorRight - width
      if (ideal < 0) return popupBase.width - width - 24
      return ideal
    }
    y: popupBase.contentOffset + (popupBase.showStem ? popupBase.stemHeight : 0)
    width: popupBase.popupWidth
    height: popupBase.popupHeight > 0
      ? popupBase.popupHeight
      : contentColumn.implicitHeight + 48
    radius: 5
    topRightRadius: popupBase.showStem ? 0 : 5
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
    visible: popupBase.showStem
    id: stemCanvas

    // The stem left edge (absolute x), used for positioning
    property real stemLeftX: PopupManager.anchorRight - popupBase.stemWidth

    // Canvas covers from stem left minus the radius (for the inverted
    // corner arc) to the popup's right edge, and from y=0 down past
    // the junction with the popup rect. The 2px overlap hides sub-pixel
    // gaps from fractional display scaling.
    property int overlap: 2
    x: stemLeftX - popupBase.stemRadius
    y: popupBase.contentOffset - overlap
    width: popupBase.stemWidth + popupBase.stemRadius + 1
    height: popupBase.stemHeight + popupBase.stemRadius + overlap

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var r = popupBase.stemRadius
      var sh = popupBase.stemHeight
      var sw = popupBase.stemWidth
      var ov = overlap

      // Stem left edge relative to this canvas = r (since canvas x = stemLeftX - r)
      var sl = r
      // Stem right edge relative to this canvas
      var sr = r + sw

      // Fill the stem body (starts at ov to overlap behind the bar)
      ctx.fillStyle = Colors.base.toString()
      ctx.beginPath()
      ctx.rect(sl, 0, sw, sh + ov)
      ctx.fill()

      // Fill the inverted corner area (triangle + arc cutout on the left)
      ctx.beginPath()
      ctx.moveTo(0, sh + ov)
      ctx.lineTo(sl, sh + ov)
      ctx.lineTo(sl, sh + ov - r)
      ctx.arcTo(sl, sh + ov, 0, sh + ov, r)
      ctx.closePath()
      ctx.fill()

      // Stroke: left border of stem + inverted corner curve
      ctx.strokeStyle = Colors.surface2.toString()
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.moveTo(sl + 0.5, 0)
      ctx.lineTo(sl + 0.5, sh + ov - r)
      ctx.arcTo(sl + 0.5, sh + ov, 0, sh + ov, r)
      ctx.stroke()

      // Stroke: right border of stem (continues the popup's right border)
      ctx.beginPath()
      ctx.moveTo(sr - 0.5, 0)
      ctx.lineTo(sr - 0.5, sh + ov)
      ctx.stroke()
    }

    onXChanged: requestPaint()
    Component.onCompleted: requestPaint()
  }

  // Cover the popup's top border under the stem (between the two border strokes)
  Rectangle {
    visible: popupBase.showStem
    x: stemCanvas.stemLeftX
    y: popupBase.contentOffset + popupBase.stemHeight
    width: popupBase.stemWidth - 1
    height: 1
    color: Colors.base
  }
}
