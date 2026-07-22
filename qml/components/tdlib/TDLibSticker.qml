//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import io.yaqtlib 1.0
import '..'
import '../../js/twemoji.js' as Emoji

TDLibStickerBase {
    id: sticker

    readonly property bool animated: appSettings.animateStickers && stickerData.format["@type"] === "stickerFormatTgs"

    useThumbnail: !appSettings.videoStickers && stickerData.format['@type'] === 'stickerFormatWebm'
    stickerVisible: !!(stickerLoader.item && stickerLoader.item.visible)

    readonly property bool loaded: file.isDownloadingCompleted && stickerLoader.status == Loader.Ready

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
            LottieItem {
                id: animatedSticker
                anchors.fill: parent
                source: file.path
                // I don't know why but setting scaledSize to QSize(-1,-1) sometimes makes the quality worse,
                // even though before we introduced LottieItem/MovieItem it worked fine without any scaling at all.
                scaledSize {
                    width: appSettings.downscaleAnimatedStickers ? Theme.itemSizeSmall : width
                    height: appSettings.downscaleAnimatedStickers ? (Theme.itemSizeSmall * aspectRatio) : height
                }

                paused: !Qt.application.active
                loop: sticker.loop
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
}
