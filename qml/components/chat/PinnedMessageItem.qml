import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../js/functions.js" as Functions
import "../../js/twemoji.js" as Emoji
import "../../js/debug.js" as Debug

Item {
    id: pinnedMessageItem

    property var pinnedMessage;
    signal requestShowMessage;
    signal requestCloseMessage;

    onPinnedMessageChanged: {
        if (pinnedMessage) {
            Debug.log("[ChatPage] Activating pinned message");
            var messageUserText = (pinnedMessage.sender_id.user_id !== tdLibWrapper.myUserId) ? Emoji.emojify(utilities.getUserName(tdLibWrapper.getUserInformation(pinnedMessage.sender_id.user_id)), pinnedMessageUserText.font.pixelSize) : qsTr("You");
            pinnedMessageUserText.text = (messageUserText === "" ? qsTr("Pinned Message") : messageUserText );
            pinnedMessageText.text = Emoji.emojify(Functions.getMessageText(pinnedMessage, true, tdLibWrapper.myUserId, false), pinnedMessageText.font.pixelSize);
            pinnedMessageItem.visible = true;
        } else {
            pinnedMessageItem.visible = false;
        }
    }

    visible: false
    anchors.left: parent.left
    anchors.right: parent.right
    height: visible ? pinnedMessageRow.height : 0

    Rectangle {
        id: pinnedMessageBackground
        anchors.fill: parent
        opacity: 0.1
        color: Theme.secondaryColor
    }

    Row {
        id: pinnedMessageRow

        width: parent.width

        IconButton {
            id: pinnedMessageButton
            width: Theme.itemSizeLarge
            height: Theme.itemSizeLarge
            icon.source: "image://theme/icon-m-mark-unread"
            onClicked: {
                pinnedMessageItem.requestShowMessage();
            }
        }

        Item {
            width: parent.width - pinnedMessageButton.width - unpinMessageIconLoader.width - removePinnedMessageIconButton.width
            height: pinnedMessageColumn.height
            anchors.verticalCenter: parent.verticalCenter
            Column {
                id: pinnedMessageColumn
                spacing: Theme.paddingSmall
                width: parent.width

                Label {
                    id: pinnedMessageUserText

                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.weight: Font.ExtraBold
                    color: Theme.primaryColor
                    maximumLineCount: 1
                    truncationMode: TruncationMode.Fade
                    textFormat: Text.StyledText
                    horizontalAlignment: Text.AlignLeft
                }

                Label {
                    id: pinnedMessageText

                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.primaryColor
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                    textFormat: Text.StyledText
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pinnedMessageItem.requestShowMessage();
                }
            }
        }

        Loader {
            id: unpinMessageIconLoader
            asynchronous: true
            active: !!canPinMessages()
            Behavior on opacity { FadeAnimation {} }
            width: active ? item.width : 0
            height: active ? item.height : 0
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: Component {
                IconButton {
                    id: unpinMessageIconButton
                    icon.source: "image://theme/icon-m-remove"
                    onClicked: {
                        Remorse.itemAction(pinnedMessageRow, qsTr("Message unpinned"), function() { tdLibWrapper.unpinMessage(chatPage.chatInformation.id, pinnedMessage.id);
                                                                                                     pinnedMessageItem.requestCloseMessage(); });

                    }
                }
            }
        }

        IconButton {
            id: removePinnedMessageIconButton
            icon.source: "image://theme/icon-m-clear"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                pinnedMessageItem.requestCloseMessage();
                pinnedMessage = undefined;
            }
        }
    }
}
