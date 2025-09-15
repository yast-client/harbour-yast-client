import QtQuick 2.0
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import "../js/functions.js" as Functions


// TODO!

GridItem {
    id: chatListViewItem

    property alias primaryText: primaryText //usually chat name
    property alias prologSecondaryText: prologSecondaryText //usually last sender name
    property alias secondaryText: secondaryText //usually last message
    property alias tertiaryText: tertiaryText //usually last message date
    property bool showSeparator: true

    property int unreadCount: 0
    property int unreadMentionCount: 0
    property int unreadReactionCount: 0
    property bool isSecret
    property alias verificationStatus: chatBadges.verificationStatus
    property bool isMarkedAsUnread
    property bool isPinned
    property alias muted: chatBadges.muted
    property alias ad: chatBadges.ad
    property alias pictureThumbnail: pictureThumbnail

    contentHeight: Theme.itemSizeLarge
    contentWidth: Theme.itemSizeLarge

    Column {
        spacing: Theme.paddingSmall / 2

        ChatPhotoPreview {

        }

        Row {
            id: primaryTextRow
            spacing: Theme.paddingMedium

            Label {
                id: primaryText
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(contentColumn.width - chatBadges.width - parent.spacing, implicitWidth)
                font.bold: appSettings.highlightUnreadConversations && ( !chatListViewItem.muted && (chatListViewItem.unreadCount > 0 || chatListViewItem.isMarkedAsUnread) )
                font.italic: appSettings.highlightUnreadConversations  && (chatListViewItem.unreadReactionCount > 0)
                color: (appSettings.highlightUnreadConversations && (chatListViewItem.unreadCount > 0)) ? Theme.highlightColor : Theme.primaryColor
            }

            ChatBadges {
                id: chatBadges
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

}
