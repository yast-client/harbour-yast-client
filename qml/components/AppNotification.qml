import QtQuick 2.6
import Sailfish.Silica 1.0
import "../js/debug.js" as Debug

Rectangle {
    id: notification
    anchors.centerIn: parent
    width: Math.min((orientation & Orientation.LandscapeMask ? parent.height : parent.width) - 2 * Theme.horizontalPageMargin, text.implicitWidth + buttonWidth)
    height: Math.min(text.height + buttonHeight, Theme.itemSizeLarge*3)

    onWidthChanged: button.calculateState()

    opacity: 0
    Behavior on opacity { FadeAnimator { id: fadeAnimator } }

    property bool highlighted
    color: highlighted ?
               Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
             : Qt.tint(
                   Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityOverlay),
                   Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity))
    radius: Theme.paddingSmall

    property var clickedAction // using signals would be harder

    function show(message, onClicked, buttonText) {
        Debug.log("app notification", message)
        postAnimationResetTimer.stop()
        text.text = message
        clickedAction = onClicked
        button.text = buttonText || ''
        button.calculateState()
        opacity = 1
        resetTimer.restart() // for some reason text.height == height here, so we use signals to stop timer
    }

    Timer {
        id: resetTimer
        interval: 3500
        onTriggered: reset()
    }

    Timer {
        id: postAnimationResetTimer
        interval: fadeAnimator.duration
        onTriggered: postAnimationReset()
    }

    readonly property real buttonHeight: button.visible && button.state == 'bottom' ? button.height + button.anchors.bottomMargin : 0
    readonly property real buttonWidth: button.visible && button.state == 'right' ? button.width + button.anchors.rightMargin : 0
    readonly property real maximumTextHeight: height - buttonHeight
    clip: text.height > maximumTextHeight
    onClipChanged: if (clip) resetTimer.stop() // see show()

    Text {
        id: text
        padding: Theme.paddingLarge
        rightPadding: buttonWidth > 0 ? Theme.paddingMedium : Theme.paddingLarge
        bottomPadding: buttonHeight > 0 ? Theme.paddingMedium : Theme.paddingLarge
        width: parent.width - buttonWidth

        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall //Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter

        SequentialAnimation on y {
            running: text.height > notification.maximumTextHeight

            PauseAnimation { duration: 1500 }
            SmoothedAnimation {
                velocity: Theme.dp(100)
                from: 0
                to: notification.maximumTextHeight - text.height
            }
            PauseAnimation { duration: 2000 }
            SmoothedAnimation {
                duration: 2000
                to: 0
            }
            PauseAnimation { duration: 1500 }
            ScriptAction { script: reset() }
        }
    }

    function reset() {
        resetTimer.stop()
        opacity = 0
        postAnimationResetTimer.restart()
    }

    function postAnimationReset() {
        button.text = ''
        clickedAction = undefined
    }

    SecondaryButton {
        id: button

        visible: !!clickedAction && !!text
        state: 'right'
        function calculateState() {
            state = 'right'
            // If it doesn't fit after adding the button to the right
            state = text.lineCount > 1 ? 'bottom' : 'right'
        }

        states: [
            State {
                name: 'bottom'
                PropertyChanges {
                    target: button
                    // topMargin is managed by text.bottomPadding
                    anchors.bottomMargin: Theme.paddingLarge
                }
                AnchorChanges {
                    target: button
                    anchors {
                        top: text.bottom
                        horizontalCenter: notification.horizontalCenter
                    }
                }
            },
            State {
                name: 'right'
                PropertyChanges {
                    target: button
                    // leftMargin is managed by text.rightPadding
                    anchors.rightMargin: Theme.paddingLarge
                }
                AnchorChanges {
                    target: button
                    anchors {
                        left: text.right
                        verticalCenter: notification.verticalCenter
                    }
                }
            }

        ]

        preferredWidth: Theme.buttonWidthExtraSmall

        onClicked: {
            reset()
            clickedAction()
        }
    }
}
