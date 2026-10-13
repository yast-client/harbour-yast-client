//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../js/twemoji.js" as Emoji

QtObject {
    id: root

    property var messageData
    property int messageType: Utilities.MessageTextDefault
    property string forumTopicName

    property var formattedText: utilities.getMessageFormattedText(messageData, messageType, FormattedTextBase.None, forumTopicName)
    property real emojiSize: Theme.fontSizeSmall

    property color linkColor: Theme.highlightColor
    property color spoilerColor: Theme.highlightBackgroundColor

    property FormattedTextBase textObject: FormattedTextBase {
        tdlib: tdLibWrapper
        customEmojiSize: Emoji.getEmojiSize(emojiSize)
    }

    property bool emojifyNormal: true
    property string parsedText: textObject.parsedText // cache
    property bool needsRichText: textObject.needsRichText
    property string text: (needsRichText ? '<style> a { color: %1; } \n .spoiler { background-color: %2; color: %2; text-decoration: none; } </style>'.arg(linkColor).arg(spoilerColor) : '')
        + (emojifyNormal ? Emoji.emojify(parsedText, emojiSize) : parsedText)
    property int textFormat: needsRichText ? Text.RichText : Text.StyledText

    function openTextUrl(url) { return textObject.handleTextLink(url) }
    function openUrl(url) { textObject.handleLink(url) }

    onFormattedTextChanged: textObject.setFormattedText(formattedText)
}
