//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../js/twemoji.js" as Emoji

QtObject {
    id: root
    // FIXME: even when setting ownership to JavascriptOwnership
    // makes the FormattedText object destroy only after the whole app is closed
    // We're setting a parent explicitly now as a workaround, but generally, it should destroy without it too

    property var formattedText
    property bool ignoreCustomEmoji
    property real emojiSize: Theme.fontSizeSmall

    property var textObject: utilities.createFormattedText(formattedText, ignoreCustomEmoji)

    property bool emojifyNormal: true
    property string text: textObject ? (emojifyNormal ? Emoji.emojify(textObject.parsedText, emojiSize) : textObject.parsedText) : null

    property Binding _sizeBinding: Binding {
        target: textObject
        property: 'customEmojiSize'
        value: Emoji.getEmojiSize(emojiSize)
    }

    // FIXME
    onTextObjectChanged: gc()
    Component.onDestruction: gc()
}
