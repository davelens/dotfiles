import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  // Required: screen for popup management
  required property var screen

  // PopupManager passed from shell.qml for singleton consistency
  property var popupManager: PopupManager

  icon: "󰍹"

  onClicked: {
    var mapped = mapToItem(null, width, 0)
    popupManager.toggle("display", screen, mapped.x)
  }
}
