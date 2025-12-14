import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import App.Logic 1.0
import "../js/twemoji.js" as Emoji

Item {
    id: sticker
    property bool highlighted
    property var stickerData
    property bool loop: true

    property bool asEmoji: appSettings.showStickersAsEmojis
    readonly property bool useThumbnail: !appSettings.videoStickers && stickerData.format['@type'] === 'stickerFormatWebm'
    readonly property bool animated: appSettings.animateStickers && stickerData.format["@type"] === "stickerFormatTgs"
    readonly property bool stickerVisible: !!(stickerLoader.item && stickerLoader.item.visible)
    property real aspectRatio: stickerData.width / stickerData.height

    property alias stickerItem: stickerLoader.item
    readonly property bool loaded: file.isDownloadingCompleted && stickerLoader.status == Loader.Ready

    implicitWidth: stickerData.width
    implicitHeight: width * aspectRatio

    TDLibFile {
        id: file
        tdlib: tdLibWrapper
        // in this implementation video (MPEG4) thumbnails are not supported, but they don't seem to appear in stickers
        fileInformation: useThumbnail ? stickerData.thumbnail.file : stickerData.sticker
        autoLoad: true
    }

    function getFrameCount() {
        // can't use a property because is non-NOTIFYable (results in lots of warnings)
        if (stickerLoader.sourceComponent == videoComponent)
            return stickerLoader.item.frameCount
        if (stickerLoader.sourceComponent == animatedComponent)
            return stickerLoader.item.frameCount
        return 0
    }

    function seekToFrame(frame) {
        if (!stickerLoader.item) return

        if (stickerLoader.sourceComponent == videoComponent) {
            if (stickerLoader.item.seekable)
                stickerLoader.item.seek(Math.min(frame * (stickerLoader.item.metaData.videoFrameRate / 1000), stickerLoader.item.duration))
        } else if (stickerLoader.sourceComponent == animatedComponent)
            stickerLoader.item.currentFrame = Math.min(frame, stickerLoader.item.frameCount)
    }

    function pause() {
        if (!stickerLoader.item) return

        if (stickerLoader.sourceComponent == videoComponent)
            stickerLoader.item.pause()
        else if (stickerLoader.sourceComponent == animatedComponent)
            stickerLoader.item.paused = true
    }

    function play() {
        if (!stickerLoader.item) return

        if (stickerLoader.sourceComponent == videoComponent)
            stickerLoader.item.play()
        else if (stickerLoader.sourceComponent == animatedComponent)
            stickerLoader.item.paused = false
    }

    Loader {
        id: stickerLoader
        anchors.fill: parent
        sourceComponent: {
            if (asEmoji) return staticComponent

            if (stickerData.format['@type'] === 'stickerFormatWebm' && appSettings.videoStickers)
                return videoComponent
            if (animated) return animatedComponent

            return staticComponent
        }

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
            MovieItem {
                id: animatedSticker
                anchors.fill: parent
                source: file.path
                sourceSize {
                    width: appSettings.downscaleAnimatedStickers ? Theme.itemSizeSmall : width
                    height: appSettings.downscaleAnimatedStickers ? (Theme.itemSizeSmall * aspectRatio) : height
                }

                //asynchronous: true
                paused: !Qt.application.active
                cache: false
                layer.enabled: sticker.highlighted
                layer.effect: PressEffect { source: animatedSticker }
                Connections {
                    target: loop ? null : animatedSticker
                    ignoreUnknownSignals: true
                    onCurrentFrameChanged:
                        if (animatedSticker.frameCount !== 0 // can't use this in target expression because non-NOTIFYable
                                && animatedSticker.currentFrame >= animatedSticker.frameCount - 1) {
                            animatedSticker.paused = true
                        }
                }
            }
        }

        Component {
            id: videoComponent
            Video {
                id: video
                anchors.fill: parent

                source: file.path
                autoPlay: true
                onStopped: if (sticker.loop && status == MediaPlayer.EndOfMedia) play()

                Connections {
                    target: Qt.application
                    onActiveChanged: if (!Qt.application.active) video.pause()
                                     else video.play()
                }

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
