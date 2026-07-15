//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Slava Monich and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/twemoji.js" as Emoji

// Combination of maximumLineCount and TruncationMode.Elide (or Fade) breaks
// Emoji image alignment, pushing the image down. This one aligns the image
// correctly on its line.
Label {
    property string rawText
    property int maxLineCount

    wrapMode: Text.Wrap
    textFormat: Text.StyledText
    truncationMode: TruncationMode.Elide
    visible: !!rawText

    // lineCount is unreliable for StyledText with images and line breaks
    readonly property int fontSize: font.pixelSize
    readonly property int actualLineHeight: (text === rawText) ? fontSize : (fontSize * 6 / 5)
    readonly property int actualLineCount: Math.floor(implicitHeight/actualLineHeight)

    Component.onCompleted: refitText()
    onFontSizeChanged: refitText()
    onWidthChanged: refitText()
    onRawTextChanged: refitText()
    onMaxLineCountChanged: refitText()

    function emojify(str) {
        return Emoji.emojify(str, fontSize)
    }

    function refitText() {
        text = emojify(rawText)
        if (maxLineCount > 0) {
            var divisor = 1
            var max = rawText.length
            var min = max
            while (actualLineCount > maxLineCount && divisor < rawText.length) {
                max = min
                divisor++
                min = rawText.length/divisor
                text = emojify(rawText.substr(0, min) + "…")
            }
            while (min < max) {
                var mid = Math.floor((min + max)/2)
                if (mid === min) {
                    text = emojify(rawText.substr(0, min) + "…")
                    break
                } else {
                    text = emojify(rawText.substr(0, mid) + "…")
                    if (actualLineCount > maxLineCount) {
                        max = mid
                    } else {
                        min = mid
                    }
                }
            }
        }
    }
}
