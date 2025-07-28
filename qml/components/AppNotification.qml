import QtQuick 2.6
import Sailfish.Silica 1.0
import "../js/debug.js" as Debug
import "../js/twemoji.js" as Emoji

Rectangle {
    id: notification
    anchors.centerIn: parent

    property real layoutMaxWidth
    readonly property real maxWidth: layoutMaxWidth - 2 * Theme.horizontalPageMargin

    width: Math.min(maxWidth, text.implicitWidth + buttonWidth)
    height: Math.min(button.state == 'right'
                     ? Math.max(button.height + button.anchors.bottomMargin + button.anchors.topMargin, text.height)
                     : text.height + buttonHeight, Theme.itemSizeLarge*3)

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
        Debug.log("In-app notification", message)
        postAnimationResetTimer.stop()
        text.text = Emoji.emojify(message, Theme.fontSizeExtraSmall)
        clickedAction = onClicked
        button.text = buttonText ? Emoji.emojify(buttonText, Theme.fontSizeExtraSmall) : ''
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

    Timer {
        id: scrollResetDisableTimer
        interval: 0
        onTriggered: if (notification.clip) resetTimer.stop()
    }

    readonly property real buttonHeight: button.visible && button.state == 'bottom' ? button.height + button.anchors.bottomMargin : 0
    readonly property real buttonWidth: button.visible && button.state == 'right' ? button.width + button.anchors.rightMargin : 0
    readonly property real maximumTextHeight: height - buttonHeight
    clip: text.height > maximumTextHeight
    onClipChanged: if (notification.clip) // see show()
                       scrollResetDisableTimer.start() // when rotating, clip can be wrong


    property alias textItem: text

    Loader {
        id: textMetricsLoader
        active: button.visible
        sourceComponent: Component {
            TextMetrics {
                font.pixelSize: textItem.font.pixelSize
                text: textItem.text
                // For some reason using text(Item).implicitWidth in notification.width expression causes a binding loop, so we use this
                readonly property bool rightButtonFits: (width
                                                    - (Theme.paddingLarge + Theme.paddingMedium) // text.leftPadding + text.rightPadding
                                                    + (button.width + Theme.paddingLarge) // buttonWidth
                                                    ) <= notification.maxWidth
            }
        }
        readonly property bool rightButtonFits: !!item && item.rightButtonFits
    }

    Text {
        id: text
        padding: Theme.paddingLarge
        rightPadding: buttonWidth > 0 ? Theme.paddingMedium : Theme.paddingLarge
        bottomPadding: buttonHeight > 0 ? Theme.paddingMedium : Theme.paddingLarge
        width: parent.width - buttonWidth
        anchors.verticalCenter: button.state == 'right' ? parent.verticalCenter : undefined

        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
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
        preferredWidth: Theme.buttonWidthExtraSmall

        states: [
            State {
                name: 'bottom'
                when: !textMetricsLoader.rightButtonFits
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
                when: textMetricsLoader.rightButtonFits
                PropertyChanges {
                    target: button
                    // leftMargin is managed by text.rightPadding
                    anchors.rightMargin: Theme.paddingLarge

                    anchors.topMargin: Theme.paddingMedium
                    anchors.bottomMargin: Theme.paddingMedium
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

        onClicked: {
            reset()
            clickedAction()
        }
    }
}
