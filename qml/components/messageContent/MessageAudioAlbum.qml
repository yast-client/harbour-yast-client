//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

MessageFileAlbumBase {
    id: messageContent
    sourceComponent: MessageAudio {
        width: parent.width
        messageListItem: messageContent.messageListItem
        rawMessage: parent.message
        highlighted: messageContent.highlighted
    }
}
