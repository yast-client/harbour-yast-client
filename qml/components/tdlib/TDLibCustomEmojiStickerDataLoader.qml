//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import '../../js/debug.js' as Debug

QtObject {
    property var stickerData
    property string customEmojiId

    property string extraValue: 'customEmoji:'+customEmojiId

    onCustomEmojiIdChanged: {
        stickerData = null
        if (customEmojiId && customEmojiId !== '0')
            tdLibWrapper.getCustomEmojiStickers(customEmojiId, extraValue)
    }

    property Connections conn__: Connections {
        target: stickerData ? null : tdLibWrapper
        ignoreUnknownSignals: true
        onStickersReceived:
            if (stickers.length === 1 && extra === extraValue) {
                Debug.log("[TDLibCustomEmojiSticker] Sticker received", customEmojiId)
                stickerData = stickers[0]
            }
    }
}
