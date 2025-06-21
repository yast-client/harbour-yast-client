import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import WerkWolf.Fernschreiber 1.0
import "../js/twemoji.js" as Emoji

Item {
    id: sticker
    property bool highlighted
    property var stickerData

    property bool asEmoji: appSettings.showStickersAsEmojis
    readonly property bool animated: stickerData.format["@type"] === "stickerFormatTgs" && appSettings.animateStickers
    readonly property bool stickerVisible: !!(stickerLoader.item && stickerLoader.item.visible)
    property real aspectRatio: stickerData.width / stickerData.height

    implicitWidth: stickerData.width
    implicitHeight: width * aspectRatio

    TDLibFile {
        id: file
        tdlib: tdLibWrapper
        fileInformation: stickerData.sticker
        autoLoad: true
    }

    Loader {
        id: stickerLoader
        anchors.fill: parent
        sourceComponent: stickerData.format["@type"] === "stickerFormatWebm" ? (appSettings.videoStickers ? videoComponent : undefined)
                                                                             : (!animated || asEmoji ? staticComponent : animatedComponent)

        Component {
            id: staticComponent
            Image {
                id: staticSticker
                anchors.fill: parent
                source: asEmoji ? Emoji.getEmojiPath(stickerData.emoji) : file.path
                sourceSize {
                    width: width
                    height: height
                }
                fillMode: Image.PreserveAspectFit
                autoTransform: true
                asynchronous: true
                visible: opacity > 0
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { FadeAnimation {} }
                layer.enabled: sticker.highlighted
                layer.effect: PressEffect { source: staticSticker }
            }
        }

        Component {
            id: animatedComponent
            AnimatedImage {
                id: animatedSticker
                anchors.fill: parent
                source: file.path
                asynchronous: true
                paused: !Qt.application.active
                cache: false
                layer.enabled: sticker.highlighted
                layer.effect: PressEffect { source: animatedSticker }
            }
        }

        Component {
            id: videoComponent
            Video {
                id: video
                anchors.fill: parent

                source: file.path
                autoPlay: true
                onStopped: if (status == MediaPlayer.EndOfMedia) play()

                /*Connections {
                    target: Qt.application
                    onActiveChanged: if (!Qt.application.active) video.pause()
                                     else video.play()
                }*/

                layer.enabled: sticker.highlighted
                layer.effect: PressEffect { source: video }
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: Component {
            BackgroundImage {}
        }

        active: opacity > 0
        opacity: !stickerVisible && !placeHolderDelayTimer.running ? 0.15 : 0
        Behavior on opacity { FadeAnimation {} }

        Timer {
            id: placeHolderDelayTimer
            interval: 1000
            running: true
        }
    }
}
