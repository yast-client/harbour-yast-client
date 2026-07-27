//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../js/functions.js" as Functions

GridItem {
    id: chatItem

    property alias primaryText: primaryText //usually chat name

    property alias unreadCount: pictureItem.unreadCount
    property alias unreadMentionCount: pictureItem.unreadMentionCount
    property alias unreadReactionCount: pictureItem.unreadReactionCount
    property alias unreadPollVoteCount: pictureItem.unreadPollVoteCount
    property alias isSecret: pictureItem.isSecret
    property alias isMarkedAsUnread: pictureItem.isMarkedAsUnread
    property alias isPinned: pictureItem.isPinned

    property alias verificationStatus: chatBadges.verificationStatus
    property alias muted: chatBadges.muted
    property alias ad: chatBadges.ad

    property alias pictureThumbnail: pictureItem.pictureThumbnail
    property alias content: contentColumn

    Column {
        id: contentColumn
        width: chatItem.width - 2*Theme.paddingMedium
        anchors.centerIn: parent
        spacing: Theme.paddingSmall / 2

        ChatPhotoPreview {
            id: pictureItem
            width: parent.width
            height: width

            highlighted: chatItem.highlighted
            muted: chatBadges.muted
        }

        Row {
            id: primaryTextRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall / 2

            Label {
                id: primaryText
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeExtraSmall
                truncationMode: TruncationMode.Fade
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(contentColumn.width - chatBadges.width - parent.spacing, implicitWidth)
                font.bold: appSettings.highlightUnreadConversations && ( !chatItem.muted && (chatItem.unreadCount > 0 || chatItem.isMarkedAsUnread) )
                font.italic: appSettings.highlightUnreadConversations  && (chatItem.unreadReactionCount > 0)
                color: (appSettings.highlightUnreadConversations && (chatItem.unreadCount > 0)) ? Theme.highlightColor : Theme.primaryColor
            }

            ChatBadges {
                id: chatBadges
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
