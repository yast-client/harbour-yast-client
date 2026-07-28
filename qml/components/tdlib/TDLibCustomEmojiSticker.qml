import QtQuick 2.0
import '../../js/debug.js' as Debug

TDLibSticker {
    property string customEmojiId

    property string extraValue: 'customEmoji:'+customEmojiId

    onCustomEmojiIdChanged:
        if (customEmojiId && customEmojiId !== '0') {
            stickerData = null
            tdLibWrapper.getCustomEmojiStickers(customEmojiId, extraValue)
        }
    Connections {
        target: stickerData ? null : tdLibWrapper
        ignoreUnknownSignals: true
        onStickersReceived:
            if (stickers.length === 1 && extra === extraValue) {
                Debug.log("[TDLibCustomEmojiSticker] Sticker received", customEmojiId)
                stickerData = stickers[0]
            }
    }
}
