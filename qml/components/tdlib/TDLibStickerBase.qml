import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import io.yaqtlib 1.0
import "../../js/twemoji.js" as Emoji

Item {
    id: sticker
    property bool highlighted
    property var stickerData
    property bool loop: true

    property bool asEmoji: appSettings.showStickersAsEmojis
    property real aspectRatio: stickerData.width / stickerData.height
    property bool useThumbnail
    property bool stickerVisible

    implicitWidth: stickerData.width
    implicitHeight: width * aspectRatio

    property alias file: file

    TDLibFile {
        id: file
        tdlib: tdLibWrapper
        // in this implementation video (MPEG4) thumbnails are not supported, but they don't seem to appear in stickers
        fileInformation: useThumbnail ? stickerData.thumbnail.file : stickerData.sticker
        autoLoad: true
    }

    Loader {
        anchors.fill: parent
        source: Qt.resolvedUrl('../BackgroundImage.qml')

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
