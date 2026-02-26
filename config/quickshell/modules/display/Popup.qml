import Quickshell
import QtQuick
import "../.."
import "../../core/components"

Variants {
  model: PopupManager.isOpen("display") && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PopupBase {
    popupWidth: 320
    contentSpacing: 12

    // Header
    Text {
      text: "Main display"
      color: Colors.text
      font.pixelSize: 16
    }

    // Display list
    Column {
      width: parent.width
      spacing: 4

      Repeater {
        model: Quickshell.screens

        FocusListItem {
          required property var modelData

          itemHeight: 48
          bodyMargins: 0
          bodyRadius: 4
          icon: modelData.name.startsWith("eDP") ? "󰌢" : "󰍹"
          iconSize: 18
          iconColor: DisplayConfig.isPrimary(modelData) ? Colors.blue : Colors.text
          text: DisplayConfig.friendlyName(modelData)
          fontSize: 14
          subtitle: modelData.name
          subtitleFontSize: 11
          rightIcon: DisplayConfig.isPrimary(modelData) ? "󰄬" : ""
          rightIconColor: Colors.blue
          rightIconHoverColor: Colors.blue
          backgroundColor: Colors.surface0
          hoverBackgroundColor: Colors.surface1
          onClicked: {
            DisplayConfig.setPrimary(modelData)
            PopupManager.close()
          }
        }
      }
    }
  }
}
