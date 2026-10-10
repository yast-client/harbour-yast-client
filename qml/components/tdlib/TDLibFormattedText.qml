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

    property var formattedText: utilities.getMessageFormattedText(messageData, messageType, false, forumTopicName)
    property real emojiSize: Theme.fontSizeSmall

    property FormattedTextBase textObject: FormattedTextBase {
        tdlib: tdLibWrapper
        customEmojiSize: Emoji.getEmojiSize(emojiSize)
    }

    property bool emojifyNormal: true
    property string text: emojifyNormal ? Emoji.emojify(textObject.parsedText, emojiSize) : textObject.parsedText

    onFormattedTextChanged: textObject.setFormattedText(formattedText)
}
