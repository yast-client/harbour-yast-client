import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import App.Logic 1.0
import "../js/twemoji.js" as Emoji

TDLibStickerBase {
    id: sticker

    stickerVisible: file.isDownloadingCompleted && loader.status == Loader.Ready

    property alias stickerItem: loader.item

    readonly property bool loaded: file.isDownloadingCompleted
    property bool setSource: true

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: Component {
            LottieItem {
                id: animatedSticker
                anchors.fill: parent

                source: setSource ? file.path : ''
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
    }
}
