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
import io.yaqtlib 1.0
import ".."
import "../messageContent"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug
import "../../modules/Opal/FancyMenus"

ListItem {
    id: messageListItem
    contentHeight: messageBackground.height + messageTextRow.y + Theme.paddingSmall/2
    Behavior on contentHeight { NumberAnimation { duration: 200 } }
    property var chatId
    property var messageId
    property int messageIndex
    property int messageViewCount
    property var myMessage
    property var messageAlbumMessageIds
    property var messageAlbumMessages
    property var reactions
    property QtObject precalculatedValues: ListView.view.precalculatedValues
    readonly property color textColor: isOutgoing ? Theme.highlightColor : Theme.primaryColor
    readonly property int textAlign: isOutgoing ? Text.AlignRight : Text.AlignLeft
    readonly property Page page: precalculatedValues.page
    readonly property Item view: precalculatedValues.view
    readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting
                                       && view.selectedMessages.some(function(existingMessage) { return existingMessage.id === messageId })
                                       && (messageAlbumMessageIds.length === 0 || messageAlbumMessageIds.every(function(id) {
                                           return view.selectedMessages.some(function(m) { return m.id == id })
                                       }))
    property bool isSponsored: myMessage['@type'] === 'sponsoredMessage'
    property bool generatedContentUnread
    readonly property bool isUnread: !isOutgoing && !isSponsored && messageId > messagesModel.lastReadInboxMessageId
    readonly property bool isAlbum: myMessage.media_album_id && myMessage.media_album_id !== '0'

    readonly property bool isOwnMessage: tdLibWrapper.myUserId === myMessage.sender_id.user_id
    readonly property bool isOutgoing: myMessage.is_outgoing && !myMessage.is_channel_post
    readonly property bool isOutgoingRead: isOutgoing && messageId <= messagesModel.lastReadOutboxMessageId
    property bool hasContentComponent
    property bool fullWidthWidescreenContent
    property bool contentAboveMedia
    property bool isFirstInSequence: true
    property bool isLastInSequence: true
    property bool wasNavigatedTo: false

    // Highlighting is provided by the rounded rectangle :D (except for navigation)
    highlighted: wasNavigatedTo
    contentItem.color: highlighted ? highlightedColor : 'transparent' // by default it's binded to _showPress, which is also true when pressTimer is running, which doesn't suit us
    openMenuOnPressAndHold: !messageListItem.precalculatedValues.pageIsSelecting

    signal replyToMessage()
    signal editMessage()
    signal forwardMessage()

    function deleteMessage(revoke) {
        var chatId = page.chatInformation.id
        var messageId = myMessage.id
        Remorse.itemAction(messageListItem, (revoke || isSavedMessages) ? qsTr("Message deleted") : qsTr("Message deleted only for yourself"), function() {
            tdLibWrapper.deleteMessages(chatId, [messageId], revoke)
        })
    }

    function copyMessageToClipboard() {
        Clipboard.text = utilities.getMessageText(myMessage, Utilities.MessageTextSimple, true)
    }

    function translate() {
        pageStack.push(Qt.resolvedUrl("../../pages/TranslatePage.qml"), {
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
        if (menu && menu.isMessageListViewItemMainContextMenu)
            openMenu()
        else {
            contextMenuLoader.sourceComponent = mainContextMenuComponent
            contextMenuLoader.active = true
        }
    }

    function getContentWidthMultiplier() {
        return !fullWidthWidescreenContent && Functions.isWidescreen(appWindow) ? 0.4 : 1.0
    }

    onClicked: {
        if (messageListItem.precalculatedValues.pageIsSelecting) {
            view.toggleMessageSelection(myMessage, messageAlbumMessageIds)
        } else {
            // Allow extra context to react to click
            var extraContent = extraContentLoader.item
            if (extraContent && extraContentLoader.contains(mapToItem(extraContentLoader, mouse.x, mouse.y))) {
                extraContent.clicked()
            } else if (webPagePreviewLoader.item) {
                webPagePreviewLoader.item.clicked()
            }

            elementSelected(index)
        }
    }

    onPressAndHold:
        if (openMenuOnPressAndHold)
            openContextMenu()
        else {
            view.selectedMessages = []
            view.state = ""
        }

    onMenuOpenChanged:
        // When opening/closing the context menu, we no longer scroll automatically
        chatView.manuallyScrolledToBottom = false

    Connections {
        target: view
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

            onLoadedChanged:
                if (loaded) {
                    if (properties.can_get_read_date && isOutgoingRead)
                        tdLibWrapper.getMessageReadDate(chatId, messageId)
                }
        }
        property alias messageProperties: propertiesLoader.properties
        readonly property bool canDeleteMessage: !!(messageProperties.can_be_deleted_for_all_users || messageProperties.can_be_deleted_only_for_self)

        property int messageReadDate

        property int reactionsRowSize: Math.floor(width / Theme.itemSizeSmall)
        property var messageReactions
        property bool reactionsLoading

        function getAvailableReactions() {
            if (reactionsLoading) return

            Debug.log("Obtaining message reactions, row size:", reactionsRowSize)
            reactionsLoading = true
            tdLibWrapper.getMessageAvailableReactions(chatId, messageId, reactionsRowSize)
        }
        onReactionsRowSizeChanged: // width changed
            if (status == Loader.Loading || status == Loader.Ready)
                getAvailableReactions()

        function loadData() {
            propertiesLoader.load()
            getAvailableReactions()
        }
        function reset() {
            propertiesLoader.reset()
            contextMenuLoader.messageReactions = null
            contextMenuLoader.reactionsLoading = false
            contextMenuLoader.messageReadDate = 0
        }

        onStatusChanged: {
            if (status == Loader.Loading || status == Loader.Ready)
                loadData()

            if (status === Loader.Ready) {
                messageListItem.menu = item
                messageListItem.openMenu()
            } else if (status != Loader.Loading)
                reset()
        }

        sourceComponent: mainContextMenuComponent

        function toggleReaction(type) {
            if (type['@type'] === 'reactionTypePaid') {
                // TODO
                return
            }

            for (var i = 0; i < reactions.length; i++) {
                var reaction = reactions[i]
                if (JSON.stringify(reaction.type) === JSON.stringify(type)) {
                    if (reaction.is_chosen) {
                        // Reaction is already selected
                        tdLibWrapper.removeMessageReaction(chatId, messageId, reaction.type)
                        return
                    }
                    break
                }
            }
            // Reaction is not yet selected
            tdLibWrapper.addMessageReaction(chatId, messageId, type, true)
        }

        Component {
            id: reactionMenuItemComponent
            BaseRowMenuItem {
                id: reactionMenuItem
                visible: reactionLoader.supported
                //highlight: false

                MessageReaction {
                    id: reactionLoader
                    anchors.centerIn: parent
                    type: modelData.type
                    highlighted: reactionMenuItem.down
                }

                onClicked: contextMenuLoader.toggleReaction(modelData.type)
            }
        }

        Component {
            id: mainContextMenuComponent
            FancyContextMenu {
                id: mainContextMenu
                listItem: messageListItem

                readonly property bool isMessageListViewItemMainContextMenu: true

                onActiveChanged:
                    if (active) contextMenuLoader.loadData()
                onClosed: // closed is called at end of animation, and active is set to false at the start
                    contextMenuLoader.reset()

                MenuItemLoader {
                    sourceComponent: Component {
                        FancyMenuRow {
                            visible: messageReactions && messageReactions.top_reactions && messageReactions.top_reactions.length

                            Repeater {
                                model: messageReactions.top_reactions.slice(0, reactionsRowSize - moreReactionsMenuItem.visible)
                                delegate: reactionMenuItemComponent
                            }

                            IconRowMenuItem {
                                id: moreReactionsMenuItem
                                visible: messageReactions && messageReactions.top_reactions && reactionsRowSize < messageReactions.top_reactions.length
                                icon.source: "image://theme/icon-m-down"
                                onClicked:
                                    contextMenuLoader.sourceComponent = reactionsContextMenuComponent
                            }
                        }
                    }
                }

                FancyMenuRow {
                    // NOTE: In places like this we should generally use `enabled` instead of `visible` so people can rely on spatial memory.
                    // NOTE2: When a user selects a message, the finger first goes to the (horizontal) center of the message, so the most used options should be there
                    IconRowMenuItem {
                        icon.source: "image://theme/icon-m-select-all"
                        onClicked: view.toggleMessageSelection(myMessage, messageAlbumMessageIds)
                    }
                    IconRowMenuItem {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: copyMessageToClipboard()
                    }
                    IconRowMenuItem {
                        visible: !!messageProperties.can_be_pinned // FIXME: should we use enabled or visible here? for spatial memory
                        icon.source: "../../../images/icon-m-" + (myMessage.is_pinned ? 'un' : '') + "pin.svg"
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
                    visible: !yaqtSettings.superCompactMessageMenu
                    checkShort: function (ratio, size) { return Screen.sizeCategory <= Screen.Large && ratio > 1 }
                    IconTextRowMenuItem {
                        visible: canDeleteMessage
                        icon.source: "image://theme/icon-m-delete"
                        shortText: qsTr("Delete", 'Short version for "Delete Message"')
                        longText: qsTr("Delete Message")
                        onClicked: {
                            if (messageProperties.can_be_deleted_only_for_self && messageProperties.can_be_deleted_for_all_users)
                                contextMenuLoader.sourceComponent = deleteContextMenuComponent
                            else
                                deleteMessage(!!messageProperties.can_be_deleted_for_all_users)
                        }
                    }
                    IconTextRowMenuItem {
                        visible: !!messageProperties.can_be_edited
                        icon.source: "image://theme/icon-m-edit"
                        shortText: qsTr("Edit", 'Short version for "Edit Message"')
                        longText: qsTr("Edit Message")
                        onClicked: editMessage()
                    }
                }

                MenuLabel {
                    visible: !!messageProperties.can_get_read_date && isOutgoingRead && messageReadDate >= 0
                    text: messageReadDate
                          ? qsTr("Read %1", "Message read date").arg(Functions.getDateTimeTimepointRelative(messageReadDate))
                          : qsTr("Loading", "Indicates that the message read date is being loaded")
                }

                MenuLabel {
                    visible: !!myMessage.edit_date
                    text: qsTr("Edited %1", "Message edit date").arg(Functions.getDateTimeTimepointRelative(myMessage.edit_date))
                }

                FancyMenuItem {
                    text: "Copy debug info"
                    icon.source: "image://theme/icon-m-diagnostic"
                    visible: DebugLog.enabled
                    onClicked: Clipboard.text =
                               "Message ID: " + messageId
                               + "\nMessage object:\n" + JSON.stringify(myMessage, null, 2)
                               + "\n\n\nMessage properties:\n" + JSON.stringify(messageProperties, null, 2)
                }


                function handleExtraContextMenuItems(properties, parent) {
                    if (!extraContentLoader.item || !extraContentLoader.item.extraContextMenuItems) return
                    for (var i=0; i<extraContentLoader.item.extraContextMenuItems.length; i++) {
                        var item = extraContentLoader.item.extraContextMenuItems[i]
                        if (item.processProperties)
                            item.processProperties(properties)
                        item.parent = parent
                    }
                }

                Component.onCompleted: handleExtraContextMenuItems(messageProperties, _contentColumn)
                Component.onDestruction: handleExtraContextMenuItems({}, null)
            }
        }

        Component {
            id: reactionsContextMenuComponent

            ContextMenu {
                // HACK: disable animation when opening the menu
                height: _contentHeight
                on_DisplayHeightChanged:
                    if (_contentHeight == _displayHeight)
                        height = Qt.binding(function() { return _displayHeight })

                SilicaFlickable {
                    id: reactionsFlickable
                    width: parent.width
                    height: Theme.itemSizeLarge*3
                    contentHeight: reactionsGrid.height

                    Grid {
                        id: reactionsGrid
                        width: parent.width
                        columns: reactionsRowSize

                        Repeater {
                            model: messageReactions.top_reactions
                            delegate: BackgroundItem {
                                visible: reactionLoader.supported
                                width: parent.width / parent.columns
                                height: Theme.itemSizeSmall

                                MessageReaction {
                                    id: reactionLoader
                                    anchors.centerIn: parent
                                    type: modelData.type
                                    highlighted: down
                                }

                                onClicked: {
                                    contextMenuLoader.toggleReaction(modelData.type)
                                    close()
                                }
                            }
                        }

                        VerticalScrollDecorator { flickable: reactionsFlickable }
                    }
                }
            }
        }

        Component {
            id: deleteContextMenuComponent
            ContextMenu {
                MenuItem {
                    text: (isPrivateChat || isSecretChat) ? qsTr("Delete for me and %1").arg(getChatTitle(font.pixelSize)) : qsTr("Delete for everyone")
                    onClicked: deleteMessage(true)
                }
                MenuItem {
                    text: qsTr("Delete just for me")
                    onClicked: deleteMessage(false)
                }
            }
        }
    }

    TDLibMessageSender {
        id: messageSenderInfo
        messageSender: isOwnMessage ? undefined : myMessage.sender_id
    }

    // Just in case we will need them back
    property bool __otherTranslations: qsTr("Copy Message to Clipboard") + qsTr("Select Message") + qsTr("More Options...") + qsTr("Unpin Message") + qsTr("Pin Message")

    Connections {
        target: tdLibWrapper
        onReceivedMessage:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessage = message
        onMessageNotFound:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessageDeleted = true
        onAvailableReactionsReceived:
            if (messageListItem.chatId === chatId && messageListItem.messageId === messageId) {
                Debug.log("Message reactions received")
                contextMenuLoader.reactionsLoading = false
                if (unavailabilityReason !== TDLibAPI.None) {
                    Debug.log("Reactions are unavailable", unavailabilityReason)
                    contextMenuLoader.messageReactions = null
                    return
                }

                contextMenuLoader.messageReactions = reactions
            }
        onMessageReadDateReceived:
            if (messageListItem.chatId === chatId && messageListItem.messageId === messageId) {
                Debug.log("Message read date received")
                contextMenuLoader.messageReadDate = typeof readDate == 'number' ? readDate : -1
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
                var albumComponentPart = (isAlbum && chatView.albumMessages.indexOf(type) !== -1) ? 'Album' : ''
                extraContentLoader.setSource(
                            "../messageContent/" + type.charAt(0).toUpperCase() + type.substring(1) + albumComponentPart + ".qml",
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
        y: isFirstInSequence ? Theme.paddingMedium : Theme.paddingSmall/2
        anchors {
            horizontalCenter: Functions.isWidescreen(appWindow) ? undefined : parent.horizontalCenter
            left: Functions.isWidescreen(appWindow) ? parent.left : undefined
            leftMargin: Functions.isWidescreen(appWindow) ? Theme.paddingMedium : undefined
        }

        Loader {
            id: profileThumbnailLoader
            active: precalculatedValues.showUserInfo && !isOutgoing && isLastInSequence
            asynchronous: true
            width: precalculatedValues.profileThumbnailDimensions
            height: width
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            sourceComponent: Component {
                ProfileThumbnail {
                    anchors.fill: parent
                    photoData: messageSenderInfo.smallPhoto
                    replacementStringHint: messageSenderText.text
                    highlighted: profileThumbnailMouseArea.containsPress
                    MouseArea {
                        id: profileThumbnailMouseArea
                        anchors.fill: parent
                        enabled: !messageListItem.precalculatedValues.pageIsSelecting
                        onClicked: messageSenderInfo.open()
                    }
                }
            }
        }

        Item {
            id: messageTextItem

            width: precalculatedValues.textItemWidth
            height: messageBackground.height

            RoundedRect {
                id: messageBackground
                height: messageTextColumn.height + precalculatedValues.paddingMediumDouble
                width: precalculatedValues.backgroundWidth
                anchors {
                    left: parent.left
                    leftMargin: isOutgoing ? precalculatedValues.pageMarginDouble : 0
                    verticalCenter: parent.verticalCenter
                }

                readonly property color highlightColor: Theme.rgba(Theme.highlightBackgroundColor, Theme.opacityFaint * (isOutgoing ? 0.7 : 1.0))
                color: (messageListItem.highlighted || down || isSelected) && !menuOpen
                       ? highlightColor
                       : Theme.rgba(Theme.secondaryColor, Theme.opacityFaint * (isOutgoing ? 0.4 : 0.8))
                layer.enabled: messageListItem.highlighted // make corners highlighted too

                roundedCorners: isOutgoing ? bottomLeft | topRight : bottomRight | topLeft
                radius: Theme.paddingLarge
                visible: appSettings.showStickersAsImages || (myMessage.content['@type'] !== "messageSticker" && myMessage.content['@type'] !== "messageAnimatedEmoji" && myMessage.content['@type'] !== "messageDice")

                // Only animate color for isUnread
                states: State {
                    name: 'highlighted'
                    when: isUnread
                    PropertyChanges { target: messageBackground; color: highlightColor }
                }
                transitions: Transition {
                    ColorAnimation { duration: 200 }
                }
            }

            Column {
                id: messageTextColumn
                width: precalculatedValues.textColumnWidth
                anchors.centerIn: messageBackground
                spacing: Theme.paddingSmall

                Label {
                    id: messageSenderText

                    width: parent.width
                    text: Emoji.emojify(isSponsored ? myMessage.title : messageSenderInfo.title, font.pixelSize)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.weight: Font.ExtraBold
                    highlighted: messageSenderMouseArea.containsPress
                    color: highlighted ? Theme.highlightColor : messageListItem.textColor
                    maximumLineCount: 1
                    truncationMode: TruncationMode.Fade
                    textFormat: Text.StyledText
                    horizontalAlignment: messageListItem.textAlign
                    visible: (precalculatedValues.showUserInfo && !isOwnMessage && isFirstInSequence) || isSponsored

                    MouseArea {
                        id: messageSenderMouseArea
                        anchors.fill: parent
                        enabled: !messageListItem.precalculatedValues.pageIsSelecting
                        onClicked: messageSenderInfo.open()
                    }
                }

                MessageViaLabel {
                    message: myMessage
                }

                Loader {
                    width: parent.width
                    active: !!myMessage.guest_bot_caller_id
                    sourceComponent: Component {
                        Label {
                            TDLibMessageSender {
                                id: guestBotCaller
                                messageSender: myMessage.guest_bot_caller_id
                            }

                            width: parent.width
                            text: qsTr("for %1", "guest bot caller").arg('<a style="text-decoration: none; font-weight: bold; color:'+Theme.primaryColor+'" href="guestBotCallerId://">' + Emoji.emojify(guestBotCaller.title, font.pixelSize)+'</a>')
                            font.pixelSize: Theme.fontSizeExtraSmall
                            textFormat: Text.RichText
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                            onLinkActivated:
                                if (link == 'guestBotCallerId://')
                                    guestBotCaller.open()
                                else utilities.handleLink(link)
                        }
                    }
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
                                layer.enabled: messageInReplyToMouseArea.pressed && !messageListItem.highlighted && !messageListItem.menuOpen
                                layer.effect: PressEffect { source: messageInReplyToRow }
                                inReplyToMessage: messageInReplyToLoader.inReplyToMessage
                                inReplyToMessageDeleted: messageInReplyToLoader.inReplyToMessageDeleted
                            }
                            MouseArea {
                                id: messageInReplyToMouseArea
                                anchors.fill: parent
                                onClicked:
                                    if (precalculatedValues.pageIsSelecting)
                                        view.toggleMessageSelection(myMessage, messageAlbumMessageIds)
                                    else
                                        messagesView.showMessage(messageInReplyToRow.inReplyToMessage.id, true)
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
                        MouseArea {
                            id: forwardedMouseArea

                            property var origin: myMessage.forward_info.origin
                            property string originType: origin["@type"]
                            property bool isChannel: originType === 'messageOriginChannel'
                            property bool isHiddenUser: originType === 'messageOriginHiddenUser'

                            TDLibMessageSender {
                                id: forwardedOriginSender
                                isChat: forwardedMouseArea.isChannel || forwardedMouseArea.originType == 'messageOriginChat'
                                chatId: isChat ? (forwardedMouseArea.isChannel ? forwardedMouseArea.origin.chat_id : forwardedMouseArea.origin.sender_chat_id) : null
                                isUser: forwardedMouseArea.originType == 'messageOriginUser'
                                userId: isUser ? forwardedMouseArea.origin.sender_user_id : null
                            }

                            Row {
                                spacing: Theme.paddingSmall
                                width: parent.width

                                ProfileThumbnail {
                                    id: forwardedThumbnail
                                    photoData: forwardedOriginSender.smallPhoto
                                    replacementStringHint: forwardedChannelText.text
                                    width: Theme.itemSizeExtraSmall
                                    height: Theme.itemSizeExtraSmall
                                    highlighted: forwardedMouseArea.containsPress
                                }

                                Column {
                                    spacing: Theme.paddingSmall
                                    width: parent.width - forwardedThumbnail.width - Theme.paddingSmall
                                    Label {
                                        width: parent.width
                                        text: qsTr("Forwarded Message")
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        font.italic: true
                                        truncationMode: TruncationMode.Fade
                                        textFormat: Text.StyledText
                                        highlighted: forwardedMouseArea.containsPress
                                    }
                                    Label {
                                        width: parent.width
                                        id: forwardedChannelText
                                        text: Emoji.emojify(forwardedMouseArea.isHiddenUser
                                                            ? forwardedMouseArea.origin.sender_name
                                                            : forwardedOriginSender.title, font.pixelSize)
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        font.bold: true
                                        truncationMode: TruncationMode.Fade
                                        textFormat: Text.StyledText
                                        highlighted: forwardedMouseArea.containsPress
                                    }
                                }
                            }

                            onClicked:
                                if (isHiddenUser)
                                    appNotification.show(qsTr("The account was hidden by the user", "Forwarded message"))
                                else
                                    forwardedOriginSender.open(isChannel ? {messageIdToShow: origin.message_id} : {})
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: messageText.height + extraContentLoader.height + (messageText.height > 0 && extraContentLoader.height > 0 ? Theme.paddingSmall : 0)
                    Text {
                        id: messageText
                        width: parent.width
                        text: Emoji.emojify(isAlbum ? utilities.getAlbumMessagesText(messageAlbumMessages) : utilities.getMessageText(myMessage), Theme.fontSizeSmall)
                        font.pixelSize: Theme.fontSizeSmall
                        color: messageListItem.textColor
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        onLinkActivated:
                            utilities.handleLink(link, chatInformation.id, topicId)
                        horizontalAlignment: messageListItem.textAlign
                        linkColor: Theme.highlightColor
                        height: text.length > 0 ? implicitHeight : 0
                    }

                    Loader {
                        id: extraContentLoader
                        width: parent.width * getContentWidthMultiplier()
                        //anchors.horizontalCenter: parent.horizontalCenter
                        asynchronous: true
                        readonly property var defaultExtraContentHeight: messageListItem.hasContentComponent ? chatView.getContentComponentHeight(model.content_type, myMessage.content, width, model.album_message_ids.length) : 0
                        height: item ? item.height : defaultExtraContentHeight
                        visible: height > 0
                    }

                    states: [
                        State {
                            name: "default"
                            when: (messageText.visible && !extraContentLoader.visible) || (!messageText.visible && extraContentLoader.visible)
                        },
                        State {
                            name: "normal"
                            when: messageText.visible && extraContentLoader.visible &&
                                  ((typeof myMessage.content.show_caption_above_media == 'undefined' && !contentAboveMedia)
                                   || myMessage.content.show_caption_above_media === false)
                            AnchorChanges {
                                target: messageText
                                anchors.top: extraContentLoader.bottom
                            }
                            PropertyChanges {
                                target: messageText
                                anchors.topMargin: Theme.paddingSmall
                            }
                        },
                        State {
                            name: "inverted"
                            when: messageText.visible && extraContentLoader.visible &&
                                  ((typeof myMessage.content.show_caption_above_media == 'undefined' && contentAboveMedia)
                                   || !!myMessage.content.show_caption_above_media)
                            AnchorChanges {
                                target: extraContentLoader
                                anchors.top: messageText.bottom
                            }
                            PropertyChanges {
                                target: extraContentLoader
                                anchors.topMargin: Theme.paddingSmall
                            }
                        }
                    ]
                }

                Loader {
                    id: webPagePreviewLoader
                    active: false
                    asynchronous: true
                    width: parent.width * getContentWidthMultiplier()
                    height: (status === Loader.Ready) ? item.height : myMessage.content.link_preview ? precalculatedValues.webPagePreviewHeight : 0

                    sourceComponent: Component {
                        WebPagePreview {
                            linkPreviewData: myMessage.content.link_preview
                            width: parent.width
                            highlighted: messageListItem.highlighted
                        }
                    }
                }

                Binding {
                    target: extraContentLoader.item
                    when: extraContentLoader.item && ("highlighted" in extraContentLoader.item) && (typeof extraContentLoader.item.highlighted === "boolean")
                    property: "highlighted"
                    value: messageListItem.highlighted || messageListItem.down || messageListItem.isSelected
                }

                Loader {
                    id: replyMarkupLoader
                    width: parent.width
                    height: active ? (myMessage.reply_markup.rows.length * (Theme.itemSizeSmall + Theme.paddingSmall) - Theme.paddingSmall) : 0
                    asynchronous: true
                    active: !!(myMessage.reply_markup && myMessage.reply_markup.rows)
                    source: Qt.resolvedUrl("ReplyMarkupButtons.qml")
                }

                Loader {
                    id: sponsoredMessageButtonLoader
                    active: isSponsored
                    asynchronous: true
                    width: parent.width
                    height: (status === Loader.Ready) ? item.implicitHeight : isSponsored ? Theme.itemSizeMedium : 0

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
                        messageStatusText.update()
                }

                Text {
                    id: messageStatusText
                    width: parent.width
                    font.pixelSize: Theme.fontSizeTiny
                    color: isOutgoing ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    horizontalAlignment: messageListItem.textAlign

                    property bool useElapsed: true
                    property bool _reloadText
                    function update() { _reloadText = !_reloadText }
                    text: {
                        // https://stackoverflow.com/questions/48325115/qml-programmatically-update-binding
                        if (_reloadText && !_reloadText) return ''

                        if (!myMessage) return ''
                        if (myMessage['@type'] === 'sponsoredMessage')
                            return myMessage.is_recommended ? qsTr("Recommended Message") : qsTr("Sponsored Message")

                        var messageStatusSuffix = ''
                        if (myMessage.edit_date > 0)
                            messageStatusSuffix += ' - ' + qsTr("edited")
                        if (myMessage.author_signature && !messageListItem.precalculatedValues.showUserInfo)
                            messageStatusSuffix += " - " + myMessage.author_signature

                        if (Debug.enabled)
                            messageStatusSuffix += " (ID: " + messageId + ")"

                        return (messageViewCount ? (Emoji.emojify('👁️ ', Theme.fontSizeTiny) + Functions.getShortenedCount(messageViewCount) + ' ') : '')
                                + (useElapsed ? Functions.getDateTimeElapsed : Functions.getDateTimeTranslated)(myMessage.date)
                                + messageStatusSuffix
                    }

                    Icon {
                        id: statusIcon
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        sourceSize: {
                            width: width
                            height: height
                        }
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        visible: !!source
                        source: isOutgoing ? Functions.getMessageSendingStateIcon(messageId, messagesModel.lastReadOutboxMessageId, myMessage.sending_state) : ''
                        highlighted: isOutgoingRead
                    }
                    rightPadding: statusIcon.visible ? statusIcon.width + Theme.paddingSmall : 0

                    MouseArea {
                        anchors.fill: parent
                        enabled: !messageListItem.precalculatedValues.pageIsSelecting
                        onClicked:
                            messageStatusText.useElapsed = !messageStatusText.useElapsed
                    }
                }

                Loader {
                    // TODO: animate choosing a reaction
                    id: interactionLoader
                    width: parent.width
                    asynchronous: true
                    active: reactions.length > 0
                    height: active ? implicitHeight : 0

                    sourceComponent: Component {
                        Flow {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            layoutDirection: isOutgoing ? Qt.RightToLeft : Qt.LeftToRight
                            Repeater {
                                model: reactions
                                Rectangle {
                                    visible: reactionLoader.supported
                                    height: Theme.fontSizeSmall + Theme.paddingSmall
                                    width: childrenRect.width + Theme.paddingSmall
                                    radius: width

                                    color: modelData.is_chosen ? Theme.rgba(Theme.highlightBackgroundColor, 0.6) : Theme.rgba(Theme.secondaryColor, Theme.highlightBackgroundOpacity)

                                    MessageReaction {
                                        id: reactionLoader
                                        x: Theme.paddingSmall/2
                                        y: x
                                        height: parent.height - y*2
                                        width: height
                                        type: modelData.type
                                    }

                                    RecentActorsList {
                                        id: recentReactors
                                        height: parent.height
                                        anchors {
                                            left: reactionLoader.right
                                            leftMargin: Theme.paddingSmall/2
                                        }
                                        inverted: true
                                        model: modelData.recent_sender_ids.reverse()
                                    }

                                    Text {
                                        anchors {
                                            left: reactionLoader.right
                                            leftMargin: visible ? (recentReactors.count > 0 ? (Theme.paddingSmall + parent.height + Math.max(0, Theme.paddingMedium*(recentReactors.count - 1))) : Theme.paddingSmall/2) : 0
                                        }
                                        visible: (modelData.total_count - recentReactors.count) > 0
                                        width: visible ? implicitWidth : 0
                                        text: Functions.getShortenedCount(modelData.total_count)
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        color: modelData.is_chosen ? Theme.highlightColor : Theme.primaryColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        // TODO: check if you can actually add the reaction
                                        onClicked:
                                            switch (modelData.type['@type']) {
                                            case 'reactionTypeEmoji':
                                            case 'reactionTypeCustomEmoji':
                                                if (modelData.is_chosen)
                                                    tdLibWrapper.removeMessageReaction(chatId, messageId, modelData.type)
                                                else
                                                    tdLibWrapper.addMessageReaction(chatId, messageId, modelData.type)
                                                break
                                            //case 'reactionTypePaid':
                                            //    ...
                                            }
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
