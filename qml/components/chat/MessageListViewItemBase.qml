import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../messageContent'
import '../tdlib'
import '../../js/twemoji.js' as Emoji
import '../../js/functions.js' as Functions
import '../../js/debug.js' as Debug

ListItem {
    id: messageListItem

    contentHeight: messageBackground.height + messageTextRow.y + Theme.paddingSmall/2
    Behavior on contentHeight { NumberAnimation { duration: 200 } }

    property QtObject precalculatedValues: ListView.view.precalculatedValues
    property MessageData messageData: MessageData {}
    property alias contextMenuLoader: contextMenuLoader
    property alias messageSenderInfo: messageSenderInfo

    readonly property var myMessage: messageData.message
    readonly property var messageId: messageData.messageId
    readonly property int messageIndex: messageData.messageIndex
    readonly property var messageAlbumMessageIds: messageData.messageAlbumMessageIds
    readonly property var messageAlbumMessages: messageData.messageAlbumMessages
    readonly property int messageViewCount: messageData.messageViewCount
    readonly property var reactions: messageData.reactions
    readonly property bool generatedContentUnread: messageData.generatedContentUnread
    readonly property bool isFirstInSequence: messageData.isFirstInSequence
    readonly property bool isLastInSequence: messageData.isLastInSequence

    readonly property bool isAlbum: messageData.isAlbum

    readonly property bool isOwnMessage: messageData.isOwnMessage
    readonly property bool isOutgoing: messageData.isOutgoing
    readonly property bool isOutgoingRead: messageData.isOutgoingRead

    readonly property Page page: precalculatedValues.page
    readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting
                                       && messagesView.selectedMessages.some(function(existingMessage) { return existingMessage.id === messageId })
                                       && (messageAlbumMessageIds.length === 0 || messageAlbumMessageIds.every(function(id) {
                                           return messagesView.selectedMessages.some(function(m) { return m.id == id })
                                       }))

    property bool wasNavigatedTo: false
    property bool backgroundHighlighted: (messageListItem.highlighted || down || isSelected) && !menuOpen

    // Highlighting is provided by the rounded rectangle :D (except for navigation)
    highlighted: wasNavigatedTo
    contentItem.color: highlighted ? highlightedColor : 'transparent' // by default it's binded to _showPress, which is also true when pressTimer is running, which doesn't suit us
    openMenuOnPressAndHold: !messageListItem.precalculatedValues.pageIsSelecting

    signal clickedNormally

    function openContextMenu() {
        if (menu && menu.isMessageListViewItemMainContextMenu)
            openMenu()
        else
            contextMenuLoader.open()
    }

    onClicked:
        if (messageListItem.precalculatedValues.pageIsSelecting)
            messagesView.toggleMessageSelection(myMessage, messageAlbumMessageIds)
        else {
            clickedNormally()
            elementSelected(index)
        }

    onPressAndHold:
        if (openMenuOnPressAndHold)
            openContextMenu()
        else {
            messagesView.selectedMessages = []
            messagesView.state = ""
        }

    onMenuOpenChanged:
        // When opening/closing the context menu, we no longer scroll automatically
        chatView.manuallyScrolledToBottom = false

    Connections {
        target: messagesView
        onNavigatedTo:
            if (targetIndex === index) {
                messageListItem.wasNavigatedTo = true
                restoreNormalityTimer.start()
            }
    }

    MessageContextMenu {
        id: contextMenuLoader
        listItem: messageListItem
        messageData: messageListItem.messageData

        onReady: {
            messageListItem.menu = item
            messageListItem.openMenu()
        }
    }

    TDLibMessageSender {
        id: messageSenderInfo
        messageSender: myMessage.sender_id
    }

    Timer {
        id: restoreNormalityTimer

        repeat: false
        running: false
        interval: 1000
        triggeredOnStart: false
        onTriggered: {
            Debug.log("Restore normality for index", index)
            messageListItem.wasNavigatedTo = false
        }
    }
}
