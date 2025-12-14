import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../js/functions.js" as Functions

GridItem {
    id: chatItem

    property alias primaryText: primaryText //usually chat name

    property int unreadCount: 0
    property int unreadMentionCount: 0
    property int unreadReactionCount: 0
    property bool isSecret
    property alias verificationStatus: chatBadges.verificationStatus
    property bool isMarkedAsUnread
    property bool isPinned
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
            unreadCount: chatItem.unreadCount
            unreadMentionCount: chatItem.unreadMentionCount
            unreadReactionCount: chatItem.unreadReactionCount
            isSecret: chatItem.isSecret
            isMarkedAsUnread: chatItem.isMarkedAsUnread
            isPinned: chatItem.isPinned
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
