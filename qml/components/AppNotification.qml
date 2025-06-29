import QtQuick 2.6
import Sailfish.Silica 1.0

Rectangle {
    id: notification
    anchors.centerIn: parent
    width: Math.min(parent.width - 2 * Theme.horizontalPageMargin, text.implicitWidth)
    height: Math.min(text.height, Theme.itemSizeLarge*3)

    opacity: 0
    Behavior on opacity { FadeAnimator {} }

    color: mouseArea.pressed && mouseArea.containsMouse ?
               Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
             : Qt.tint(
                   Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityOverlay),
                   Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity))
    radius: Theme.paddingSmall

    property var clickedAction // using signals would be harder

    function show(message, onClicked) {
        text.text = message
        clickedAction = onClicked
        opacity = 1
        resetTimer.start() // for some reason text.height == height here, so we use signals to stop timer
    }

    Timer {
        id: resetTimer
        interval: 3500
        onTriggered: notification.opacity = 0
    }

    clip: text.height > height
    onClipChanged: if (clip) resetTimer.stop() // see show()

    Text {
        id: text
        padding: Theme.paddingLarge
        width: parent.width

        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall // Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter

        SequentialAnimation on y {
            running: text.height > notification.height

            PauseAnimation { duration: 1500 }
            SmoothedAnimation {
                velocity: Theme.dp(100)
                from: 0
                to: notification.height - text.height
            }
            PauseAnimation { duration: 2000 }
            SmoothedAnimation {
                duration: 2000
                to: 0
            }
            PauseAnimation { duration: 1500 }
            ScriptAction { script: notification.opacity = 0 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: clickedAction()
        enabled: !!clickedAction
    }
}
