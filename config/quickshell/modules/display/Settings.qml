import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

ScrollView {
  id: settingsRoot
  anchors.fill: parent
  clip: true
  contentWidth: availableWidth

  // Search query passed from SettingsPanel
  property string searchQuery: ""

  // All outputs from sway (including disabled)
  property var outputs: []

  // Layout positions being edited
  // Each entry: { name, x, y, width, height, active, make, model, scale }
  property var layoutItems: []
  property bool layoutDirty: false
  property int selectedIndex: -1
  property int activeCount: 0

  // Gap between monitors in layout coordinates
  property int snapGap: 100

  // Drag state
  property int dragIndex: -1
  property real pendingMouseX: 0
  property real pendingMouseY: 0

  // Snap result during drag (layout coordinates)
  property real snapX: 0
  property real snapY: 0
  property real guideLineX: -1
  property real guideLineY: -1

  // Throttle snap computation to 5 times per second
  Timer {
    id: snapTimer
    interval: 200
    repeat: true
    running: settingsRoot.dragIndex >= 0
    onTriggered: {
      var layoutX = settingsRoot.fromCanvasX(settingsRoot.pendingMouseX, canvas.width, canvas.height)
      var layoutY = settingsRoot.fromCanvasY(settingsRoot.pendingMouseY, canvas.width, canvas.height)
      var snap = settingsRoot.snapPosition(settingsRoot.dragIndex, layoutX, layoutY)
      settingsRoot.snapX = snap.x
      settingsRoot.snapY = snap.y
      settingsRoot.guideLineX = snap.guideX
      settingsRoot.guideLineY = snap.guideY
    }
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

  // Parse swaymsg output JSON
  function parseOutputs(json) {
    try {
      var list = JSON.parse(json)
      outputs = list
      buildLayoutItems()
    } catch(e) {
      console.log("display settings: failed to parse outputs:", e)
    }
  }

  // Build editable layout items from sway outputs
  function buildLayoutItems() {
    var items = []
    for (var i = 0; i < outputs.length; i++) {
      var o = outputs[i]
      var mode = o.current_mode || (o.modes && o.modes.length > 0 ? o.modes[0] : null)
      var w = mode ? mode.width : 1920
      var h = mode ? mode.height : 1080
      var scale = o.scale || 1.0
      var posX = o.rect ? o.rect.x : 0
      var posY = o.rect ? o.rect.y : 0
      var logicalW = Math.round(w / scale)
      var logicalH = Math.round(h / scale)

      // Disabled monitors have 0,0 rect; offset them to the right of active monitors
      if (!o.active) {
        var maxRight = 0
        for (var j = 0; j < outputs.length; j++) {
          if (outputs[j].active && outputs[j].rect) {
            var oj = outputs[j]
            var ojMode = oj.current_mode || (oj.modes && oj.modes.length > 0 ? oj.modes[0] : null)
            var ojW = ojMode ? ojMode.width : 1920
            var ojScale = oj.scale || 1.0
            maxRight = Math.max(maxRight, oj.rect.x + Math.round(ojW / ojScale))
          }
        }
        posX = maxRight + 100
      }

      items.push({
        name: o.name,
        x: posX,
        y: posY,
        width: logicalW,
        height: logicalH,
        rawWidth: w,
        rawHeight: h,
        active: o.active,
        make: o.make || "",
        model: o.model || "",
        scale: scale,
        friendlyName: o.name.startsWith("eDP") ? "Built-in Display" : (o.model || o.name)
      })
    }
    layoutItems = items
    layoutDirty = false
    selectedIndex = -1
    var count = 0
    for (var k = 0; k < items.length; k++) {
      if (items[k].active) count++
    }
    activeCount = count

    // Cancel drag if we no longer have multiple active monitors
    if (count <= 1 && dragIndex >= 0) {
      dragIndex = -1
      guideLineX = -1
      guideLineY = -1
    }
  }

  // Cached layout bounds and scale — recomputed when layoutItems changes
  property var cachedBounds: ({ x: 0, y: 0, width: 1920, height: 1080 })
  property real cachedScale: 0.10

  onLayoutItemsChanged: updateCachedBounds()

  function updateCachedBounds() {
    var items = layoutItems
    if (items.length === 0) {
      cachedBounds = { x: 0, y: 0, width: 1920, height: 1080 }
      cachedScale = 0.10
      return
    }
    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    for (var i = 0; i < items.length; i++) {
      minX = Math.min(minX, items[i].x)
      minY = Math.min(minY, items[i].y)
      maxX = Math.max(maxX, items[i].x + items[i].width)
      maxY = Math.max(maxY, items[i].y + items[i].height)
    }
    if (minX === Infinity) {
      cachedBounds = { x: 0, y: 0, width: 1920, height: 1080 }
    } else {
      cachedBounds = { x: minX, y: minY, width: maxX - minX, height: maxY - minY }
    }

    var padding = 400
    var totalW = cachedBounds.width + padding * 2
    var totalH = cachedBounds.height + padding * 2
    var cw = (canvas && canvas.width > 0) ? canvas.width : 600
    var ch = (canvas && canvas.height > 0) ? canvas.height : 320
    cachedScale = Math.min(cw / totalW, ch / totalH, 0.10)
  }

  // Convert layout coordinates to canvas coordinates
  function toCanvasX(layoutX, cw, ch) {
    var b = cachedBounds
    return cw / 2 + (layoutX - b.x - b.width / 2) * cachedScale
  }

  function toCanvasY(layoutY, cw, ch) {
    var b = cachedBounds
    return ch / 2 + (layoutY - b.y - b.height / 2) * cachedScale
  }

  // Convert canvas coordinates back to layout coordinates
  function fromCanvasX(canvasX, cw, ch) {
    var b = cachedBounds
    return b.x + b.width / 2 + (canvasX - cw / 2) / cachedScale
  }

  function fromCanvasY(canvasY, cw, ch) {
    var b = cachedBounds
    return b.y + b.height / 2 + (canvasY - ch / 2) / cachedScale
  }

  // Edge snapping: for each other monitor, there are 8 candidate positions
  // where the dragged monitor can be placed flush:
  //
  //   TL   TC   TR
  //    L  [  ]   R
  //   BL   BC   BR
  //
  // Pick the candidate closest to the cursor.
  function snapPosition(dragIdx, proposedX, proposedY) {
    var dragged = layoutItems[dragIdx]
    var dw = dragged.width
    var dh = dragged.height
    var bestDist = Infinity
    var best = null

    for (var i = 0; i < layoutItems.length; i++) {
      if (i === dragIdx) continue
      if (!layoutItems[i].active) continue
      var o = layoutItems[i]

      // 8 positions around this monitor, offset by snapGap
      var g = settingsRoot.snapGap
      var cands = [
        // Left side
        { x: o.x - dw - g, y: o.y,               gx: o.x, gy: o.y },            // L (top-aligned)
        { x: o.x - dw - g, y: o.y - dh - g,      gx: o.x, gy: o.y },            // TL
        { x: o.x - dw - g, y: o.y + o.height + g, gx: o.x, gy: o.y + o.height }, // BL
        // Right side
        { x: o.x + o.width + g, y: o.y,               gx: o.x + o.width, gy: o.y },      // R (top-aligned)
        { x: o.x + o.width + g, y: o.y - dh - g,      gx: o.x + o.width, gy: o.y },      // TR
        { x: o.x + o.width + g, y: o.y + o.height + g, gx: o.x + o.width, gy: o.y + o.height }, // BR
        // Top side
        { x: o.x, y: o.y - dh - g,               gx: o.x, gy: o.y },            // TC (left-aligned)
        // Bottom side
        { x: o.x, y: o.y + o.height + g,         gx: o.x, gy: o.y + o.height }  // BC (left-aligned)
      ]

      for (var c = 0; c < cands.length; c++) {
        var cd = cands[c]
        // Distance from cursor to center of candidate placement
        var dx = cd.x + dw / 2 - proposedX
        var dy = cd.y + dh / 2 - proposedY
        var dist = dx * dx + dy * dy
        if (dist < bestDist) {
          bestDist = dist
          best = cd
        }
      }
    }

    if (best) {
      return { x: best.x, y: best.y, guideX: best.gx, guideY: best.gy }
    }

    return { x: Math.round(proposedX), y: Math.round(proposedY), guideX: -1, guideY: -1 }
  }

  // Normalize layout so the top-left active monitor is at 0,0
  function normalizeLayout() {
    var minX = Infinity, minY = Infinity
    for (var i = 0; i < layoutItems.length; i++) {
      if (!layoutItems[i].active) continue
      minX = Math.min(minX, layoutItems[i].x)
      minY = Math.min(minY, layoutItems[i].y)
    }
    if (minX === Infinity) return
    if (minX === 0 && minY === 0) return
    var items = layoutItems.slice()
    for (var i = 0; i < items.length; i++) {
      if (!items[i].active) continue
      items[i].x -= minX
      items[i].y -= minY
    }
    layoutItems = items
  }

  // Apply layout via swaymsg
  function applyLayout() {
    normalizeLayout()
    var cmds = []
    for (var i = 0; i < layoutItems.length; i++) {
      var item = layoutItems[i]
      if (!item.active) continue
      cmds.push("output " + item.name + " pos " + item.x + " " + item.y)
    }
    if (cmds.length === 0) return
    applyProc.command = ["swaymsg", cmds.join("; ")]
    applyProc.running = true
  }

  // Fetch outputs on load and when screens change
  Component.onCompleted: fetchProc.running = true

  Connections {
    target: Quickshell
    function onScreensChanged() { fetchProc.running = true }
  }

  Process {
    id: fetchProc
    command: ["swaymsg", "-t", "get_outputs"]
    property string output: ""
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { fetchProc.output += data }
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) settingsRoot.parseOutputs(fetchProc.output)
      fetchProc.output = ""
    }
  }

  Process {
    id: applyProc
    running: false
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        settingsRoot.layoutDirty = false
        fetchProc.running = true
      }
    }
  }

  Column {
    width: parent.width
    spacing: 20

    Text {
      text: "Displays"
      color: Colors.text
      font.pixelSize: 24
      font.bold: true
    }

    // Monitor layout section
    Text {
      text: settingsRoot.highlightText("Monitor Layout", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 14
    }

    // Canvas area
    Rectangle {
      id: canvasContainer
      width: parent.width
      height: 320
      radius: 8
      color: Colors.mantle
      clip: true

      // Hit-test: find which monitor index is at a canvas position
      function hitTest(mx, my) {
        var items = settingsRoot.layoutItems
        var s = settingsRoot.cachedScale
        // Iterate in reverse so topmost (last-drawn) wins
        for (var i = items.length - 1; i >= 0; i--) {
          if (!items[i].active) continue
          var rx = settingsRoot.toCanvasX(items[i].x, canvas.width, canvas.height)
          var ry = settingsRoot.toCanvasY(items[i].y, canvas.width, canvas.height)
          var rw = items[i].width * s
          var rh = items[i].height * s
          if (mx >= rx && mx <= rx + rw && my >= ry && my <= ry + rh) {
            return i
          }
        }
        return -1
      }

      // Single mouse area handling all interaction
      MouseArea {
        id: canvasMouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: 20
        enabled: settingsRoot.activeCount > 1
        focus: settingsRoot.dragIndex >= 0

        property int hoverIndex: -1

        cursorShape: {
          if (settingsRoot.dragIndex >= 0) return Qt.CrossCursor
          if (hoverIndex >= 0) return Qt.PointingHandCursor
          return Qt.ArrowCursor
        }

        Keys.onEscapePressed: {
          if (settingsRoot.dragIndex >= 0) {
            settingsRoot.dragIndex = -1
            settingsRoot.guideLineX = -1
            settingsRoot.guideLineY = -1
          }
        }

        onPositionChanged: mouse => {
          if (settingsRoot.dragIndex < 0) {
            hoverIndex = canvasContainer.hitTest(mouse.x, mouse.y)
            return
          }
          settingsRoot.pendingMouseX = mouse.x
          settingsRoot.pendingMouseY = mouse.y
        }

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
          // Right-click or click outside cancels drag mode
          if (settingsRoot.dragIndex >= 0) {
            if (mouse.button === Qt.RightButton) {
              settingsRoot.dragIndex = -1
              settingsRoot.guideLineX = -1
              settingsRoot.guideLineY = -1
              return
            }

            // Left click: apply the current snap position
            var items = settingsRoot.layoutItems.slice()
            items[settingsRoot.dragIndex] = Object.assign(
              {}, items[settingsRoot.dragIndex],
              { x: settingsRoot.snapX, y: settingsRoot.snapY }
            )
            settingsRoot.layoutItems = items
            settingsRoot.layoutDirty = true

            settingsRoot.dragIndex = -1
            settingsRoot.guideLineX = -1
            settingsRoot.guideLineY = -1
            return
          }

          // Not in drag mode: click a monitor to start drag mode
          if (mouse.button === Qt.LeftButton) {
            var hit = canvasContainer.hitTest(mouse.x, mouse.y)
            if (hit < 0) return
            settingsRoot.selectedIndex = hit
            settingsRoot.dragIndex = hit
            settingsRoot.pendingMouseX = mouse.x
            settingsRoot.pendingMouseY = mouse.y

            // Compute initial snap
            var layoutX = settingsRoot.fromCanvasX(mouse.x, canvas.width, canvas.height)
            var layoutY = settingsRoot.fromCanvasY(mouse.y, canvas.width, canvas.height)
            var snap = settingsRoot.snapPosition(hit, layoutX, layoutY)
            settingsRoot.snapX = snap.x
            settingsRoot.snapY = snap.y
            settingsRoot.guideLineX = snap.guideX
            settingsRoot.guideLineY = snap.guideY
          }
        }
      }

      // Monitor rectangles layer
      Item {
        id: canvas
        anchors.fill: parent
        z: 1

        Repeater {
          id: monitorRepeater
          model: settingsRoot.layoutItems.length

          Rectangle {
            id: monitorRect
            required property int index

            property var monitorData: settingsRoot.layoutItems[index] || null
            property bool isSelected: settingsRoot.selectedIndex === index

            visible: monitorData !== null
            x: monitorData ? settingsRoot.toCanvasX(monitorData.x, canvas.width, canvas.height) : 0
            y: monitorData ? settingsRoot.toCanvasY(monitorData.y, canvas.width, canvas.height) : 0
            width: monitorData ? monitorData.width * settingsRoot.cachedScale : 100
            height: monitorData ? monitorData.height * settingsRoot.cachedScale : 60

            radius: 4
            color: {
              if (!monitorData || !monitorData.active) return Colors.surface0
              if (isSelected) return Colors.surface1
              return Colors.surface0
            }
            border.width: isSelected ? 2 : 1
            border.color: {
              if (!monitorData || !monitorData.active) return Colors.surface2
              if (isSelected) return Colors.blue
              return Colors.overlay0
            }
            opacity: {
              if (!monitorData || !monitorData.active) return 0.4
              if (settingsRoot.activeCount <= 1) return 0.5
              return 1.0
            }

            // Monitor content labels
            Column {
              anchors.centerIn: parent
              spacing: 2
              visible: monitorRect.width > 60 && monitorRect.height > 40

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? (monitorData.name.startsWith("eDP") ? "󰌢" : "󰍹") : ""
                color: monitorData && monitorData.active ? Colors.text : Colors.overlay0
                font.pixelSize: Math.min(16, monitorRect.height * 0.3)
                font.family: "Symbols Nerd Font"
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? monitorData.friendlyName : ""
                color: monitorData && monitorData.active ? Colors.text : Colors.overlay0
                font.pixelSize: Math.min(11, monitorRect.height * 0.18)
                elide: Text.ElideRight
                width: monitorRect.width - 8
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? monitorData.rawWidth + "x" + monitorData.rawHeight : ""
                color: Colors.overlay0
                font.pixelSize: Math.min(9, monitorRect.height * 0.14)
              }
            }
          }
        }

        // Snap preview: shows where the monitor will land
        Rectangle {
          id: snapPreview
          visible: settingsRoot.dragIndex >= 0

          property var draggedItem: settingsRoot.dragIndex >= 0
            ? settingsRoot.layoutItems[settingsRoot.dragIndex] : null

          x: settingsRoot.toCanvasX(settingsRoot.snapX, canvas.width, canvas.height)
          y: settingsRoot.toCanvasY(settingsRoot.snapY, canvas.width, canvas.height)
          width: draggedItem ? draggedItem.width * settingsRoot.cachedScale : 0
          height: draggedItem ? draggedItem.height * settingsRoot.cachedScale : 0
          radius: 4
          color: Colors.blue
          opacity: 0.15
          border.width: 2
          border.color: Colors.blue
        }
      }

      // Vertical guide line
      Rectangle {
        visible: settingsRoot.dragIndex >= 0 && settingsRoot.guideLineX >= 0
        x: settingsRoot.guideLineX >= 0
          ? settingsRoot.toCanvasX(settingsRoot.guideLineX, canvas.width, canvas.height)
          : 0
        y: 0
        width: 1
        height: parent.height
        color: Colors.blue
        opacity: 0.5
        z: 10
      }

      // Horizontal guide line
      Rectangle {
        visible: settingsRoot.dragIndex >= 0 && settingsRoot.guideLineY >= 0
        x: 0
        y: settingsRoot.guideLineY >= 0
          ? settingsRoot.toCanvasY(settingsRoot.guideLineY, canvas.width, canvas.height)
          : 0
        width: parent.width
        height: 1
        color: Colors.blue
        opacity: 0.5
        z: 10
      }

      // Multi-monitor hint
      Text {
        visible: settingsRoot.activeCount > 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Click a monitor to reposition it"
        color: Colors.overlay0
        font.pixelSize: 11
        z: 5
      }
    }

    // Single-monitor message (below the canvas)
    Text {
      visible: settingsRoot.activeCount <= 1
      text: "Connect a second display to arrange layout"
      color: Colors.overlay0
      font.pixelSize: 12
    }

    // Apply button row
    Row {
      spacing: 12
      visible: settingsRoot.layoutDirty

      FocusButton {
        text: "Apply"
        backgroundColor: Colors.blue
        textColor: Colors.crust
        textHoverColor: Colors.crust
        onClicked: settingsRoot.applyLayout()
      }

      FocusButton {
        text: "Reset"
        backgroundColor: Colors.surface2
        onClicked: fetchProc.running = true
      }
    }

    // Primary display section
    Text {
      text: settingsRoot.highlightText("Primary Display", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 14
    }

    Rectangle {
      width: parent.width
      height: primaryColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: primaryColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 4

        Text {
          text: "Select which display hosts the status bar"
          color: Colors.overlay0
          font.pixelSize: 12
          bottomPadding: 8
        }

        Repeater {
          model: Quickshell.screens

          FocusListItem {
            required property var modelData

            itemHeight: 44
            bodyMargins: 0
            bodyRadius: 4
            icon: modelData.name.startsWith("eDP") ? "󰌢" : "󰍹"
            iconSize: 16
            iconColor: DisplayConfig.isPrimary(modelData) ? Colors.blue : Colors.text
            text: DisplayConfig.friendlyName(modelData)
            fontSize: 14
            subtitle: modelData.name
            subtitleFontSize: 11
            rightIcon: DisplayConfig.isPrimary(modelData) ? "󰄬" : ""
            rightIconColor: Colors.blue
            rightIconHoverColor: Colors.blue
            backgroundColor: Colors.surface1
            hoverBackgroundColor: Colors.surface2
            onClicked: DisplayConfig.setPrimary(modelData)
          }
        }
      }
    }
  }
}
