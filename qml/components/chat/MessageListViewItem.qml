//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../messageContent'
import '../tdlib'
import '../../js/twemoji.js' as Emoji
import '../../js/functions.js' as Functions
import '../../js/debug.js' as Debug

MessageListViewItemBase {
    id: messageListItem

    contentHeight: messageBackground.height + messageTextRow.y + Theme.paddingSmall/2
    Behavior on contentHeight { NumberAnimation { duration: 200 } }

    readonly property color textColor: isOutgoing ? Theme.highlightColor : Theme.primaryColor
    readonly property int textAlign: isOutgoing ? Text.AlignRight : Text.AlignLeft
    property bool isSponsored: myMessage['@type'] === 'sponsoredMessage'
    readonly property bool isUnread: messagesView.readable && !isOutgoing && !isSponsored && messagesModel.lastReadInboxMessageId && messageId > messagesModel.lastReadInboxMessageId

    property bool hasContentComponent
    property bool fullWidthWidescreenContent
    readonly property real contentWidthModifier: !fullWidthWidescreenContent && Functions.isWidescreen(appWindow) ? 0.4 : 1.0
    property bool contentAboveMedia

    onClickedNormally: {
        // Allow extra context to react to click
        var extraContent = extraContentLoader.item
        if (extraContent && extraContentLoader.contains(mapToItem(extraContentLoader, x, y)))
            extraContent.clicked()
        else if (webPagePreviewLoader.item)
            webPagePreviewLoader.item.clicked()
    }

    // Just in case we will need them back
    property bool __otherTranslations: qsTr("Copy Message to Clipboard") + qsTr("Select Message") + qsTr("More Options...") + qsTr("Unpin Message") + qsTr("Pin Message")

    messageSenderInfo.messageSender: isOwnMessage ? undefined : myMessage.sender_id

    contextMenuLoader.canCopy: isAlbum // for document albums, there is no text in messageText
                               ? !!utilities.getAlbumMessagesText(messageData.messageAlbumMessages, false)
                               : messageText.height > 0
    contextMenuLoader.canTranslate: !!messageText.text
    contextMenuLoader.onHandleExtraContextMenuItems: {
        if (!extraContentLoader.item || !extraContentLoader.item.extraContextMenuItems) return
        for (var i=0; i<extraContentLoader.item.extraContextMenuItems.length; i++) {
            var item = extraContentLoader.item.extraContextMenuItems[i]
            if (item.processProperties)
                item.processProperties(properties)
            item.parent = parent
        }
    }

    Connections {
        target: tdLibWrapper
        onMessageReceived:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessage = message
        onMessageNotFound:
            if (messageId === myMessage.reply_to_message_id)
                messageInReplyToLoader.inReplyToMessageDeleted = true
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
                color: backgroundHighlighted ? highlightColor
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
                                        messagesView.toggleMessageSelection(myMessage, messageAlbumMessageIds)
                                    else
                                        messagesView.showMessage(messageInReplyToRow.inReplyToMessage.id)
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
                        text: Emoji.emojify(isAlbum ? utilities.getAlbumMessagesText(messageAlbumMessages) : utilities.getMessageText(myMessage), font.pixelSize)
                        font.pixelSize: Theme.fontSizeSmall
                        color: messageListItem.textColor
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        onLinkActivated:
                            utilities.handleLink(link, chatId, topicId)
                        horizontalAlignment: messageListItem.textAlign
                        linkColor: Theme.highlightColor
                        height: text.length > 0 ? implicitHeight : 0
                    }

                    Loader {
                        id: extraContentLoader
                        width: parent.width * contentWidthModifier
                        //anchors.horizontalCenter: parent.horizontalCenter
                        asynchronous: true
                        readonly property var defaultExtraContentHeight: messageListItem.hasContentComponent ? chatView.getContentComponentHeight(model.content_type, myMessage.content, width, model.album_message_ids.length) : 0
                        height: item ? item.height : defaultExtraContentHeight
                        visible: height > 0
                    }

                    states: [
                        State {
                            name: "default"
                            when: messageText.visible !== extraContentLoader.visible
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
                    width: parent.width * contentWidthModifier
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
                        width: visible ? Theme.iconSizeSmall : 0
                        height: width
                        sourceSize {
                            width: width
                            height: height
                        }
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        visible: messagesView.readable && isOutgoing
                        source: visible ? Functions.getMessageSendingStateIcon(messageId, messagesModel.lastReadOutboxMessageId, myMessage.sending_state) : ''
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

                MessageInteractionReactions {
                    reactions: messageListItem.reactions
                    invertLayout: isOutgoing
                }

            }
        }
    }
}
