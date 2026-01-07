/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import App.Logic 1.0
import ".."

import "../../js/debug.js" as Debug
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

Column {
    id: messagesView

    property var messagesModel: chatManager.model
    property var topicId
    property string forumTopicName
    property int messageSource: TDLibAPI.MessageSourceAuto
    property var draftMessage: chatInformation.draft_message

    property var selectedMessages: []
    readonly property bool isSelecting: selectedMessages.length > 0
    property bool containsSponsoredMessages: false
    property string messageIdToScrollTo
    property int unreadCount: chatInformation.unread_count
    property bool isPrepared

    property alias chatView: chatView
    property alias newMessageColumn: newMessageColumn
    property alias newMessageInReplyToRow: newMessageColumn.newMessageInReplyToRow
    property alias knownUsersRepeater: newMessageColumn.knownUsersRepeater
    property alias attachmentPreviewRow: newMessageColumn.attachmentPreviewRow
    property alias newMessageTextField: newMessageColumn.newMessageTextField
    property alias attachmentOptionsFlickable: newMessageColumn.attachmentOptionsFlickable
    property alias stickerPickerLoader: stickerPickerLoader
    property alias allowedOrientations: newMessageColumn.allowedOrientations

    property bool overlayActive: stickerPickerLoader.active || voiceNoteOverlayLoader.active || messageOverlayLoader.active || stickerSetOverlayLoader.active

    signal resetElements()
    signal elementSelected(int elementIndex)
    signal navigatedTo(int targetIndex)

    function log() {
        var a = Array.prototype.slice.call(arguments)
        a.splice(0,0,'[MessagesView] '+chatInformation.id)
        Debug.log.apply(console, a)
    }

    function getMessageStatusText(message, listItemIndex, viewCount, useElapsed) {
        var lastReadSentIndex = messagesModel.lastReadSentMessageIndex
        log("Last read sent index: " + lastReadSentIndex)

        if(!message) return ""
        if (message['@type'] === "sponsoredMessage")
            return message.is_recommended ? qsTr("Recommended Message") : qsTr("Sponsored Message")

        var messageStatusSuffix = ''

        if (message.edit_date > 0)
            messageStatusSuffix += " - " + qsTr("edited")

        if (chatPage.myUserId === message.sender_id.user_id) {
            messageStatusSuffix += "&nbsp;&nbsp;"
            if (listItemIndex <= lastReadSentIndex) {
                // Read by other party
                messageStatusSuffix += Emoji.emojify("✅", Theme.fontSizeTiny)
            } else {
                // Not yet read by other party
                if (message.sending_state) {
                    if (message.sending_state['@type'] === "messageSendingStatePending")
                        messageStatusSuffix += Emoji.emojify("🕙", Theme.fontSizeTiny)
                    else
                        // Sending failed...
                        messageStatusSuffix += Emoji.emojify("❌", Theme.fontSizeTiny)
                } else
                    messageStatusSuffix += Emoji.emojify("☑️", Theme.fontSizeTiny)
            }
        }

        if (message.author_signature && !chatView.precalculatedValues.showUserInfo)
            messageStatusSuffix += " - " + message.author_signature

        if (Debug.enabled)
            messageStatusSuffix += " (ID: " + message.id + ")"

        return (viewCount > 0 ? (Emoji.emojify('👁️ ', Theme.fontSizeTiny) + Functions.getShortenedCount(viewCount) + ' ') : '')
                + (useElapsed ? Functions.getDateTimeElapsed(message.date) : Functions.getDateTimeTranslated(message.date))
                + messageStatusSuffix
    }

    function sendMessage() {
        // TODO: in other places where we use TDLibWrapper send message functions, correctly specify topic ID
        if (newMessageColumn.editMessageId !== "0")
            (newMessageColumn.editIsCaption ? tdLibWrapper.editMessageCaption : tdLibWrapper.editMessageText)
                    (chatInformation.id, newMessageColumn.editMessageId, newMessageTextField.text)
        else {
            if (attachmentPreviewRow.visible) {
                function sendFile(messageType, fileType, filePath, additionalOptions) {
                    filePath = typeof filePath === 'undefined' ? attachmentPreviewRow.fileProperties.filePath : filePath

                    tdLibWrapper.sendFileMessage(chatInformation.id, messageType, fileType, filePath, newMessageTextField.text, newMessageColumn.replyToMessageId, topicId, additionalOptions)
                }

                if (attachmentPreviewRow.isPicture)
                    sendFile('inputMessagePhoto', 'photo')
                else if (attachmentPreviewRow.isVideo)
                    sendFile('inputMessageVideo', 'video')
                else if (attachmentPreviewRow.isDocument)
                    sendFile('inputMessageDocument', 'document')
                else if (attachmentPreviewRow.isVoiceNote)
                    sendFile('inputMessageVoiceNote', 'voice_note', utilities.voiceNotePath)
                else if (attachmentPreviewRow.isLocation)
                    tdLibWrapper.sendLocationMessage(chatInformation.id, attachmentPreviewRow.locationData.latitude, attachmentPreviewRow.locationData.longitude, attachmentPreviewRow.locationData.horizontalAccuracy, newMessageColumn.replyToMessageId, topicId)

                messagesView.clearAttachmentPreviewRow()
            } else if (chatPage.hasSendPrivilege('can_send_other_messages') && tdLibWrapper.isDiceEmoji(newMessageTextField.text))
                tdLibWrapper.sendDiceMessage(chatInformation.id, newMessageTextField.text, newMessageColumn.replyToMessageId, topicId)
            else
                tdLibWrapper.sendTextMessage(chatInformation.id, newMessageTextField.text, newMessageColumn.replyToMessageId, topicId)

            if(appSettings.focusTextAreaAfterSend)
                lostFocusTimer.start()
        }
        newMessageInReplyToRow.inReplyToMessage = null
        newMessageColumn.editMessageId = "0"
        newMessageColumn.editIsCaption = false
        utilities.stopGeoLocationUpdates()
    }

    function setMessageText(text, doSend) {
        if(doSend)
            tdLibWrapper.sendTextMessage(chatInformation.id, text, 0)
        else {
            newMessageTextField.text = text
            newMessageTextField.cursorPosition = text.length
            lostFocusTimer.start()
        }

    }

    function showMessage(messageId, initialRun) {
        // Means we tapped a quoted message and had to load it.
        if(initialRun)
            messageIdToScrollTo = messageId

        if (messageIdToScrollTo) {
            var index = messagesModel.getMessageIndex(messagesView.messageIdToScrollTo)
            var proxyIndex = chatProxyModel.mapRowFromSource(index, -1)
            if(proxyIndex !== -1) {
                messageIdToScrollTo = ""
                chatView.scrollToIndex(proxyIndex)
                navigatedTo(proxyIndex)
            } else if(initialRun)
                // we only want to do this once.
                messagesModel.loadHistoryForMessage(messageIdToScrollTo)
        }
    }

    function clearAttachmentPreviewRow() {
        attachmentPreviewRow.isPicture = false
        attachmentPreviewRow.isVideo = false
        attachmentPreviewRow.isDocument = false
        attachmentPreviewRow.isVoiceNote = false
        attachmentPreviewRow.isLocation = false
        attachmentPreviewRow.fileProperties = null
        attachmentPreviewRow.locationData = null
        attachmentPreviewRow.attachmentDescription = ""
        utilities.stopGeoLocationUpdates()
    }

    function prepareView() {
        if (isPrepared) return
        isPrepared = true

        if (draftMessage && draftMessage.input_message_text) {
            newMessageTextField.text = draftMessage.input_message_text.text.text
            if(draftMessage.reply_to_message_id)
                tdLibWrapper.getMessage(chatInformation.id, draftMessage.reply_to_message_id)
        }
    }

    states: [
        State {
            name: "selectMessages"
            when: isSelecting
            PropertyChanges {
                target: chatNameText
                text: qsTr("Select Messages")
            }
            PropertyChanges {
                target: chatStatusText
                text: qsTr("%Ln messages selected", "number of messages selected", messagesView.selectedMessages.length)
            }
            PropertyChanges {
                target: newMessageTextField
                focus: false
            }
        }
    ]

    function deselectMessage(message) {
        for (var i = 0; i < selectedMessages.length; i++) {
            if(selectedMessages[i].id === message.id) {
                delete selectedMessages[i].properties
                selectedMessages.splice(i, 1)
                return true
            }
        }
        return false
    }
    function selectMessage(message) {
        message.properties = {}
        selectedMessages.push(message)
        tdLibWrapper.getMessageProperties(message.chat_id, message.id)
    }

    function toggleSingleMessageSelection(message) {
        if (deselectMessage(message)) {
            selectedMessagesChanged()
            return
        }

        selectMessage(message)
        selectedMessagesChanged()
    }
    function toggleMultipleMessagesSelection(messages) {
        var i;
        if (messages.every(function(m) {
            return selectedMessages.some(function(selectedMessage) {
                return selectedMessage.id === m.id
            })
        })) {
            for (i=0; i < messages.length; i++)
                deselectMessage(messages[i])
            selectedMessagesChanged()
            return
        }

        for (i=0; i < messages.length; i++)
            selectMessage(messages[i]);
        selectedMessagesChanged()
    }

    function toggleMessageSelection(message, albumMessageIds) {
        if (!albumMessageIds || message.media_album_id === '0' || albumMessageIds.length <= 1)
            toggleSingleMessageSelection(message)
        else {
            var albumMessages = [message]
            messagesModel.getMessagesForAlbum(message.media_album_id, 1).forEach(function(m) { albumMessages.push(m) })
            toggleMultipleMessagesSelection(albumMessages)
        }
    }

    Connections {
        target: tdLibWrapper
        onMessagePropertiesReceived: {
            for (var i = 0; i < selectedMessages.length; i++) {
                if (selectedMessages[i].id === messageId) {
                    selectedMessages[i].properties = messageProperties
                    selectedMessagesChanged()
                    break
                }
            }
        }
    }

    Binding {
        target: chatPage
        property: 'loading'
        value: !messagesModel || messagesModel.loading
    }

    Connections {
        target: messagesModel
        ignoreUnknownSignals: true
        onMessagesReceived: {
            var originalScrollPosition = messagesModel.calculateScrollPosition()
            var scrollPosition = chatProxyModel.mapRowFromSource(originalScrollPosition, -1)
            log("Messages received, from incremental update:", fromIncrementalUpdate, ", view has", chatView.count, "messages, possibly need to scroll to", scrollPosition, "("+originalScrollPosition+")")

            if (!fromIncrementalUpdate || (!chatPage.isInitialized && scrollPosition > -1))
                chatView.scrollToIndex(scrollPosition)

            if (!fromIncrementalUpdate) {
                if (chatHeader.visible && scrollPosition >= (chatView.count - 10)) {
                    log("Not far from the end, loading more future...")
                    chatView.inCooldown = true
                    messagesModel.loadMoreFuture()
                }
            }

            if (chatView.height > chatView.contentHeight) {
                log("Chat content quite small...")
                viewMessageTimer.queueViewMessage(chatView.count - 1)
            } else if (fromIncrementalUpdate && messagesView.messageIdToScrollTo && messagesView.messageIdToScrollTo != "")
                showMessage(messagesView.messageIdToScrollTo, false)

            chatViewCooldownTimer.restart()
            chatViewStartupReadTimer.restart()

            /*
            // Double-tap for reactions is currently disabled, let's see if we'll ever need it again
            if (!fromIncrementalUpdate) {
                var remainingDoubleTapHints = appSettings.remainingDoubleTapHints;
                log("Remaining double tap hints: " + remainingDoubleTapHints);
                if (remainingDoubleTapHints > 0) {
                    doubleTapHintTimer.start();
                    tapHint.visible = true;
                    tapHintLabel.visible = true;
                    appSettings.remainingDoubleTapHints = remainingDoubleTapHints - 1;
                }
            }
             */

        }
        onNewMessageReceived: {
            if ((chatView.manuallyScrolledToBottom && Qt.application.state === Qt.ApplicationActive) || message.sender_id.user_id === chatPage.myUserId) {
                log("Own message received or was scrolled to bottom, scrolling down to see it...")
                chatView.scrollToIndex(chatView.count - 1)
                viewMessageTimer.queueViewMessage(chatView.count - 1)
            }
        }
    }

    Connections {
        target: chatManager
        ignoreUnknownSignals: true
        onPinnedMessageChanged: {
            if (chatManager.pinnedMessageId !== 0) {
                log("Loading pinned message ", chatManager.pinnedMessageId)
                tdLibWrapper.getMessage(chatInformation.id, chatManager.pinnedMessageId)
            } else pinnedMessageItem.pinnedMessage = undefined
        }
    }

    Connections {
        target: tdLibWrapper
        onReceivedMessage: {
            if (message.is_pinned) {
                log("Received pinned message")
                pinnedMessageItem.pinnedMessage = message
            }
            if (draftMessage && messageId === draftMessage.reply_to_message_id) {
                newMessageInReplyToRow.inReplyToMessage = message
            }
            log("Received message ID: " + messageId)
        }
        onSponsoredMessagesReceived: messagesView.containsSponsoredMessages = true
    }

    Component.onCompleted: {
        log("Initializing")
        chatView.currentIndex = -1
    }

    Component.onDestruction: {
        if (chatPage.canSendMessages && !chatPage.isDeletedUser)
            tdLibWrapper.setChatDraftMessage(chatInformation.id, messagesView.newMessageColumn.replyToMessageId, newMessageTextField.text, topicId)
        chatActionTimer.stop()
        utilities.stopGeoLocationUpdates()
    }

    Connections {
        target: pageStack
        onCurrentPageChanged:
            if (pageStack.currentPage && pageStack.currentPage.isChatInformationPage)
                resetElements()
    }

    Timer {
        id: lostFocusTimer
        interval: 200
        running: false
        repeat: false
        onTriggered:
            newMessageTextField.forceActiveFocus()
    }

    Timer {
        id: viewMessageTimer
        interval: appSettings.delayMessageRead ? 1000 : 0
        property int lastQueuedIndex: -1
        function queueViewMessage(index) {
            if (index > lastQueuedIndex) {
                lastQueuedIndex = index
                start()
            }
        }

        onTriggered: {
            log("scroll position changed, message index: ", lastQueuedIndex)
            log("unread count: ", unreadCount)
            var modelIndex = chatProxyModel.mapRowToSource(lastQueuedIndex)
            var messageToRead = messagesModel.getMessage(modelIndex)
            if (messageToRead['@type'] === "sponsoredMessage") {
                log("sponsored message to read: ", messageToRead.id)
                tdLibWrapper.viewMessage(chatInformation.id, messageToRead.message_id, false, messageSource)
            } else if (unreadCount > 0 && lastQueuedIndex > -1) {
                if (messageToRead) {
                    log("message to read: ", messageToRead.id)
                    var messageId = messageToRead.id
                    var type = messageToRead.content["@type"]
                    if (messageToRead.media_album_id !== '0') {
                        var albumIds = messagesModel.getMessageIdsForAlbum(messageToRead.media_album_id)
                        if (albumIds.length > 0) {
                            messageId = albumIds[albumIds.length - 1]
                            log("message to read last album message id: ", messageId)
                        }
                    }
                    if (messageId)
                        tdLibWrapper.viewMessage(chatInformation.id, messageId, false, messageSource)
                }
                lastQueuedIndex = -1
            }
            if (unreadCount === 0) {
                tdLibWrapper.readAllChatMentions(chatInformation.id)
                tdLibWrapper.readAllChatReactions(chatInformation.id)
            }
        }
    }

    PinnedMessageItem {
        id: pinnedMessageItem
        onRequestShowMessage: {
            messageOverlayLoader.overlayMessage = pinnedMessageItem.pinnedMessage
            messageOverlayLoader.active = true
        }
        onRequestCloseMessage: {
            messageOverlayLoader.overlayMessage = undefined
            messageOverlayLoader.active = false
        }
    }

    Item {
        id: chatViewItem
        width: parent.width
        height: parent.height - pinnedMessageItem.height - newMessageColumn.height - selectedMessagesActions.height

        property int previousHeight

        Component.onCompleted:
            previousHeight = height

        onHeightChanged: {
            if (previousHeight > height) {
                var deltaHeight = previousHeight - height
                chatView.contentY = chatView.contentY + deltaHeight
            } else
                chatView.handleScrollPositionChanged()
            previousHeight = height
        }

        Timer {
            id: chatViewCooldownTimer
            interval: 2000
            onTriggered: {
                log("Cooldown completed...")
                chatView.inCooldown = false

                if (!chatPage.isInitialized) {
                    log("Page is initialized!")
                    chatPage.isInitialized = true
                    chatView.handleScrollPositionChanged()
                }
            }
        }

        Timer {
            id: chatViewStartupReadTimer
            interval: 200
            onTriggered: {
                if (!chatPage.isInitialized) {
                    log("Page is initialized!")
                    chatPage.isInitialized = true
                    chatView.handleScrollPositionChanged()
                    if (chatPage.isChannel || chatPage.isBot)
                        tdLibWrapper.getChatSponsoredMessages(chatInformation.id)
                }
            }
        }

        Loader {
            asynchronous: true
            active: chatView.blurred
            anchors.fill: chatView
            sourceComponent: Component {
                FastBlur {
                    source: chatView
                    radius: Theme.paddingLarge
                }
            }
        }

        SilicaListView {
            id: chatView

            visible: !blurred
            property bool blurred: messageOverlayLoader.item || stickerPickerLoader.item || voiceNoteOverlayLoader.item || inlineQuery.hasOverlay || stickerSetOverlayLoader.item

            anchors.fill: parent
            opacity: chatPage.loading ? 0 : 1
            Behavior on opacity { FadeAnimation {} }
            clip: true
            highlightMoveDuration: 0
            highlightResizeDuration: 0
            property int lastReadSentIndex: -1
            property bool inCooldown: false
            property bool manuallyScrolledToBottom
            property QtObject precalculatedValues: QtObject {
                readonly property var page: chatPage
                readonly property alias view: messagesView
                readonly property bool showUserInfo: page.isBasicGroup || (page.isSuperGroup && (!page.isChannel || chatGroupInformation.show_message_sender))
                readonly property int profileThumbnailDimensions: showUserInfo ? Theme.itemSizeSmall : 0
                readonly property int pageMarginDouble: 2 * Theme.horizontalPageMargin
                readonly property int paddingMediumDouble: 2 * Theme.paddingMedium
                readonly property int entryWidth: chatView.width - pageMarginDouble
                readonly property int textItemWidth: entryWidth - profileThumbnailDimensions - Theme.paddingSmall
                readonly property int backgroundWidth: page.isChannel ? textItemWidth : textItemWidth - pageMarginDouble
                readonly property int backgroundRadius: textItemWidth/50
                readonly property int textColumnWidth: backgroundWidth - Theme.horizontalPageMargin
                readonly property int messageInReplyToHeight: Theme.fontSizeExtraSmall * 2.571428571 + Theme.paddingSmall
                readonly property int webPagePreviewHeight: ( (textColumnWidth * 2 / 3) + (6 * Theme.fontSizeExtraSmall) + ( 7 * Theme.paddingSmall) )
                readonly property bool pageIsSelecting: messagesView.isSelecting
            }

            function handleScrollPositionChanged() {
                log("Current position: ", chatView.contentY)
                log("Contains sponsored messages?", containsSponsoredMessages)
                if (chatHeader.visible && ( unreadCount > 0 || containsSponsoredMessages ) ) {
                    var bottomIndex = chatView.indexAt(chatView.contentX, ( chatView.contentY + chatView.height - Theme.horizontalPageMargin ))
                    if (bottomIndex > -1)
                        viewMessageTimer.queueViewMessage(bottomIndex)
                } else {
                    tdLibWrapper.readAllChatMentions(chatInformation.id)
                    tdLibWrapper.readAllChatReactions(chatInformation.id)
                }
                manuallyScrolledToBottom = chatView.atYEnd
            }

            function scrollToIndex(index, mode) {
                log("Scrolling to index", index, "with mode", mode)
                if(index > 0 && index < chatView.count) {
                    positionViewAtIndex(index, (mode === undefined) ? ListView.Contain : mode)
                    if(index === chatView.count - 1) {
                        manuallyScrolledToBottom = true
                        if(!chatView.atYEnd)
                            chatView.positionViewAtEnd()
                    }
                }
            }

            onContentYChanged: {
                if (!chatPage.loading && !chatView.inCooldown) {
                    // check for startReached/endReached here so inCooldown won't be true forever
                    if (!messagesModel.startReached && chatView.indexAt(chatView.contentX, chatView.contentY) < 10) {
                        log("Trying to get older history items...")
                        chatView.inCooldown = true
                        messagesModel.loadMoreHistory()
                    } else if (!messagesModel.endReached && chatHeader.visible && chatView.indexAt(chatView.contentX, chatView.contentY) > ( count - 10)) {
                        log("Trying to get newer history items...")
                        chatView.inCooldown = true
                        messagesModel.loadMoreFuture()
                        // NOTE: it might be needed to call loadMoreFuture() but without the check for endReached inside it
                        // (so, forcefully, and without checking for endReached here in JS),
                        // because sometimes tdlib might not return complete end
                        // this was the previous behavior before endReached and startReached values were introduced
                    }
                }
            }

            onMovementEnded:
                handleScrollPositionChanged()

            onQuickScrollAnimatingChanged: {
                if (!quickScrollAnimating) {
                    handleScrollPositionChanged()
                    if(atYEnd) { // handle some false guesses from quick scroll
                        chatView.scrollToIndex(chatView.count - 2)
                        chatView.scrollToIndex(chatView.count - 1)
                    }
                }
            }

            BoolFilterModel {
                id: chatProxyModel
                sourceModel: messagesModel
                filterRoleName: "album_entry_filter"
                filterValue: false
            }
            model: chatProxyModel
            header: Component {
                Loader {
                    active: !!chatPage.botInformation && chatPage.botInformation.description.length > 0
                    asynchronous: true
                    width: chatView.width
                    sourceComponent: Component {
                        Label {
                            id: botInfoLabel
                            topPadding: Theme.paddingLarge
                            bottomPadding: Theme.paddingLarge
                            leftPadding: Theme.horizontalPageMargin
                            rightPadding: Theme.horizontalPageMargin
                            text: Emoji.emojify(chatPage.botInformation.description, font.pixelSize)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.highlightColor
                            wrapMode: Text.Wrap
                            textFormat: Text.StyledText
                            horizontalAlignment: Text.AlignHCenter
                            onLinkActivated:
                                utilities.handleLink(link, chatInformation.id)
                            linkColor: Theme.primaryColor
                            visible: (text !== "")
                        }
                    }
                }
            }

            function getContentComponentHeight(contentType, content, parentWidth, albumEntries) {
                var unit
                switch(contentType) {
                case "messageAnimatedEmoji":
                    return content.animated_emoji.sticker.height
                case "messageAnimation":
                    return Functions.getVideoHeight(parentWidth, content.animation)
                case "messageAudio":
                case "messageVoiceNote":
                case "messageDocument":
                    return Theme.itemSizeLarge * (albumEntries + 1)
                case "messageGame":
                    return parentWidth * 0.66666666 + Theme.itemSizeLarge // 2 / 3;
                case "messageLocation":
                case "messageVenue":
                    return parentWidth * 0.66666666 // 2 / 3;
                case "messagePhoto":
                    if(albumEntries > 0) {
                        unit = (parentWidth * 0.66666666)
                        return (albumEntries % 2 !== 0 ? unit * 0.75 : 0) + unit * albumEntries * 0.25
                    }
                    var biggest = utilities.findBiggestPhotoSize(content.photo.sizes)
                    var aspectRatio = biggest.width/biggest.height
                    return Math.max(Theme.itemSizeExtraSmall, Math.min(parentWidth * 0.66666666, parentWidth / aspectRatio))
                case "messagePoll":
                    return Theme.itemSizeSmall * (4 + content.poll.options)
                case "messageSticker":
                    return Theme.itemSizeLarge*3 * (content.sticker.width / content.sticker.height)
                case "messageDice":
                    var diceStickers = content.final_state || content.initial_state
                    var sticker = diceStickers['@type'] === 'diceStickersSlotMachine'
                            ? diceStickers.background
                            : diceStickers.sticker

                    return Theme.itemSizeExtraLarge * (sticker.width / sticker.height)
                case "messageVideo":
                    if(albumEntries > 0) {
                        unit = (parentWidth * 0.66666666)
                        return (albumEntries % 2 !== 0 ? unit * 0.75 : 0) + unit * albumEntries * 0.25
                    }
                    return Functions.getVideoHeight(parentWidth, content.video)
                case "messageVideoNote":
                    return parentWidth
                }
            }

            readonly property var fullWidthWidescreenContentMessages: [
                "messageDocument",
                "messageAudio",
                "messagePoll",
                "messageVoiceNote",
            ]
            readonly property var albumMessages: [
                'messagePhoto',
                'messageVideo',
                'messageDocument',
                'messageAudio',
            ]
            readonly property var contentAboveMediaByDefaultMessages: [
                'messagePoll',
                'messageVenue'
            ]

            delegate: Loader {
                width: chatView.width
                Component {
                    id: messageListViewItemComponent
                    MessageListViewItem {
                        precalculatedValues: chatView.precalculatedValues
                        chatId: chatManager.chatId
                        myMessage: model.display
                        messageId: model.message_id
                        messageAlbumMessageIds: model.album_message_ids
                        messageViewCount: model.view_count
                        reactions: model.reactions
                        chatReactions: availableReactions
                        generatedContentUnread: model.generated_content_unread
                        isFirstInSequence: model.is_first_in_sequence
                        isLastInSequence: model.is_last_in_sequence
                        readonly property int originalIndex: model.index
                        messageIndex: chatProxyModel.mapRowToSource(originalIndex)
                        onOriginalIndexChanged: messageIndexTimer.start()
                        Timer {
                            // FIXME: find a better way to fix this
                            id: messageIndexTimer
                            interval: 0
                            onTriggered: messageIndex = Qt.binding(function() { return chatProxyModel.mapRowToSource(originalIndex) })
                        }
                        hasContentComponent: !!myMessage.content && !utilities.messageContentIsService(model.content_type, true)
                        fullWidthWidescreenContent: !!myMessage.content && chatView.fullWidthWidescreenContentMessages.indexOf(model.content_type) > -1
                        contentAboveMedia: !!myMessage.content && chatView.contentAboveMediaByDefaultMessages.indexOf(model.content_type) > -1
                        onReplyToMessage: {
                            newMessageInReplyToRow.inReplyToMessage = myMessage
                            newMessageTextField.focus = true
                        }
                        onEditMessage: {
                            newMessageColumn.editMessageId = messageId
                            newMessageColumn.editIsCaption = !!myMessage && !!myMessage.content && !!myMessage.content.caption
                            newMessageTextField.text = Functions.getMessageText(myMessage, false, chatPage.myUserId, true)
                            newMessageTextField.cursorPosition = newMessageTextField.text.length
                            newMessageTextField.focus = true
                        }
                        onForwardMessage: {
                            startForwardingMessages([myMessage])
                        }
                    }
                }
                Component {
                    id: messageListViewItemSimpleComponent
                    MessageListViewItemSimple {}
                }
                Component {
                    id: messageListViewItemHiddenComponent
                    Item {
                        property var myMessage: display
                        property bool senderIsUser: myMessage.sender_id["@type"] === "messageSenderUser"
                        property var userInformation: senderIsUser ? tdLibWrapper.getUserInformation(myMessage.sender_id.user_id) : null
                        property bool isOwnMessage: senderIsUser && chatPage.myUserId === myMessage.sender_id.user_id
                        height: 1
                    }
                }
                sourceComponent: utilities.messageContentIsService(model.content_type)
                                    ? messageListViewItemSimpleComponent
                                    : messageListViewItemComponent
            }
            VerticalScrollDecorator { flickable: chatView }

            ViewPlaceholder {
                id: chatViewPlaceholder
                enabled: chatView.count === 0 && !(chatPage.botInformation && chatPage.botInformation.description.length > 0)
                text: (chatPage.isSecretChat && !chatPage.isSecretChatReady) ? qsTr("This secret chat is not yet ready. Your chat partner needs to go online first.")
                                                                             : searchInChatItem.visible ? qsTr("No results", "No messages search results found") : qsTr("This chat is empty.")
            }
        }

        BusyLabel {
            Behavior on opacity { FadeAnimator {} }
            anchors.centerIn: parent
            //spacing: Theme.paddingMedium
            text: qsTr("Loading messages...")
            running: chatPage.loading
        }

        Rectangle {
            width: Theme.fontSizeHuge
            height: Theme.fontSizeHuge
            anchors {
                right: parent.right
                rightMargin: Theme.paddingMedium
                bottom: parent.bottom
                bottomMargin: Theme.paddingMedium
            }
            visible: !chatPage.loading && chatHeader.visible && (unreadCount > 0 || (!messagesModel.endReached && chatView.count > 0))
            property bool highlighted: chatUnreadMessagesMouseArea.containsPress

            // not ideal:
            color: Theme.rgba(Theme.highlightBackgroundColor, highlighted ? 1.0 : Theme.highlightBackgroundOpacity)
            radius: width / 2

            Text {
                visible: unreadCount > 0
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.centerIn: parent
                text: Functions.formatUnreadCount(unreadCount)
            }
            Icon {
                visible: unreadCount <= 0
                anchors.centerIn: parent
                source: "image://theme/icon-m-page-down"
            }

            MouseArea {
                id: chatUnreadMessagesMouseArea
                enabled: visible // not sure if it's really needed
                anchors.fill: parent
                onClicked: {
                    // probably not ideal
                    var lastReadIndex = chatProxyModel.mapRowFromSource(messagesModel.lastReadIncomingMessageIndex, -1)
                    log("Scrolling to the bottom lastReadIndex:", lastReadIndex)
                    if (lastReadIndex > -1) {
                        if (chatView.indexAt(chatView.contentX, chatView.contentY) >= lastReadIndex - 2
                                || chatView.indexAt(chatView.contentX + chatView.contentWidth, chatView.contentY + chatView.contentHeight) >= lastReadIndex - 2)
                            if (messagesModel.endReached) chatView.scrollToBottom()
                            else messagesModel.loadEnd(true)
                        else chatView.scrollToIndex(Math.min(lastReadIndex + 1, chatView.count))
                    } else
                        messagesModel.loadEnd()
                }
            }
        }

        Timer {
            id: chatActionTimer
            property string action
            triggeredOnStart: true
            interval: 5000 // from https://core.telegram.org/constructor/updateChatUserTyping: chat action update is valid for 6 seconds
            repeat: true
            onTriggered: if (Qt.application.active)
                             tdLibWrapper.sendChatAction(chatInformation.id, action, topicId)
            onRunningChanged: if (!running)
                                  tdLibWrapper.sendChatAction(chatInformation.id, "chatActionCancel", topicId)
            function run(action) {
                this.action = action
                restart()
            }
        }

        Loader {
            id: stickerPickerLoader
            active: false
            asynchronous: true
            width: parent.width
            height: active ? parent.height : 0
            source: "../StickerPicker.qml"
            onStatusChanged: if (status == Loader.Ready)
                                 chatActionTimer.run("chatActionChoosingSticker")
                             else chatActionTimer.stop()
        }

        Connections {
            target: stickerPickerLoader.item
            onStickerPicked: {
                log("Sticker picked: " + stickerId)
                stickerManager.setNeedsReload(true)
                tdLibWrapper.sendStickerMessage(chatInformation.id, stickerId, newMessageColumn.replyToMessageId)
                stickerPickerLoader.active = false
                attachmentOptionsFlickable.show = false
                newMessageInReplyToRow.inReplyToMessage = null
                newMessageColumn.editMessageId = "0"
                newMessageColumn.editIsCaption = false
            }
        }

        Loader {
            id: messageOverlayLoader

            property var overlayMessage

            active: false
            asynchronous: true
            width: parent.width
            height: active ? parent.height : 0
            sourceComponent: Component {
                MessageOverlayFlickable {
                    overlayMessage: messageOverlayLoader.overlayMessage
                    showHeader: !chatPage.isChannel
                    onRequestClose:
                        messageOverlayLoader.active = false
                }
            }
        }

        Loader {
            id: voiceNoteOverlayLoader
            active: false
            asynchronous: true
            width: parent.width
            height: active ? parent.height : 0
            source: "../VoiceNoteOverlay.qml"
            onActiveChanged: if (!active)
                utilities.stopRecordingVoiceNote()
        }

        Loader {
            id: stickerSetOverlayLoader

            property string stickerSetId

            active: false
            asynchronous: true
            width: parent.width
            height: active ? parent.height : 0
            sourceComponent: Component {
                StickerSetOverlay {
                    stickerSetId: stickerSetOverlayLoader.stickerSetId
                    onRequestClose:
                        stickerSetOverlayLoader.active = false
                }
            }

            onActiveChanged: if (active)
                attachmentOptionsFlickable.show = false
        }

        InlineQuery {
            id: inlineQuery
            textField: newMessageTextField
            chatId: chatInformation.id
        }
    }

    NewMessageColumn {
        id: newMessageColumn
        myUserId: chatPage.myUserId
        show: !messagesView.isSelecting && chatPage.canSendMessages
        allowedOrientations: chatPage.allowedOrientations
    }

    Loader {
        id: selectedMessagesActions
        asynchronous: true
        readonly property bool show: messagesView.isSelecting
        active: height > 0
        width: parent.width
        height: show ? Theme.itemSizeMedium : 0
        Behavior on height { SmoothedAnimation { duration: 200 } }
        sourceComponent: Component {
            Item {
                clip: true

                IconButton {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    icon.source: "image://theme/icon-m-cancel"
                    onClicked:
                        messagesView.selectedMessages = []
                }

                Row {
                    spacing: Theme.paddingSmall
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    IconButton {
                        icon.source: "../../images/icon-m-copy.svg"
                        icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        onClicked: {
                            Clipboard.text = Functions.getMessagesArrayText(messagesView.selectedMessages)
                            appNotification.show(qsTr("%Ln messages have been copied", "", selectedMessages.length))
                            messagesView.selectedMessages = []
                        }
                    }

                    IconButton {
                        visible: !chatPage.isSecretChat && selectedMessages.every(function(message) {
                            return message.properties.can_be_forwarded
                        })
                        icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        icon.source: "image://theme/icon-m-forward"
                        onClicked:
                            startForwardingMessages(messagesView.selectedMessages)

                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-delete"
                        visible: chatInformation.id === chatPage.myUserId || selectedMessages.every(function(message) {
                            return message.properties.can_be_deleted_for_all_users
                        })
                        icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        onClicked: {
                            var ids = Functions.getMessagesArrayIds(selectedMessages)
                            var chatId = chatInformation.id
                            var wrapper = tdLibWrapper
                            Remorse.popupAction(chatPage, qsTr("%Ln Messages deleted", "", ids.length), function() {
                                wrapper.deleteMessages(chatId, ids)
                            })
                            messagesView.selectedMessages = []
                        }
                    }
                }
            }
        }
    }
}
