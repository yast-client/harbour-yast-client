//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '../tdlib'

MessageSticker {
    stickerData: rawMessage.content.animated_emoji.sticker
    defaultWidth: Theme.itemSizeExtraLarge
    sticker {
        fitzModifier: rawMessage.content.animated_emoji.fitzpatrick_type
        loop: false
    }
    extraContextMenuItems: []
    openSetOnClick: false
    onClicked: {
        if (!bigAnimationLoader.stickerData)
            tdLibWrapper.clickAnimatedEmojiMessage(chatId, messageId)
        sticker.replayIfNeeded()
    }

    Connections {
        target: tdLibWrapper
        onAnimatedEmojiMessageClicked:
            if (!bigAnimationLoader.stickerData && messageListItem.isInViewport() && chatId === chatPage.chatId && messageId === messageListItem.messageId) {
                bigAnimationLoader.stickerData = sticker
                tdLibWrapper.sendChatAction(chatId, {'@type': 'chatActionWatchingAnimations', emoji: sticker.emoji}, topicId)
            }
    }

    TDLibSticker {
        id: bigAnimationLoader
        width: Theme.itemSizeHuge*2
        anchors {
            verticalCenter: parent.verticalCenter
            right: sticker.right
        }
        z: 1 // TODO: this is not enough to make the animation appear above everything else
        asEmoji: false
        loop: false
        onLoopFinished: stickerData = null
        showBackgroundImage: false
    }
}
