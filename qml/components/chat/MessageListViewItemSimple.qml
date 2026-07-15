//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug

MessageListViewItemBase {
    id: messageListItem
    width: parent.width
    contentHeight: column.height + Theme.paddingMedium*2

    readonly property var messageId: messageData.messageId
    readonly property var myMessage: messageData.message

    property var linkedMessage

    contextMenuLoader.hideSelect: true
    contextMenuLoader.canCopy: false
    contextMenuLoader.hideTranslate: true

    Column {
        id: column
        y: Theme.paddingMedium
        width: backgroundRectangle.width
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingMedium

        Rectangle {
            id: backgroundRectangle
            height: messageText.height
            width: Math.min(messageText.implicitWidth, messageListItem.width - Theme.horizontalPageMargin * 2)
            color: Theme.rgba(backgroundHighlighted ? Theme.highlightColor : (Theme.colorScheme === Theme.LightOnDark ? Theme.secondaryColor : Theme.overlayBackgroundColor), backgroundHighlighted ? 0.3 : 0.1)
            radius: Theme.paddingSmall

            Text {
                id: messageText
                width: parent.width
                anchors.centerIn: parent
                padding: Theme.paddingMedium
                text: Emoji.emojify('<a style="text-decoration: none; font-weight: bold; color: %1" href="openSender">%2</a> '.arg(Theme.secondaryHighlightColor).arg(messageSenderInfo.title)
                                    + utilities.getMessageText(myMessage, topicId ? Utilities.MessageTextSimpleInForumTopic : Utilities.MessageTextSimple, false, true, forumTopicName),
                                    font.pixelSize)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                onLinkActivated:
                    if (link === 'openSender')
                        messageSenderInfo.open()
                    else if (link === 'linkedmessage' && linkedMessage)
                        messagesView.showMessage(linkedMessage.id)
                    else
                        utilities.handleLink(link)
            }
        }

        MessageInteractionReactions {
            width: parent.width
            reactions: messageListItem.reactions
        }
    }

    Loader {
        id: gameScoreInfoLoader
        active: myMessage.content["@type"] === "messageGameScore"
        asynchronous: true
        sourceComponent: Component {
            Connections {
                target: tdLibWrapper
                onMessageReceived: {
                    if (chatId === chatPage.chatId && messageId === myMessage.content.game_message_id) {
                        messageListItem.linkedMessage = message
                        messageText.messageContentText = (messageListItem.isOwnMessage
                                ? qsTr("scored %Ln points in %2", "myself", myMessage.content.score)
                                : qsTr("scored %Ln points in %2", "", myMessage.content.score))
                            .arg("<a href=\"linkedmessage\" style=\"text-decoration: none; color:"+Theme.primaryColor+"\">"+message.content.game.title+"</a>")
                    }
                }
                Component.onCompleted:
                    tdLibWrapper.getMessage(chatPage.chatInformation.id, myMessage.content.game_message_id)
            }
        }
    }
}
