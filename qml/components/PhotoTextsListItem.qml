import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

ListItem {
    id: chatItem

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

    property alias pictureThumbnailItem: pictureItem
    property alias pictureThumbnail: pictureItem.pictureThumbnail
    property var minithumbnail
    property int minithumbnailRadius: Theme.paddingSmall / 2

    property alias chatActionIcon: chatActionIcon

    property real leftMargin: Theme.horizontalPageMargin
    property real rightMargin: Theme.horizontalPageMargin

    contentHeight: Theme.itemSizeExtraLarge
    contentWidth: parent.width

    ChatPhotoPreview {
        id: pictureItem
        anchors {
            left: parent.left
            leftMargin: chatItem.leftMargin
            verticalCenter: parent.verticalCenter
        }

        highlighted: chatItem.highlighted
        unreadCount: chatItem.unreadCount
        unreadMentionCount: chatItem.unreadMentionCount
        unreadReactionCount: chatItem.unreadReactionCount
        isSecret: chatItem.isSecret
        isMarkedAsUnread: chatItem.isMarkedAsUnread
        isPinned: chatItem.isPinned
        muted: chatBadges.muted
    }

    Column {
        id: contentColumn
        anchors {
            verticalCenter: parent.verticalCenter
            left: pictureItem.right
            leftMargin: Theme.paddingSmall
            right: parent.right
            rightMargin: chatItem.rightMargin
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
                font.bold: appSettings.highlightUnreadConversations && ( !chatItem.muted && (chatItem.unreadCount > 0 || chatItem.isMarkedAsUnread) )
                font.italic: appSettings.highlightUnreadConversations  && (chatItem.unreadReactionCount > 0)
                color: (appSettings.highlightUnreadConversations && (chatItem.unreadCount > 0)) ? Theme.highlightColor : Theme.primaryColor
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
                width: Math.min(implicitWidth, parent.parent.width)
                visible: !!text
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.highlightColor
                textFormat: Text.StyledText
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
            }
            Loader {
                id: minithumbnailLoader
                active: !!minithumbnail
                visible: active
                width: active ? Theme.fontSizeExtraSmall : 0
                height: width

                sourceComponent: Component {
                    OpacityMask {
                        anchors.fill: parent
                        source: minithumbnailItem.image
                        maskSource: minithumbnailMask

                        TDLibMinithumbnail {
                            id: minithumbnailItem
                            minithumbnail: chatItem.minithumbnail
                            visible: false
                        }

                        Rectangle {
                            id: minithumbnailMask
                            color: Theme.primaryColor
                            width: parent.width - Theme.paddingSmall
                            height: parent.height - Theme.paddingSmall
                            radius: minithumbnailRadius
                            visible: false
                        }
                    }
                }
            }
            ChatActionIcon {
                id: chatActionIcon
            }
            Label {
                id: secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - (prologSecondaryText.width + minithumbnailLoader.width + chatActionIcon.width
                                       + (prologSecondaryText.visible + minithumbnailLoader.visible + chatActionIcon.visible) * parent.spacing)
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
                textFormat: Text.StyledText
                linkColor: highlighted ? Theme.primaryColor : Theme.highlightColor
                visible: prologSecondaryText.width < ( parent.width - Theme.paddingLarge )
            }
        }

        Label {
            id: tertiaryText
            visible: !!text
            width: parent.width
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.secondaryColor
            linkColor: Theme.highlightColor
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
