import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../"
import "../../js/twemoji.js" as Emoji

MessageSticker {
    stickerData: rawMessage.content.animated_emoji.sticker
}
