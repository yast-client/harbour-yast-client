import QtQuick 2.6
import Sailfish.Silica 1.0

ListItem {
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
    property bool isMarkedAsUnread
    property bool isPinned
    property alias verificationStatus: chatBadges.verificationStatus
    property alias muted: chatBadges.muted
    property alias ad: chatBadges.ad

    property alias pictureThumbnail: pictureItem.pictureThumbnail

    contentHeight: Theme.itemSizeExtraLarge
    contentWidth: parent.width

    ChatPhotoPreview {
        id: pictureItem
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        highlighted: chatListViewItem.highlighted
        unreadCount: chatListViewItem.unreadCount
        unreadMentionCount: chatListViewItem.unreadMentionCount
        unreadReactionCount: chatListViewItem.unreadReactionCount
        isSecret: chatListViewItem.isSecret
        isMarkedAsUnread: chatListViewItem.isMarkedAsUnread
        isPinned: chatListViewItem.isPinned
        muted: chatBadges.muted
    }

    Column {
        id: contentColumn
        anchors {
            verticalCenter: parent.verticalCenter
            left: pictureItem.right
            leftMargin: Theme.paddingSmall
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        spacing: Theme.paddingSmall / 2

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

        Row {
            width: parent.width
            spacing: Theme.paddingSmall
            Label {
                id: prologSecondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: Math.min(implicitWidth, parent.width)
                color: Theme.highlightColor
                textFormat: Text.StyledText
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
            }
            Label {
                id: secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - Theme.paddingMedium - prologSecondaryText.width
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
                textFormat: Text.StyledText
                visible: prologSecondaryText.width < ( parent.width - Theme.paddingLarge )
            }
        }

        Label {
            id: tertiaryText
            width: parent.width
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.secondaryColor
            truncationMode: TruncationMode.Fade
        }
    }

    Separator {
        visible: showSeparator
        id: separator
        anchors {
            bottom: parent.bottom
            bottomMargin: -1
        }

        width: parent.width
        color: Theme.primaryColor
        horizontalAlignment: Qt.AlignHCenter
    }

}
