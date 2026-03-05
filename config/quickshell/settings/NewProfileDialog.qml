import QtQuick
import ".."
import "../core/components"

DialogOverlay {
  id: dialog
  title: "New Profile"

  Text {
    text: "Create a new profile from your current settings."
    color: Colors.subtext0
    font.pixelSize: 13
    width: parent.width
    wrapMode: Text.WordWrap
  }

  // Name input
  Column {
    width: parent.width
    spacing: 6

    Text {
      text: "Profile name"
      color: Colors.subtext1
      font.pixelSize: 12
    }

    Rectangle {
      width: parent.width
      height: 36
      radius: 6
      color: Colors.surface0
      border.width: nameInput.activeFocus ? 2 : 1
      border.color: nameInput.activeFocus ? Colors.blue : Colors.surface2

      TextInput {
        id: nameInput
        anchors.fill: parent
        anchors.margins: 8
        color: Colors.text
        font.pixelSize: 14
        clip: true
        focus: true
        Component.onCompleted: forceActiveFocus()

        Text {
          anchors.fill: parent
          text: "My Profile"
          color: Colors.overlay0
          font.pixelSize: 14
          visible: !nameInput.text && !nameInput.activeFocus
        }

        Keys.onReturnPressed: {
          if (nameInput.text.trim()) {
            GeneralSettings.createProfile(nameInput.text.trim())
            dialog.closeRequested()
          }
        }

        Keys.onEscapePressed: dialog.closeRequested()
      }
    }

    // Preview of sanitized name
    Text {
      text: nameInput.text.trim() ? "Folder: " + previewSanitized(nameInput.text.trim()) : ""
      color: Colors.overlay0
      font.pixelSize: 11
      visible: nameInput.text.trim() !== ""
    }
  }

  // Buttons
  Row {
    spacing: 8

    FocusButton {
      height: 32
      text: "Create"
      fontSize: 12
      backgroundColor: Colors.blue
      textColor: Colors.crust
      textHoverColor: Colors.crust
      enabled: nameInput.text.trim() !== ""
      onClicked: {
        GeneralSettings.createProfile(nameInput.text.trim())
        dialog.closeRequested()
      }
    }

    FocusButton {
      height: 32
      text: "Cancel"
      fontSize: 12
      backgroundColor: Colors.surface0
      hoverColor: Colors.surface1
      onClicked: dialog.closeRequested()
    }
  }

  // Preview function (mirrors GeneralSettings.sanitizeName without the UUID part)
  function previewSanitized(displayName) {
    var base = displayName.toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")
    if (!base) base = "profile"
    return base + "-<id>"
  }
}
