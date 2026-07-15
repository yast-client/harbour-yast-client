//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '../../js/twemoji.js' as Emoji

AlbumMessageContentBase {
    id: messageContent
    width: parent.width
    height: column.height

    property Component sourceComponent

    Column {
        id: column
        width: parent.width
        Repeater {
            model: albumMessages
            BackgroundItem {
                id: messageBackgroundItem
                width: parent.width
                height: loader.height + messageText.height

                // FIXME this is broken (isn't highlighted when selected):
                readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting && page.selectedMessages.some(function(existingMessage) {
                    return existingMessage.id === albumMessages[index].id
                })
                highlighted: isSelected || down || messageContent.highlighted
                onPressAndHold: messagesView.toggleMessageSelection(albumMessages[index])
                onClicked:
                    if (messageListItem.precalculatedValues.pageIsSelecting)
                        messagesView.toggleMessageSelection(albumMessages[index])

                Loader {
                    id: loader
                    property var message: albumMessages[index]
                    width: parent.width
                    sourceComponent: messageContent.sourceComponent
                    asynchronous: true
                }

                Text {
                    id: messageText
                    width: parent.width
                    anchors.top: loader.bottom
                    text: Emoji.emojify(utilities.enhanceMessageText(albumMessages[index].content.caption), font.pixelSize)
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
            }
        }
    }
}
