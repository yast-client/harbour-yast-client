import QtQuick 2.6
import Sailfish.Silica 1.0
import "../js/functions.js" as Functions

ShaderEffectSource {
    id: pictureItem
    height: Theme.itemSizeLarge
    width: height

    property bool highlighted
    property int unreadCount: 0
    property int unreadMentionCount: 0
    property int unreadReactionCount: 0
    property bool isSecret
    property bool isMarkedAsUnread
    property bool isPinned
    property bool muted

    property alias pictureThumbnail: pictureThumbnail

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
            visible: pictureItem.isPinned
        }

        Icon {
            source: "../../images/icon-s-pin.svg"
            height: Theme.iconSizeExtraSmall
            width: Theme.iconSizeExtraSmall
            highlighted: pictureItem.highlighted
            sourceSize: Qt.size(Theme.iconSizeExtraSmall, Theme.iconSizeExtraSmall)
            anchors.centerIn: chatPinnedBackground
            visible: pictureItem.isPinned
        }

        Rectangle {
            id: chatSecretBackground
            color: Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityFaint)
            width: Theme.fontSizeLarge
            height: Theme.fontSizeLarge
            anchors.bottom: parent.bottom
            radius: parent.width / 2
            visible: pictureItem.isSecret
        }

        Icon {
            source: "image://theme/icon-s-secure"
            height: Theme.iconSizeExtraSmall
            width: Theme.iconSizeExtraSmall
            highlighted: pictureItem.highlighted
            anchors.centerIn: chatSecretBackground
            visible: pictureItem.isSecret
        }

        Rectangle {
            id: chatUnreadMessagesCountBackground
            color: muted ? ((Theme.colorScheme === Theme.DarkOnLight) ? "lightgray" : "dimgray") : Theme.highlightBackgroundColor
            width: Theme.fontSizeLarge
            height: Theme.fontSizeLarge
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            radius: parent.width / 2
            visible: pictureItem.unreadCount > 0 || pictureItem.isMarkedAsUnread
        }

        Text {
            id: chatUnreadMessagesCount
            font.pixelSize: Theme.fontSizeExtraSmall
            font.bold: true
            color: Theme.primaryColor
            anchors.centerIn: chatUnreadMessagesCountBackground
            visible: pictureItem.unreadCount > 0
            opacity: muted ? Theme.opacityHigh : 1.0
            text: Functions.formatUnreadCount(pictureItem.unreadCount)
        }

        Rectangle {
            color: muted ? ((Theme.colorScheme === Theme.DarkOnLight) ? "lightgray" : "dimgray") : Theme.highlightBackgroundColor
            width: Theme.fontSizeLarge
            height: Theme.fontSizeLarge
            anchors.right: parent.right
            anchors.top: parent.top
            radius: parent.width / 2
            visible: pictureItem.unreadReactionCount > 0 || pictureItem.unreadMentionCount > 0

            Icon {
                source: "image://theme/icon-s-favorite"
                height: Theme.iconSizeExtraSmall
                width: Theme.iconSizeExtraSmall
                highlighted: pictureItem.highlighted
                anchors.centerIn: parent
                visible: pictureItem.unreadReactionCount > 0 && !pictureItem.unreadMentionCount
            }

            Text {
                font {
                    pixelSize: Theme.iconSizeExtraSmall
                    bold: true
                }
                color: Theme.primaryColor
                anchors.centerIn: parent
                visible: pictureItem.unreadMentionCount > 0
                opacity: muted ? Theme.opacityHigh : 1.0
                text: "@"
            }
        }
    }
}
