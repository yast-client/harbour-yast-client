import QtQuick 2.6
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import "../js/functions.js" as Functions

ListItem {
    id: chatListViewItem

    property alias primaryText: primaryTextRow.textItem //usually chat name
    property alias prologSecondaryText: prologSecondaryText //usually last sender name
    property alias secondaryText: secondaryText //usually last message
    property alias tertiaryText: tertiaryText //usually last message date
    property bool showSeparator: true

    property int unreadCount: 0
    property int unreadMentionCount: 0
    property int unreadReactionCount: 0
    property bool isSecret
    property bool isVerified
    property bool scam
    property bool fake
    property bool isMarkedAsUnread
    property bool isPinned
    property bool isMuted
    property alias pictureThumbnail: pictureThumbnail

    contentHeight: Theme.itemSizeExtraLarge
    contentWidth: parent.width


    ShaderEffectSource {
        id: pictureItem
        height: Theme.itemSizeLarge
        width: height
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        sourceItem: Item {
            width: pictureItem.width
            height: pictureItem.width

            ProfileThumbnail {
                id: pictureThumbnail
                replacementStringHint: primaryText.text
                width: parent.width
                height: parent.width
            }

            Rectangle {
                id: chatPinnedBackground
                color: Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityFaint)
                width: Theme.fontSizeLarge
                height: Theme.fontSizeLarge
                anchors.top: parent.top
                radius: parent.width / 2
                visible: chatListViewItem.isPinned
            }

            Icon {
                source: "../../images/icon-s-pin.svg"
                height: Theme.iconSizeExtraSmall
                width: Theme.iconSizeExtraSmall
                highlighted: chatListViewItem.highlighted
                sourceSize: Qt.size(Theme.iconSizeExtraSmall, Theme.iconSizeExtraSmall)
                anchors.centerIn: chatPinnedBackground
                visible: chatListViewItem.isPinned
            }

            Rectangle {
                id: chatSecretBackground
                color: Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityFaint)
                width: Theme.fontSizeLarge
                height: Theme.fontSizeLarge
                anchors.bottom: parent.bottom
                radius: parent.width / 2
                visible: chatListViewItem.isSecret
            }

            Icon {
                source: "image://theme/icon-s-secure"
                height: Theme.iconSizeExtraSmall
                width: Theme.iconSizeExtraSmall
                highlighted: chatListViewItem.highlighted
                anchors.centerIn: chatSecretBackground
                visible: chatListViewItem.isSecret
            }

            Rectangle {
                id: chatUnreadMessagesCountBackground
                color: isMuted ? ((Theme.colorScheme === Theme.DarkOnLight) ? "lightgray" : "dimgray") : Theme.highlightBackgroundColor
                width: Theme.fontSizeLarge
                height: Theme.fontSizeLarge
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: parent.width / 2
                visible: chatListViewItem.unreadCount > 0 || chatListViewItem.isMarkedAsUnread
            }

            Text {
                id: chatUnreadMessagesCount
                font.pixelSize: Theme.fontSizeExtraSmall
                font.bold: true
                color: Theme.primaryColor
                anchors.centerIn: chatUnreadMessagesCountBackground
                visible: chatListViewItem.unreadCount > 0
                opacity: isMuted ? Theme.opacityHigh : 1.0
                text: Functions.formatUnreadCount(chatListViewItem.unreadCount)
            }

            Rectangle {
                color: isMuted ? ((Theme.colorScheme === Theme.DarkOnLight) ? "lightgray" : "dimgray") : Theme.highlightBackgroundColor
                width: Theme.fontSizeLarge
                height: Theme.fontSizeLarge
                anchors.right: parent.right
                anchors.top: parent.top
                radius: parent.width / 2
                visible: chatListViewItem.unreadReactionCount > 0 || chatListViewItem.unreadMentionCount > 0

                Icon {
                    source: "image://theme/icon-s-favorite"
                    height: Theme.iconSizeExtraSmall
                    width: Theme.iconSizeExtraSmall
                    highlighted: chatListViewItem.highlighted
                    anchors.centerIn: parent
                    visible: chatListViewItem.unreadReactionCount > 0 && !chatListViewItem.unreadMentionCount
                }

                Text {
                    font {
                        pixelSize: Theme.iconSizeExtraSmall
                        bold: true
                    }
                    color: Theme.primaryColor
                    anchors.centerIn: parent
                    visible: chatListViewItem.unreadMentionCount > 0
                    opacity: isMuted ? Theme.opacityHigh : 1.0
                    text: "@"
                }
            }
        }
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

        ChatHeaderText {
            id: primaryTextRow
            width: parent.width

            font.pixelSize: Theme.fontSizeMedium
            font.bold: appSettings.highlightUnreadConversations && ( !chatListViewItem.isMuted && (chatListViewItem.unreadCount > 0 || chatListViewItem.isMarkedAsUnread) )
            font.italic: appSettings.highlightUnreadConversations  && (chatListViewItem.unreadReactionCount > 0)
            color: (appSettings.highlightUnreadConversations && (chatListViewItem.unreadCount > 0)) ? Theme.highlightColor : Theme.primaryColor

            verified: chatListViewItem.isVerified
            muted: chatListViewItem.isMuted
            scam: chatListViewItem.scam
            fake: chatListViewItem.fake
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
            }
            Label {
                id: secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - Theme.paddingMedium - prologSecondaryText.width
                truncationMode: TruncationMode.Fade
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
