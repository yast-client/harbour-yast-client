//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

QtObject {
    property var message
    property var messageId
    property int messageIndex
    property var messageAlbumMessageIds
    property var messageAlbumMessages
    property int messageViewCount
    property var reactions
    property bool generatedContentUnread
    property bool isFirstInSequence: true
    property bool isLastInSequence: true

    readonly property bool isAlbum: message.media_album_id && message.media_album_id !== '0'

    readonly property bool isOwnMessage: message && tdLibWrapper.myUserId === message.sender_id.user_id
    readonly property bool isOutgoing: message && message.is_outgoing && !message.is_channel_post
    readonly property bool isOutgoingRead: messagesView.readable && isOutgoing && messageId <= messagesModel.lastReadOutboxMessageId

    signal replyToMessage
    signal editMessage
    signal forwardMessage
}
