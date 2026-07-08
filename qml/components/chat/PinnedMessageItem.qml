import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import "../../js/twemoji.js" as Emoji

Item {
    id: root
    width: parent.width
    height: visible ? pinnedMessagesView.height : 0

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
                    id: pinnedMessagesView
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
                            onClicked:
                                Remorse.popupAction(chatPage, qsTr("Messages unpinned"), function() {
                                    tdLibWrapper.unpinAllChatMessages(chatPage.chatId)
                                    pageStack.pop()
                                })
                        }
                    }

                    Connections {
                        target: chatView
                        onCountChanged:
                            if (!chatView.count)
                                pageStack.pop()
                    }
                }
            }
        }
    }

    PagedView {
        id: pinnedMessagesView
        width: parent.width
        height: currentItem ? currentItem.height : Theme.itemSizeMedium
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

        delegate: ListItem {
            id: pinnedMessageItem
            width: PagedView.contentWidth
            contentHeight: Theme.itemSizeMedium

            property var messageId: model.message_id
            property var messageData: model.display

            // NOTE: Unigram uses getChatMessagePosition from TDLib (doesn't mean this is worse:)
            property int reversedTotalPosition: pinnedMessagesModel.totalCount - (pinnedMessagesView.count - index) + 1

            MessagePropertiesLoader {
                id: messageProperties
                chatId: chatPage.chatId
                messageId: pinnedMessageItem.messageId
            }

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

                    // TBD: should we use a sender name here, perhaps also with a profile photo?
                    Label {
                        width: parent.width
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
                        pinnedMessageItem.remorseAction(qsTr("Message unpinned"), function() {
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

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("All pinned messages")
                        onClicked: pageStack.push(pinnedMessagesPageComponent)
                    }
                }
            }
        }
    }
}
