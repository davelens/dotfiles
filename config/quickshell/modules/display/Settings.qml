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

  // Layout positions being edited (keyed by output name)
  // Each entry: { name, x, y, width, height, active, make, model, scale }
  property var layoutItems: []
  property bool layoutDirty: false
  property int selectedIndex: -1

  // Snap threshold in logical pixels (in the canvas coordinate space)
  property int snapThreshold: 12

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
    // First pass: collect active monitors
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
  }

  // Calculate the bounding box of all layout items
  function layoutBounds() {
    if (layoutItems.length === 0) return { x: 0, y: 0, width: 1920, height: 1080 }
    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    for (var i = 0; i < layoutItems.length; i++) {
      var item = layoutItems[i]
      if (!item.active) continue
      minX = Math.min(minX, item.x)
      minY = Math.min(minY, item.y)
      maxX = Math.max(maxX, item.x + item.width)
      maxY = Math.max(maxY, item.y + item.height)
    }
    if (minX === Infinity) {
      // All disabled, use first item
      return { x: 0, y: 0, width: layoutItems[0].width, height: layoutItems[0].height }
    }
    return { x: minX, y: minY, width: maxX - minX, height: maxY - minY }
  }

  // Calculate scale factor to fit layout in the canvas
  function canvasScale(canvasWidth, canvasHeight) {
    var bounds = layoutBounds()
    // Add padding around the layout
    var padding = 200
    var totalW = bounds.width + padding * 2
    var totalH = bounds.height + padding * 2
    var scaleX = canvasWidth / totalW
    var scaleY = canvasHeight / totalH
    return Math.min(scaleX, scaleY, 0.15)
  }

  // Convert layout coordinates to canvas coordinates
  function toCanvasX(layoutX, canvasWidth, canvasHeight) {
    var bounds = layoutBounds()
    var s = canvasScale(canvasWidth, canvasHeight)
    var centerX = canvasWidth / 2
    var boundsCenter = bounds.x + bounds.width / 2
    return centerX + (layoutX - boundsCenter) * s
  }

  function toCanvasY(layoutY, canvasWidth, canvasHeight) {
    var bounds = layoutBounds()
    var s = canvasScale(canvasWidth, canvasHeight)
    var centerY = canvasHeight / 2
    var boundsCenter = bounds.y + bounds.height / 2
    return centerY + (layoutY - boundsCenter) * s
  }

  // Convert canvas coordinates back to layout coordinates
  function fromCanvasX(canvasX, canvasWidth, canvasHeight) {
    var bounds = layoutBounds()
    var s = canvasScale(canvasWidth, canvasHeight)
    var centerX = canvasWidth / 2
    var boundsCenter = bounds.x + bounds.width / 2
    return boundsCenter + (canvasX - centerX) / s
  }

  function fromCanvasY(canvasY, canvasWidth, canvasHeight) {
    var bounds = layoutBounds()
    var s = canvasScale(canvasWidth, canvasHeight)
    var centerY = canvasHeight / 2
    var boundsCenter = bounds.y + bounds.height / 2
    return boundsCenter + (canvasY - centerY) / s
  }

  // Edge snapping: find the best snap position for a dragged monitor
  // Returns { x, y } with snapped coordinates
  function snapPosition(dragIndex, proposedX, proposedY) {
    var dragged = layoutItems[dragIndex]
    var dw = dragged.width
    var dh = dragged.height
    var bestX = proposedX
    var bestY = proposedY
    var bestDistX = snapThreshold + 1
    var bestDistY = snapThreshold + 1

    // Convert snap threshold to layout coordinates
    var s = canvasScale(canvas.width, canvas.height)
    var layoutSnapThreshold = snapThreshold / s

    for (var i = 0; i < layoutItems.length; i++) {
      if (i === dragIndex) continue
      if (!layoutItems[i].active) continue

      var other = layoutItems[i]
      var ox = other.x
      var oy = other.y
      var ow = other.width
      var oh = other.height

      // Horizontal snapping (x-axis)
      // Right edge of dragged -> left edge of other
      var dist = Math.abs((proposedX + dw) - ox)
      if (dist < layoutSnapThreshold && dist < bestDistX) {
        bestDistX = dist
        bestX = ox - dw
      }
      // Left edge of dragged -> right edge of other
      dist = Math.abs(proposedX - (ox + ow))
      if (dist < layoutSnapThreshold && dist < bestDistX) {
        bestDistX = dist
        bestX = ox + ow
      }
      // Left edge of dragged -> left edge of other
      dist = Math.abs(proposedX - ox)
      if (dist < layoutSnapThreshold && dist < bestDistX) {
        bestDistX = dist
        bestX = ox
      }
      // Right edge of dragged -> right edge of other
      dist = Math.abs((proposedX + dw) - (ox + ow))
      if (dist < layoutSnapThreshold && dist < bestDistX) {
        bestDistX = dist
        bestX = ox + ow - dw
      }

      // Vertical snapping (y-axis)
      // Bottom edge of dragged -> top edge of other
      dist = Math.abs((proposedY + dh) - oy)
      if (dist < layoutSnapThreshold && dist < bestDistY) {
        bestDistY = dist
        bestY = oy - dh
      }
      // Top edge of dragged -> bottom edge of other
      dist = Math.abs(proposedY - (oy + oh))
      if (dist < layoutSnapThreshold && dist < bestDistY) {
        bestDistY = dist
        bestY = oy + oh
      }
      // Top edge of dragged -> top edge of other
      dist = Math.abs(proposedY - oy)
      if (dist < layoutSnapThreshold && dist < bestDistY) {
        bestDistY = dist
        bestY = oy
      }
      // Bottom edge of dragged -> bottom edge of other
      dist = Math.abs((proposedY + dh) - (oy + oh))
      if (dist < layoutSnapThreshold && dist < bestDistY) {
        bestDistY = dist
        bestY = oy + oh - dh
      }
    }

    return { x: Math.round(bestX), y: Math.round(bestY) }
  }

  // Normalize layout so the top-left monitor is at 0,0
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

  // Fetch outputs on load
  Component.onCompleted: {
    fetchProc.running = true
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
        // Refresh after applying
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
      width: parent.width
      height: 320
      radius: 8
      color: Colors.mantle

      // Grid pattern hint
      Canvas {
        id: gridCanvas
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.strokeStyle = Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.3)
          ctx.lineWidth = 1
          var gridSize = 40
          for (var x = gridSize; x < width; x += gridSize) {
            ctx.beginPath()
            ctx.moveTo(x, 0)
            ctx.lineTo(x, height)
            ctx.stroke()
          }
          for (var y = gridSize; y < height; y += gridSize) {
            ctx.beginPath()
            ctx.moveTo(0, y)
            ctx.lineTo(width, y)
            ctx.stroke()
          }
        }
        Component.onCompleted: requestPaint()
      }

      // Monitor rectangles
      Item {
        id: canvas
        anchors.fill: parent
        anchors.margins: 8

        Repeater {
          id: monitorRepeater
          model: settingsRoot.layoutItems.length

          Rectangle {
            id: monitorRect
            required property int index

            property var monitorData: settingsRoot.layoutItems[index] || null
            property bool isSelected: settingsRoot.selectedIndex === index
            property bool isDragging: dragArea.drag.active

            visible: monitorData !== null
            x: monitorData ? settingsRoot.toCanvasX(monitorData.x, canvas.width, canvas.height) : 0
            y: monitorData ? settingsRoot.toCanvasY(monitorData.y, canvas.width, canvas.height) : 0
            width: monitorData ? monitorData.width * settingsRoot.canvasScale(canvas.width, canvas.height) : 100
            height: monitorData ? monitorData.height * settingsRoot.canvasScale(canvas.width, canvas.height) : 60

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
            opacity: monitorData && monitorData.active ? 1.0 : 0.4

            // Drag support
            Drag.active: dragArea.drag.active

            MouseArea {
              id: dragArea
              anchors.fill: parent
              drag.target: monitorData && monitorData.active ? monitorRect : null
              cursorShape: monitorData && monitorData.active ? Qt.SizeAllCursor : Qt.ArrowCursor
              hoverEnabled: true

              property real startX: 0
              property real startY: 0
              property real startLayoutX: 0
              property real startLayoutY: 0

              onPressed: mouse => {
                if (!monitorData || !monitorData.active) return
                settingsRoot.selectedIndex = index
                startX = monitorRect.x
                startY = monitorRect.y
                startLayoutX = monitorData.x
                startLayoutY = monitorData.y
              }

              onPositionChanged: mouse => {
                if (!drag.active || !monitorData) return

                // Convert current canvas position to layout coordinates
                var proposedX = settingsRoot.fromCanvasX(monitorRect.x, canvas.width, canvas.height)
                var proposedY = settingsRoot.fromCanvasY(monitorRect.y, canvas.width, canvas.height)

                // Apply snapping
                var snapped = settingsRoot.snapPosition(index, proposedX, proposedY)

                // Update layout item
                var items = settingsRoot.layoutItems.slice()
                items[index] = Object.assign({}, items[index], { x: snapped.x, y: snapped.y })
                settingsRoot.layoutItems = items
                settingsRoot.layoutDirty = true

                // Snap the visual position too
                monitorRect.x = settingsRoot.toCanvasX(snapped.x, canvas.width, canvas.height)
                monitorRect.y = settingsRoot.toCanvasY(snapped.y, canvas.width, canvas.height)
              }

              onReleased: {
                settingsRoot.layoutDirty = true
              }

              onClicked: mouse => {
                settingsRoot.selectedIndex = index
              }
            }

            // Monitor content
            Column {
              anchors.centerIn: parent
              spacing: 2
              visible: monitorRect.width > 60 && monitorRect.height > 40

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? (monitorData.name.startsWith("eDP") ? "󰌢" : "󰍹") : ""
                color: monitorData && monitorData.active ? Colors.text : Colors.overlay0
                font.pixelSize: Math.min(16, monitorRect.height * 0.25)
                font.family: "Symbols Nerd Font"
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? monitorData.friendlyName : ""
                color: monitorData && monitorData.active ? Colors.text : Colors.overlay0
                font.pixelSize: Math.min(11, monitorRect.height * 0.15)
                elide: Text.ElideRight
                width: monitorRect.width - 8
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: monitorData ? monitorData.rawWidth + "x" + monitorData.rawHeight : ""
                color: Colors.overlay0
                font.pixelSize: Math.min(9, monitorRect.height * 0.12)
              }
            }
          }
        }
      }

      // Instructions text
      Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: settingsRoot.layoutItems.length > 1 ? "Drag monitors to arrange them" : "Connect additional monitors to arrange layout"
        color: Colors.overlay0
        font.pixelSize: 11
      }
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
