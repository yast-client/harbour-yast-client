import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import "../../js/twemoji.js" as Emoji

Item {
    id: root
    width: parent.width
    height: visible ? Theme.itemSizeMedium : 0

    //property var beforeMessageId // TODO
    signal hide

    visible: !!pinnedMessagesView.count

    SequentialAnimation {
        id: hideAnimation
        ParallelAnimation {
            FadeAnimator { target: root }
            NumberAnimation { target: root; property: 'height'; to: 0; duration: 200 }
        }
        ScriptAction {
            script: hide()
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.1
        color: Theme.secondaryColor
    }

    Component {
        id: pinnedMessagesPageComponent
        Page {
            objectName: 'pinnedMessagesPage'
            SilicaFlickable {
                anchors.fill: parent

                PageHeader {
                    id: header
                    title: qsTr("%Ln pinned messages", "", pinnedMessagesModel.totalCount)
                }

                MessagesView {
                    width: parent.width
                    anchors {
                        top: header.bottom
                        bottom: parent.bottom
                    }

                    messagesModel: pinnedMessagesModel
                    newMessageColumn.show: false
                    readable: false

                    PushUpMenu {
                        parent: chatView
                        MenuItem {
                            text: qsTr("Unpin all messages")
                            onClicked: {
                                // todo..
                                //Remorse.popupAction(chatPage, qsTr("Messages unpinned"), function() { tdLibWrapper.unpinAllChatMessages(..) })
                            }
                        }
                    }
                }
            }
        }
    }

    PagedView {
        id: pinnedMessagesView
        anchors.fill: parent
        direction: PagedView.TopToBottom
        wrapMode: PagedView.NoWrap
        // Workaround weird PagedView animation behavior with small height
        moveDuration: 100
        clip: moving
        moveDragThreshold: height/3

        model: pinnedMessagesModel

        MediaMessagesModel {
            id: pinnedMessagesModel
            tdlib: tdLibWrapper
            filter: TDLibAPI.SearchMessagesFilterPinned
            maintainCount: true
            Component.onCompleted: init(chatPage.chatId)
        }

        currentIndex: count - 1 // todo beforeMessageId

        //onCurrentIndexChanged: if (...) loadMoreHistory(..) else if (...) loadMoreFuture(..) .... // todo

        delegate: BackgroundItem {
            id: pinnedMessageItem
            width: PagedView.contentWidth
            height: PagedView.contentHeight

            //property bool isOwnMessage: tdLibWrapper.myUserId === myMessage.sender_id.user_id
            property var messageId: model.message_id
            property var messageData: model.display

            // NOTE: Unigram uses getChatMessagePosition from TDLib (doesn't mean this is worse:)
            property int reversedTotalPosition: pinnedMessagesModel.totalCount - (pinnedMessagesView.count - index) + 1

            MessagePropertiesLoader {
                id: messageProperties
                chatId: chatPage.chatId
                messageId: pinnedMessageItem.messageId
            }

            /*TDLibMessageSender {
                id: messageSenderInfo
                messageSender: isOwnMessage ? undefined : myMessage.sender_id
            }*/

            onClicked: messagesView.showMessage(messageId, true)

            Row {
                anchors.fill: parent

                Icon {
                    id: pinnedMessageButton
                    width: Theme.itemSizeMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    source: 'image://theme/icon-m-mark-unread'
                }

                Column {
                    width: parent.width - pinnedMessageButton.width - unpinMessageIcon.width - removePinnedMessageIconButton.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall

                    // TODO (TBD): return sender name, perhaps also add profile photo?
                    Label {
                        width: parent.width
                        //text: Emoji.emojify(isOwnMessage ? qsTr("You") : messageSenderInfo.title, font.pixelSize)
                        text: {
                            if (index === pinnedMessagesView.count - 1)
                                return qsTr("Pinned message")
                            if (pinnedMessagesModel.totalCount <= 2)
                                return qsTr("Previous message") // TBD??

                            return qsTr("Pinned message #%Ln", '', reversedTotalPosition)
                        }
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.weight: Font.ExtraBold
                        color: Theme.primaryColor
                        maximumLineCount: 1
                        truncationMode: TruncationMode.Fade
                        textFormat: Text.StyledText
                        horizontalAlignment: Text.AlignLeft
                    }

                    // TODO: media minithumbnail
                    Label {
                        width: parent.width
                        text: Emoji.emojify(utilities.getMessageText(pinnedMessageItem.messageData, Utilities.MessageTextSimple, true), font.pixelSize)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                        maximumLineCount: 1
                    }
                }

                // TODO: bot button

                IconButton {
                    id: unpinMessageIcon
                    visible: !!messageProperties.properties.can_be_pinned
                    width: visible ? Theme.iconSizeMedium : 0
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: 'image://theme/icon-m-remove'
                    onClicked:
                        Remorse.itemAction(pinnedMessageRow, qsTr("Message unpinned"), function() {
                            tdLibWrapper.unpinMessage(chatPage.chatId, messageId)
                        })
                }

                IconButton {
                    id: removePinnedMessageIconButton
                    icon.source: "image://theme/icon-m-clear" // icon-splus-hide-password?
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: hide()
                }
            }
        }
    }
}
