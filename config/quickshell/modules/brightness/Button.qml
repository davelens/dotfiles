import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  popupId: "brightness"
  icon: BrightnessManager.getIcon(BrightnessManager.averageLevel)

  onWheel: event => {
    var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
    for (var i = 0; i < BrightnessManager.displays.length; i++) {
      var d = BrightnessManager.displays[i]
      var newLevel = Math.max(0.01, Math.min(1, d.brightness + delta))
      BrightnessManager.setBrightness(d.id, newLevel)
    }
  }
}
