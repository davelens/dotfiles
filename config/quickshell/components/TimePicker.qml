import QtQuick
import QtQuick.Controls
import ".."

Row {
    id: timePicker

    property int hours: 0
    property int minutes: 0  // Will be converted to index (0, 15, 30, 45 -> 0, 1, 2, 3)

    spacing: 4
    height: 100

    // Hours tumbler (0-23)
    Tumbler {
        id: hoursTumbler
        model: 24
        currentIndex: hours
        visibleItemCount: 3
        wrap: true
        width: 50
        height: parent.height

        onCurrentIndexChanged: {
            if (hours !== currentIndex) {
                hours = currentIndex
            }
        }

        delegate: Text {
            text: modelData.toString().padStart(2, '0')
            color: Tumbler.displacement === 0 ? Colors.text : Colors.overlay0
            font.pixelSize: Tumbler.displacement === 0 ? 18 : 14
            font.bold: Tumbler.displacement === 0
            opacity: 1.0 - Math.abs(Tumbler.displacement) / 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: "transparent"
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - height / 2
            width: parent.width - 8
            height: 28
            color: Colors.surface0
            radius: 4
            z: -1
        }
    }

    // Colon separator
    Text {
        text: ":"
        color: Colors.text
        font.pixelSize: 18
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
    }

    // Minutes tumbler (0, 15, 30, 45)
    Tumbler {
        id: minutesTumbler
        model: ["00", "15", "30", "45"]
        currentIndex: minutes / 15
        visibleItemCount: 3
        wrap: true
        width: 50
        height: parent.height

        onCurrentIndexChanged: {
            var newMinutes = currentIndex * 15
            if (minutes !== newMinutes) {
                minutes = newMinutes
            }
        }

        delegate: Text {
            text: modelData
            color: Tumbler.displacement === 0 ? Colors.text : Colors.overlay0
            font.pixelSize: Tumbler.displacement === 0 ? 18 : 14
            font.bold: Tumbler.displacement === 0
            opacity: 1.0 - Math.abs(Tumbler.displacement) / 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: "transparent"
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - height / 2
            width: parent.width - 8
            height: 28
            color: Colors.surface0
            radius: 4
            z: -1
        }
    }

    // Sync external changes to hours
    onHoursChanged: {
        if (hoursTumbler.currentIndex !== hours) {
            hoursTumbler.currentIndex = hours
        }
    }

    // Sync external changes to minutes
    onMinutesChanged: {
        var targetIndex = Math.floor(minutes / 15)
        if (minutesTumbler.currentIndex !== targetIndex) {
            minutesTumbler.currentIndex = targetIndex
        }
    }
}
