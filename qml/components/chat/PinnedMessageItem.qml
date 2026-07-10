import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../../js/twemoji.js' as Emoji
import '../../js/debug.js' as Debug

Item {
    id: root
    width: parent.width
    height: visible ? pinnedMessagesView.height : 0

    property int viewBottomModelIndex: chatProxyModel.mapRowFromSource(messagesView.bottomIndex, -1)
    property var viewCurrentMessageId: messagesView.messagesModel.getMessage(viewBottomModelIndex).id || 0
    signal hide

    Connections {
        target: chatPage
        onLoadingChanged:
            viewBottomModelIndex = Qt.binding(function() {
                return chatProxyModel.mapRowFromSource(messagesView.bottomIndex, -1)
            })
    }

    visible: !!pinnedMessagesView.count

    SequentialAnimation {
        id: hideAnimation
        ParallelAnimation {
            FadeAnimator { target: root }
            NumberAnimation { target: root; property: 'height'; to: 0; duration: 200 }
        }
        ScriptAction { script: hide() }
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

                // Load from message ID 0 (the end). MediaMessagesModel will ignore the request if it's already the case
                Component.onCompleted:
                    pinnedMessagesModel.init(chatPage.chatId)

                PageHeader {
                    id: header
                    title: qsTr("%Ln pinned messages", "", pinnedMessagesModel.totalCount)
                }

                MessagesView {
                    id: allPinnedMessagesView
                    width: parent.width
                    anchors {
                        top: header.bottom
                        bottom: parent.bottom
                    }

                    messagesModel: pinnedMessagesModel
                    newMessageColumn.show: false
                    readable: false

                    onJumpedTo: {
                        pinnedMessagesModel.locked = true
                        pinnedMessagesView.currentIndex = index == 0 ? pinnedMessagesView.count - 1 : index-1
                        messagesView.showMessage(messageId)
                        pageStack.pop()
                    }

                    viewPlaceholder.text: qsTr("No pinned messages")
                    PushUpMenu {
                        parent: allPinnedMessagesView.chatView
                        MenuItem {
                            text: qsTr("Unpin all messages")
                            onClicked: {
                                allPinnedMessagesView.forceViewPlaceholder = true
                                var remorse = Remorse.popupAction(chatPage, qsTr("Messages unpinned"), function() {
                                    pageStack.pop()
                                    tdLibWrapper.unpinAllChatMessages(chatPage.chatId)
                                })
                                remorse.canceled.connect(function() { allPinnedMessagesView.forceViewPlaceholder = false })
                            }
                        }
                    }

                    chatView.footer: Item { width: 1; height: Theme.paddingLarge }

                    Connections {
                        target: allPinnedMessagesView.chatView
                        onCountChanged:
                            if (!allPinnedMessagesView.chatView.count)
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
        cacheSize: 2
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

            property bool locked
            property bool lockedEnd
            function unlock() {
                Debug.log("[PinnedMessageItem] Unlocked")
                locked = lockedEnd = false
            }

            property var currentMessageIndex: messageIndexBeforeId(viewCurrentMessageId)
            function updateCurrentMessageIndex() {
                currentMessageIndex = Qt.binding(function() { return messageIndexBeforeId(viewCurrentMessageId) })
            }

            onMessagesReceived: {
                updateCurrentMessageIndex()

                if (!fromIncrementalUpdate) {
                    if (lockedEnd)
                        pinnedMessagesView.currentIndex = pinnedMessagesView.count - 1

                    if (viewCurrentMessageId)
                        // Load some more messages to ensure endReached is correctly set
                        loadMoreFuture()
                }
            }
            onTotalCountChanged: updateCurrentMessageIndex()

            function handleCurrentMessageIndexChanged(doUnlock) {
                if (doUnlock) unlock()
                else if (locked) return

                // don't use a property so there wouldn't be a need for special handling for when the message moves (e.g. due to deletion of another message)
                pinnedMessagesView.currentIndex = currentMessageIndex

                if (!loading && currentMessageIndex < 0 || (currentMessageIndex === pinnedMessagesView.count - 1 && !endReached))
                    init(chatPage.chatId, viewCurrentMessageId) // re-initialize
            }

            Component.onCompleted: init(chatPage.chatId, viewCurrentMessageId)
            onCurrentMessageIndexChanged: handleCurrentMessageIndexChanged()
        }

        Connections {
            target: chatView
            onMovementEnded:
                pinnedMessagesModel.handleCurrentMessageIndexChanged(true)
        }
        Connections {
            target: chatView
            onCountChanged:
                if (pinnedMessagesModel.getMessageIndex(messagesView.messageIdToScrollTo) !== pinnedMessagesView.currentIndex + 1)
                    pinnedMessagesModel.handleCurrentMessageIndexChanged(true)
        }

        onCurrentIndexChanged: {
            Debug.log("[PinnedMessageItem] Current index changed", currentIndex)
            if (currentIndex <= 10)
                model.loadMoreHistory()
            else if (currentIndex >= count - 1 - 10)
                model.loadMoreFuture()

            if ((model.locked && (!model.lockedEnd || currentIndex == count - 1)) || currentIndex != model.currentMessageIndex) {
                Debug.log("[PinnedMessageItem] Current index changed due to a drag")
                model.locked = true
                model.lockedEnd = false
                if (currentItem)
                    messagesView.showMessage(currentItem.messageId)
            }
        }

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

            onClicked: {
                pinnedMessagesModel.locked = true
                if (pinnedMessagesView.currentIndex == 0) {
                    if (pinnedMessagesModel.endReached) {
                        pinnedMessagesModel.lockedEnd = false
                        pinnedMessagesView.currentIndex = pinnedMessagesView.count - 1
                    } else {
                        pinnedMessagesModel.lockedEnd = true
                        pinnedMessagesModel.init(chatPage.chatId)
                    }
                } else
                    pinnedMessagesView.currentIndex--

                messagesView.showMessage(messageId)
            }

            Row {
                anchors.fill: parent

                Icon {
                    id: pinnedMessageButton
                    width: Theme.iconSizeMedium
                    height: width
                    anchors {
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.paddingMedium
                        rightMargin: Theme.paddingMedium
                    }
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

            Component {
                id: menuComponent
                ContextMenu {
                    MenuItem {
                        text: qsTr("All pinned messages")
                        onClicked: pageStack.push(pinnedMessagesPageComponent)
                    }
                }
            }
            menu: pinnedMessagesView.count ? menuComponent : null
        }
    }
}
