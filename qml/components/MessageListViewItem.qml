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
import QtQuick 2.6
import Sailfish.Silica 1.0
import "./messageContent"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug
import "../modules/Opal/FancyMenus"

ListItem {
    id: messageListItem
    contentHeight: messageBackground.height + Theme.paddingMedium + (reactionsColumn.visible ? reactionsColumn.height : 0)
    Behavior on contentHeight { NumberAnimation { duration: 200 } }
    property var chatId
    property var messageId
    property int messageIndex
    property int messageViewCount
    property var myMessage
    property var messageAlbumMessageIds
    property var reactions
    readonly property bool isAnonymous: myMessage.sender_id["@type"] === "messageSenderChat"
    readonly property var userInformation: tdLibWrapper.getUserInformation(myMessage.sender_id.user_id)
    property QtObject precalculatedValues: ListView.view.precalculatedValues
    readonly property color textColor: isOwnMessage ? Theme.highlightColor : Theme.primaryColor
    readonly property int textAlign: isOwnMessage ? Text.AlignRight : Text.AlignLeft
    readonly property Page page: precalculatedValues.page
    readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting && page.selectedMessages.some(function(existingMessage) {
        return existingMessage.id === messageId
    })
    readonly property bool isOwnMessage: page.myUserId === myMessage.sender_id.user_id
    property bool hasContentComponent
    property bool fullWidthWidescreenContent
    property bool wasNavigatedTo: false

    property var chatReactions
    property var messageReactions

    highlighted: (down || (isSelected && messageAlbumMessageIds.length === 0) || wasNavigatedTo) && !menuOpen
    openMenuOnPressAndHold: !messageListItem.precalculatedValues.pageIsSelecting

    signal replyToMessage()
    signal editMessage()
    signal forwardMessage()

    function deleteMessage() {
        var chatId = page.chatInformation.id
        var messageId = myMessage.id
        Remorse.itemAction(messageListItem, qsTr("Message deleted"), function() {
            tdLibWrapper.deleteMessages(chatId, [ messageId ])
        })
    }

    function copyMessageToClipboard() {
        Clipboard.text = Functions.getMessageText(myMessage, true, userInformation.id, true)
    }

    function translate() {
        pageStack.push(Qt.resolvedUrl("../pages/TranslatePage.qml"), {
                           messageId: messageId,
                           message: myMessage,
                       })
    }

    function togglePinned() {
        if (myMessage.is_pinned)
            Remorse.popupAction(page, qsTr("Message unpinned"), function() {
                tdLibWrapper.unpinMessage(chatId, messageId)
                pinnedMessageItem.requestCloseMessage()
            })
        else tdLibWrapper.pinMessage(chatId, messageId)
    }

    function openContextMenu() {
        if (menu) openMenu()
        else contextMenuLoader.active = true
    }

    function getInteractionText(viewCount, reactions, size, highlightColor) {
        var interactionText = viewCount > 0 ? (Emoji.emojify("👁️ ", size) + Functions.getShortenedCount(viewCount)) : ''
        for (var i = 0; i < reactions.length; i++) {
            var reaction = reactions[i]
            var reactionText = reaction.reaction ? reaction.reaction : (reaction.type && reaction.type.emoji) ? reaction.type.emoji : ""
            if (reactionText) {
                interactionText += ("&nbsp;" + Emoji.emojify(reactionText, size))
                if (!chatPage.isPrivateChat) {
                    var count = Functions.getShortenedCount(reaction.total_count)
                    interactionText += " "
                    interactionText += (reaction.is_chosen ? ("<font color='" + highlightColor + "'><b>" + count + "</b></font>") : count)
                }
            }
        }
        return interactionText
    }

    function openReactions() {
        if (messageListItem.chatReactions) {
            Debug.log("Using chat reactions")
            messageListItem.messageReactions = chatReactions
            showItemCompletelyTimer.requestedIndex = index
            showItemCompletelyTimer.start()
        } else {
            Debug.log("Obtaining message reactions")
            tdLibWrapper.getMessageAvailableReactions(messageListItem.chatId, messageListItem.messageId)
        }
        selectReactionBubble.visible = false
    }

    function getContentWidthMultiplier() {
        return !fullWidthWidescreenContent && Functions.isWidescreen(appWindow) ? 0.4 : 1.0
    }

    onClicked: {
        if (messageListItem.precalculatedValues.pageIsSelecting) {
            page.toggleMessageSelection(myMessage)
        } else {
            // Allow extra context to react to click
            var extraContent = extraContentLoader.item
            if (extraContent && extraContentLoader.contains(mapToItem(extraContentLoader, mouse.x, mouse.y))) {
                extraContent.clicked()
            } else if (webPagePreviewLoader.item) {
                webPagePreviewLoader.item.clicked()
            }

            if (messageListItem.messageReactions) {
                messageListItem.messageReactions = null
                selectReactionBubble.visible = false
            } else {
                selectReactionBubble.visible = !selectReactionBubble.visible
                elementSelected(index)
            }
        }
    }

    onDoubleClicked: openReactions()

    onPressAndHold: {
        if (openMenuOnPressAndHold) {
            openContextMenu()
        } else {
            page.selectedMessages = []
            page.state = ""
        }
    }

    onMenuOpenChanged: {
        // When opening/closing the context menu, we no longer scroll automatically
        chatView.manuallyScrolledToBottom = false
    }

    Connections {
        target: chatPage
        onResetElements: {
            messageListItem.messageReactions = null
            selectReactionBubble.visible = false
        }
        onElementSelected:
            if (elementIndex !== index) {
                selectReactionBubble.visible = false
            }
        onNavigatedTo:
            if (targetIndex === index) {
                messageListItem.wasNavigatedTo = true
                restoreNormalityTimer.start()
            }
    }

    Loader {
        id: contextMenuLoader
        active: false
        asynchronous: true

        MessagePropertiesLoader {
            id: propertiesLoader
            chatId: messageListItem.chatId
            messageId: messageListItem.messageId
            autoLoad: false
        }
        property alias messageProperties: propertiesLoader.properties
        readonly property bool canDeleteMessage: !!messageProperties.can_be_deleted_for_all_users || (!!messageProperties.can_be_deleted_only_for_self && myMessage.chat_id === page.myUserId)

        onStatusChanged: {
            if (status == Loader.Loading || status == Loader.Ready)
                propertiesLoader.load()

            if(status === Loader.Ready) {
                messageListItem.menu = item
                messageListItem.openMenu()
            } else if (status != Loader.Loading)
                propertiesLoader.reset()
        }

        sourceComponent: Component {
            FancyContextMenu {
                listItem: messageListItem
                onActiveChanged: if (active) propertiesLoader.load()
                onClosed: propertiesLoader.reset() // closed is called at end of animation, and active is set to false at the start, so we use closed() for tracking close and active for tracking open
                FancyMenuRow {
                    // NOTE: In places like this we should generally use `enabled` instead of `visible` so people can rely on spatial memory.
                    // NOTE2: When a user selects a message, the finger first goes to the (horizontal) center of the message, so the most used options should be there
                    IconRowMenuItem {
                        icon.source: "image://theme/icon-m-select-all"
                        onClicked: page.toggleMessageSelection(myMessage)
                    }
                    IconRowMenuItem {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: copyMessageToClipboard()
                    }
                    IconRowMenuItem {
                        visible: !!messageProperties.can_be_pinned // FIXME: should we use enabled or visible here? for spatial memory
                        icon.source: "../../images/icon-m-" + (myMessage.is_pinned ? 'un' : '') + "pin.svg"
                        onClicked: togglePinned()
                    }
                    IconRowMenuItem {
                        visible: appSettings.showTranslateOption
                        enabled: !!messageText.text
                        icon.source: "image://theme/icon-m-region"
                        onClicked: translate()
                    }
                }
                FancyMenuRow {
                    checkShort: function (ratio) { return Screen.sizeCategory <= Screen.Large && ratio > 1 }
                    IconTextRowMenuItem {
                        visible: !!messageProperties.can_be_forwarded
                        icon.source: "image://theme/icon-m-message-forward"
                        shortText: qsTr("Forward", 'Short version for "Forward Message"')
                        longText: qsTr("Forward Message")
                        onClicked: forwardMessage()
                    }
                    IconTextRowMenuItem {
                        visible: !!messageProperties.can_be_replied
                        icon.source: "image://theme/icon-m-message-reply"
                        shortText: qsTr("Reply", 'Short version for "Reply to Message"')
                        longText: qsTr("Reply to Message")
                        onClicked: replyToMessage()
                    }
                }
                FancyMenuRow {
                    visible: !appSettings.superCompactMessageMenu
                    checkShort: function (ratio, size) { return Screen.sizeCategory <= Screen.Large && ratio > 1 }
                    IconTextRowMenuItem {
                        visible: canDeleteMessage
                        icon.source: "image://theme/icon-m-delete"
                        shortText: qsTr("Delete", 'Short version for "Delete Message"')
                        longText: qsTr("Delete Message")
                        onClicked: deleteMessage()
                    }
                    IconTextRowMenuItem {
                        visible: !!messageProperties.can_be_edited
                        icon.source: "image://theme/icon-m-edit"
                        shortText: qsTr("Edit", 'Short version for "Edit Message"')
                        longText: qsTr("Edit Message")
                        onClicked: editMessage()
                    }
                }

                Component.onCompleted: {
                    if (!extraContentLoader.item || !extraContentLoader.item.extraContextMenuItems) return
                    for (var i=0; i<extraContentLoader.item.extraContextMenuItems.length; i++) {
                        if (extraContentLoader.item.extraContextMenuItems[i].processProperties)
                            extraContentLoader.item.extraContextMenuItems[i].processProperties(messageProperties)
                        extraContentLoader.item.extraContextMenuItems[i].parent = _contentColumn
                    }
                }
                Component.onDestruction: {
                    if (!extraContentLoader.item || !extraContentLoader.item.extraContextMenuItems) return
                    for (var i=0; i<extraContentLoader.item.extraContextMenuItems.length; i++) {
                        if (extraContentLoader.item.extraContextMenuItems[i].processProperties)
                            extraContentLoader.item.extraContextMenuItems[i].processProperties({})
                        extraContentLoader.item.extraContextMenuItems[i].parent = null
                    }
                }
            }
        }
    }

    // Just in case we will need them back
    property bool __otherTranslations: qsTr("Copy Message to Clipboard") + qsTr("Select Message") + qsTr("More Options...") + qsTr("Unpin Message") + qsTr("Pin Message")

    function updateIsUnread() {
        messageBackground.isUnread = Qt.binding(function() { return messageIndex > chatModel.getLastReadMessageIndex() && myMessage['@type'] !== "sponsoredMessage" })
    }
    Connections {
        target: chatModel
        onMessagesReceived: updateIsUnread()
        onMessagesIncrementalUpdate: updateIsUnread()
        onNewMessageReceived: updateIsUnread()
        onUnreadCountUpdated: updateIsUnread()
        onLastReadSentMessageUpdated: {
            Debug.log("[ChatModel] Messages in this chat were read, new last read: ", lastReadSentIndex, ", updating description for index ", index, ", status: ", (messageIndex <= lastReadSentIndex))
            messageDateText.text = getMessageStatusText(myMessage, messageIndex, lastReadSentIndex, messageDateText.useElapsed)
        }
    }

    Connections {
        target: tdLibWrapper
        onReceivedMessage:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessage = message
        onMessageNotFound:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessageDeleted = true
        onAvailableReactionsReceived: {
            if (messageListItem.messageId === messageId && pageStack.currentPage === chatPage) {
                Debug.log("Available reactions for this message: " + reactions)
                messageListItem.messageReactions = reactions
                showItemCompletelyTimer.requestedIndex = messageIndex
                showItemCompletelyTimer.start()
            } else messageListItem.messageReactions = null
        }
        onReactionsUpdated:
            chatReactions = tdLibWrapper.getChatReactions(page.chatInformation.id)
    }

    Timer {
        id: showItemCompletelyTimer

        property int requestedIndex: (chatView.count - 1)

        repeat: false
        running: false
        interval: 200
        triggeredOnStart: false
        onTriggered: {
            if (requestedIndex === messageIndex) {
                chatView.highlightMoveDuration = -1
                chatView.highlightResizeDuration = -1
                chatView.scrollToIndex(requestedIndex)
                chatView.highlightMoveDuration = 0
                chatView.highlightResizeDuration = 0
            }
            Debug.log("Show item completely timer triggered, requested index: " + requestedIndex + ", current index: " + index)
            if (requestedIndex === index) {
                var p = chatView.contentItem.mapFromItem(reactionsColumn, 0, 0)
                if (chatView.contentY > p.y || p.y + reactionsColumn.height > chatView.contentY + chatView.height) {
                    Debug.log("Moving reactions for item at", requestedIndex, "info the view")
                    chatView.highlightMoveDuration = -1
                    chatView.highlightResizeDuration = -1
                    chatView.scrollToIndex(requestedIndex, height <= chatView.height ? ListView.Contain : ListView.End)
                    chatView.highlightMoveDuration = 0
                    chatView.highlightResizeDuration = 0
                }
            }
        }
    }

    Timer {
        id: restoreNormalityTimer

        repeat: false
        running: false
        interval: 1000
        triggeredOnStart: false
        onTriggered: {
            Debug.log("Restore normality for index " + index)
            messageListItem.wasNavigatedTo = false
        }
    }

    Component.onCompleted: {
        delegateComponentLoadingTimer.start()
        if (myMessage.reply_to_message_id)
            tdLibWrapper.getMessage(myMessage.reply_in_chat_id ? myMessage.reply_in_chat_id : page.chatInformation.id,
                myMessage.reply_to_message_id)
    }

    onMyMessageChanged: {
        Debug.log("[ChatModel] This message was updated, index", messageIndex, ", updating content...")
        messageDateText.text = getMessageStatusText(myMessage, messageIndex, chatView.lastReadSentIndex, messageDateText.useElapsed)
        Emoji.emojify(Functions.getMessageText(myMessage, false, page.myUserId, false, Theme.fontSizeSmall), Theme.fontSizeSmall)
        if (webPagePreviewLoader.item)
            webPagePreviewLoader.item.linkPreviewData = myMessage.content.link_preview
    }

    Timer {
        id: delegateComponentLoadingTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            if (messageListItem.hasContentComponent) {
                var type = myMessage.content["@type"]
                var albumComponentPart = (myMessage.media_album_id !== "0" && chatView.albumMessages.indexOf(type) !== -1) ? 'Album' : ''
                extraContentLoader.setSource(
                            "../components/messageContent/" + type.charAt(0).toUpperCase() + type.substring(1) + albumComponentPart + ".qml",
                            {messageListItem: messageListItem})
            } else
                if (typeof myMessage.content.link_preview !== "undefined") // only in messageText
                    webPagePreviewLoader.active = true
        }
    }

    Row {
        id: messageTextRow
        spacing: Theme.paddingSmall
        width: precalculatedValues.entryWidth
        anchors.horizontalCenter: Functions.isWidescreen(appWindow) ? undefined : parent.horizontalCenter
        anchors.left: Functions.isWidescreen(appWindow) ? parent.left : undefined
        y: Theme.paddingSmall
        anchors.leftMargin: Functions.isWidescreen(appWindow) ? Theme.paddingMedium : undefined

        Loader {
            id: profileThumbnailLoader
            active: precalculatedValues.showUserInfo
            asynchronous: true
            width: precalculatedValues.profileThumbnailDimensions
            height: width
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            sourceComponent: Component {
                ProfileThumbnail {
                    id: messagePictureThumbnail
                    photoData: messageListItem.isAnonymous ? ((typeof page.chatInformation.photo !== "undefined") ? page.chatInformation.photo.small : {}) : ((typeof messageListItem.userInformation.profile_photo !== "undefined") ? messageListItem.userInformation.profile_photo.small : ({}))
                    replacementStringHint: userText.text
                    width: Theme.itemSizeSmall
                    height: Theme.itemSizeSmall
                    visible: precalculatedValues.showUserInfo
                    MouseArea {
                        anchors.fill: parent
                        enabled: !(messageListItem.precalculatedValues.pageIsSelecting || messageListItem.isAnonymous)
                        onClicked:
                            tdLibWrapper.createPrivateChat(messageListItem.userInformation.id, "openDirectly")
                    }
                }
            }
        }

        Item {
            id: messageTextItem

            width: precalculatedValues.textItemWidth
            height: messageBackground.height

            Rectangle {
                id: messageBackground

                anchors {
                    left: parent.left
                    leftMargin: messageListItem.isOwnMessage ? precalculatedValues.pageMarginDouble : 0
                    verticalCenter: parent.verticalCenter
                }
                height: messageTextColumn.height + precalculatedValues.paddingMediumDouble
                width: precalculatedValues.backgroundWidth
                property bool isUnread: messageIndex > chatModel.getLastReadMessageIndex() && myMessage['@type'] !== "sponsoredMessage"
                color: isUnread ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
                radius: parent.width / 50
                visible: appSettings.showStickersAsImages || (myMessage.content['@type'] !== "messageSticker" && myMessage.content['@type'] !== "messageAnimatedEmoji")
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on opacity { FadeAnimation {} }
            }

            Column {
                id: messageTextColumn
                width: precalculatedValues.textColumnWidth
                anchors.centerIn: messageBackground
                spacing: Theme.paddingSmall

                Label {
                    id: userText

                    width: parent.width
                    text: messageListItem.isOwnMessage
                          ? qsTr("You")
                          : Emoji.emojify(myMessage['@type'] === "sponsoredMessage"
                                          ? myMessage.title
                                          : (messageListItem.isAnonymous
                                                ? page.chatInformation.title
                                                : Functions.getUserName(messageListItem.userInformation)), font.pixelSize)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.weight: Font.ExtraBold
                    color: messageListItem.textColor
                    maximumLineCount: 1
                    truncationMode: TruncationMode.Fade
                    textFormat: Text.StyledText
                    horizontalAlignment: messageListItem.textAlign
                    visible: precalculatedValues.showUserInfo || myMessage['@type'] === "sponsoredMessage"
                    MouseArea {
                        anchors.fill: parent
                        enabled: !(messageListItem.precalculatedValues.pageIsSelecting || messageListItem.isAnonymous)
                        onClicked:
                            tdLibWrapper.createPrivateChat(messageListItem.userInformation.id, "openDirectly")
                    }
                }

                MessageViaLabel {
                    message: myMessage
                }

                Loader {
                    id: messageInReplyToLoader
                    active: typeof myMessage.reply_to_message_id !== "undefined" && myMessage.reply_to_message_id !== 0
                    width: parent.width
                    // text height ~= 1,28*font.pixelSize
                    height: active ? precalculatedValues.messageInReplyToHeight : 0
                    property var inReplyToMessage
                    property bool inReplyToMessageDeleted: false
                    sourceComponent: Component {
                        Item {
                            width: messageInReplyToRow.width
                            height: messageInReplyToRow.height
                            InReplyToRow {
                                id: messageInReplyToRow
                                myUserId: page.myUserId
                                layer.enabled: messageInReplyToMouseArea.pressed && !messageListItem.highlighted && !messageListItem.menuOpen
                                layer.effect: PressEffect { source: messageInReplyToRow }
                                inReplyToMessage: messageInReplyToLoader.inReplyToMessage
                                inReplyToMessageDeleted: messageInReplyToLoader.inReplyToMessageDeleted
                            }
                            MouseArea {
                                id: messageInReplyToMouseArea
                                anchors.fill: parent
                                onClicked: {
                                    if (precalculatedValues.pageIsSelecting) {
                                        page.toggleMessageSelection(myMessage)
                                    } else {
                                        if(appSettings.goToQuotedMessage) {
                                            chatPage.showMessage(messageInReplyToRow.inReplyToMessage.id, true)
                                        } else {
                                            messageOverlayLoader.active = true
                                            messageOverlayLoader.overlayMessage = messageInReplyToRow.inReplyToMessage
                                        }
                                    }
                                }
                                onPressAndHold:
                                    if (openMenuOnPressAndHold) openContextMenu()
                            }
                        }
                    }
                }

                Loader {
                    id: forwardedInformationLoader
                    active: typeof myMessage.forward_info !== "undefined"
                    asynchronous: true
                    width: parent.width
                    height: active ? (item ? item.height : Theme.itemSizeExtraSmall) : 0
                    sourceComponent: Component {
                        Row {
                            id: forwardedMessageInformationRow
                            spacing: Theme.paddingSmall
                            width: parent.width

                            Component.onCompleted: {
                                var originType = myMessage.forward_info.origin["@type"]
                                if (originType === "messageOriginChannel" || originType === "messageForwardOriginChannel") {
                                    var otherChatInformation = tdLibWrapper.getChat(myMessage.forward_info.origin.chat_id)
                                    forwardedThumbnail.photoData = (typeof otherChatInformation.photo !== "undefined") ? otherChatInformation.photo.small : {}
                                    forwardedChannelText.text = Emoji.emojify(otherChatInformation.title, Theme.fontSizeExtraSmall)
                                } else if (originType === "messageOriginUser" || originType === "messageForwardOriginUser") {
                                    var otherUserInformation = tdLibWrapper.getUserInformation(myMessage.forward_info.origin.sender_user_id)
                                    forwardedThumbnail.photoData = (typeof otherUserInformation.profile_photo !== "undefined") ? otherUserInformation.profile_photo.small : {}
                                    forwardedChannelText.text = Emoji.emojify(Functions.getUserName(otherUserInformation), Theme.fontSizeExtraSmall)
                                } else {
                                    forwardedChannelText.text = Emoji.emojify(myMessage.forward_info.origin.sender_name, Theme.fontSizeExtraSmall)
                                    forwardedThumbnail.photoData = {}
                                }
                            }

                            ProfileThumbnail {
                                id: forwardedThumbnail
                                replacementStringHint: forwardedChannelText.text
                                width: Theme.itemSizeExtraSmall
                                height: Theme.itemSizeExtraSmall
                            }

                            Column {
                                spacing: Theme.paddingSmall
                                width: parent.width - forwardedThumbnail.width - Theme.paddingSmall
                                Label {
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    width: parent.width
                                    font.italic: true
                                    truncationMode: TruncationMode.Fade
                                    textFormat: Text.StyledText
                                    text: qsTr("Forwarded Message")
                                }
                                Label {
                                    id: forwardedChannelText
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.primaryColor
                                    width: parent.width
                                    font.bold: true
                                    truncationMode: TruncationMode.Fade
                                    textFormat: Text.StyledText
                                    text: Emoji.emojify(forwardedMessageInformationRow.otherChatInformation.title, font.pixelSize)
                                }
                            }
                        }
                    }
                }

                Text {
                    id: messageText
                    width: parent.width
                    text: Emoji.emojify(Functions.getMessageText(myMessage, false, page.myUserId, false, Theme.fontSizeSmall), Theme.fontSizeSmall)
                    font.pixelSize: Theme.fontSizeSmall
                    color: messageListItem.textColor
                    wrapMode: Text.Wrap
                    textFormat: Text.StyledText
                    onLinkActivated: {
                        var chatCommand = Functions.handleLink(link)
                        if(chatCommand) tdLibWrapper.sendTextMessage(chatInformation.id, chatCommand)
                    }
                    horizontalAlignment: messageListItem.textAlign
                    linkColor: Theme.highlightColor
                    visible: !!text
                }

                Loader {
                    id: webPagePreviewLoader
                    active: false
                    asynchronous: true
                    width: parent.width * getContentWidthMultiplier()
                    height: (status === Loader.Ready) ? item.implicitHeight : myMessage.content.link_preview ? precalculatedValues.webPagePreviewHeight : 0

                    sourceComponent: Component {
                        WebPagePreview {
                            linkPreviewData: myMessage.content.link_preview
                            width: parent.width
                            highlighted: messageListItem.highlighted
                        }
                    }
                }

                Loader {
                    id: extraContentLoader
                    width: parent.width * getContentWidthMultiplier()
                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    readonly property var defaultExtraContentHeight: messageListItem.hasContentComponent ? chatView.getContentComponentHeight(model.content_type, myMessage.content, width, model.album_message_ids.length) : 0
                    height: item ? item.height : defaultExtraContentHeight
                }

                Binding {
                    target: extraContentLoader.item
                    when: extraContentLoader.item && ("highlighted" in extraContentLoader.item) && (typeof extraContentLoader.item.highlighted === "boolean")
                    property: "highlighted"
                    value: messageListItem.highlighted
                }

                Loader {
                    id: replyMarkupLoader
                    width: parent.width
                    height: active ? (myMessage.reply_markup.rows.length * (Theme.itemSizeSmall + Theme.paddingSmall) - Theme.paddingSmall) : 0
                    asynchronous: true
                    active: !!myMessage.reply_markup && myMessage.reply_markup.rows
                    source: Qt.resolvedUrl("ReplyMarkupButtons.qml")
                }

                Loader {
                    id: sponsoredMessageButtonLoader
                    active: myMessage['@type'] === "sponsoredMessage"
                    asynchronous: true
                    width: parent.width
                    height: (status === Loader.Ready) ? item.implicitHeight : myMessage['@type'] === "sponsoredMessage" ? Theme.itemSizeMedium : 0

                    sourceComponent: Component {
                        SponsoredMessage {
                            message: myMessage
                            width: parent.width
                        }
                    }
                }

                Timer {
                    id: messageDateUpdater
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered:
                        messageDateText.text = getMessageStatusText(myMessage, messageIndex, chatView.lastReadSentIndex, messageDateText.useElapsed)
                }

                Text {
                    width: parent.width

                    property bool useElapsed: true

                    id: messageDateText
                    font.pixelSize: Theme.fontSizeTiny
                    color: messageListItem.isOwnMessage ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    horizontalAlignment: messageListItem.textAlign
                    text: getMessageStatusText(myMessage, messageIndex, chatView.lastReadSentIndex, messageDateText.useElapsed)
                    MouseArea {
                        anchors.fill: parent
                        enabled: !messageListItem.precalculatedValues.pageIsSelecting
                        onClicked: {
                            messageDateText.useElapsed = !messageDateText.useElapsed
                            messageDateText.text = getMessageStatusText(myMessage, messageIndex, chatView.lastReadSentIndex, messageDateText.useElapsed)
                        }
                    }
                }

                Loader {
                    id: interactionLoader
                    width: parent.width
                    asynchronous: true
                    active: (chatPage.isChannel && messageViewCount > 0) || reactions.length > 0
                    height: active ? (Theme.fontSizeExtraSmall + Theme.paddingSmall) : 0
                    sourceComponent: Component {
                        Label {
                            text: getInteractionText(messageViewCount, reactions, font.pixelSize, Theme.highlightColor)
                            width: parent.width
                            font.pixelSize: Theme.fontSizeTiny
                            color: messageListItem.isOwnMessage ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            horizontalAlignment: messageListItem.textAlign
                            textFormat: Text.StyledText
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (messageListItem.messageReactions) {
                                        messageListItem.messageReactions = null
                                        selectReactionBubble.visible = false
                                    } else openReactions()
                                }
                            }
                        }
                    }
                }

            }

            Rectangle {
                id: selectReactionBubble
                visible: false
                opacity: visible ? 0.5 : 0.0
                Behavior on opacity { NumberAnimation {} }
                anchors {
                    horizontalCenter: messageListItem.isOwnMessage ? messageBackground.left : messageBackground.right
                    verticalCenter: messageBackground.verticalCenter
                }
                height: Theme.itemSizeExtraSmall
                width: Theme.itemSizeExtraSmall
                color: Theme.primaryColor
                radius: parent.width / 2
            }

            IconButton {
                id: selectReactionButton
                visible: selectReactionBubble.visible
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation {} }
                icon.source: "image://theme/icon-s-favorite"
                anchors.centerIn: selectReactionBubble
                onClicked: openReactions()
            }
        }
    }

    Column {
        id: reactionsColumn
        width: parent.width - ( 2 * Theme.horizontalPageMargin )
        anchors.top: messageTextRow.bottom
        anchors.topMargin: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        visible: messageListItem.messageReactions ? (messageListItem.messageReactions.length > 0 ? true : false) : false
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation {} }
        spacing: Theme.paddingMedium

        Flickable {
            width: parent.width
            height: reactionsResultRow.height + 2 * Theme.paddingMedium
            anchors.horizontalCenter: parent.horizontalCenter
            contentWidth: reactionsResultRow.width
            clip: true
            Row {
                id: reactionsResultRow
                spacing: Theme.paddingMedium
                Repeater {
                    model: messageListItem.messageReactions

                    Item {
                        height: singleReactionRow.height
                        width: singleReactionRow.width

                        Row {
                            id: singleReactionRow
                            spacing: Theme.paddingMedium

                            Image {
                                id: emojiPicture
                                source: Emoji.getEmojiPath(modelData)
                                width: status === Image.Ready ? Theme.fontSizeExtraLarge : 0
                                height: Theme.fontSizeExtraLarge
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                for (var i = 0; i < reactions.length; i++) {
                                    var reaction = reactions[i]
                                    var reactionText = reaction.reaction ? reaction.reaction : (reaction.type && reaction.type.emoji) ? reaction.type.emoji : ""
                                    if (reactionText === modelData) {
                                        if (reaction.is_chosen) {
                                            // Reaction is already selected
                                            tdLibWrapper.removeMessageReaction(chatId, messageId, reactionText)
                                            messageReactions = null
                                            return
                                        }
                                        break
                                    }
                                }
                                // Reaction is not yet selected
                                tdLibWrapper.addMessageReaction(chatId, messageId, modelData)
                                messageReactions = null
                                selectReactionBubble.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
