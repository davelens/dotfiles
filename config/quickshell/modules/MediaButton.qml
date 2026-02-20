import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import ".."

Item {
  id: root

  // Required: screen reference for width calculation
  required property var screen

  // Get the first active player (playing or paused with content)
  readonly property var activePlayer: {
    for (var i = 0; i < Mpris.players.values.length; i++) {
      var p = Mpris.players.values[i]
      if (p.trackTitle) return p
    }
    return null
  }

  // Get the display name for the player source
  function getSourceName() {
    if (!activePlayer) return ""

    // Check metadata URL for known sites (browsers expose this)
    var url = activePlayer.metadata["xesam:url"] || ""
    if (url.indexOf("youtube.com") !== -1) return "YouTube"
    if (url.indexOf("youtu.be") !== -1) return "YouTube"
    if (url.indexOf("soundcloud.com") !== -1) return "SoundCloud"
    if (url.indexOf("spotify.com") !== -1) return "Spotify"
    if (url.indexOf("bandcamp.com") !== -1) return "Bandcamp"
    if (url.indexOf("twitch.tv") !== -1) return "Twitch"

    // Fall back to player identity
    return activePlayer.identity
  }

  // Hide when nothing is playing
  visible: activePlayer !== null
  width: visible ? content.width : 0
  height: parent.height

  Row {
    id: content
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    // Play/pause icon
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.activePlayer && root.activePlayer.isPlaying ? "󰐊" : "󰏤"
      color: Colors.blue
      font.pixelSize: 14
      font.family: "Symbols Nerd Font"
    }

    // Player source (e.g., YouTube, Spotify, Firefox)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.getSourceName()
      color: Colors.overlay0
      font.pixelSize: 12
    }

    // Artist - Title (truncated to 30% of screen width)
    Text {
      id: mediaText
      anchors.verticalCenter: parent.verticalCenter
      text: {
        if (!root.activePlayer) return ""
        var artist = root.activePlayer.trackArtist || ""
        var title = root.activePlayer.trackTitle || ""
        if (artist && title) return artist + " - " + title
        return title || artist
      }
      color: Colors.text
      font.pixelSize: 13
      elide: Text.ElideRight
      width: Math.min(implicitWidth, root.screen.width * 0.3)
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.activePlayer && root.activePlayer.canTogglePlaying) {
        root.activePlayer.togglePlaying()
      }
    }
  }
}
