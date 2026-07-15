//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: rectangle
    width: text.width + border.width*2 + Theme.paddingSmall*2
    height: text.height + border.width*2 + Theme.paddingSmall
    radius: Theme.paddingSmall
    color: error ? 'transparent' : Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
    border {
        width: error ? Theme.paddingSmall : 0
        color: error ? Theme.errorColor : 'transparent'
    }

    property alias text: text.text
    property bool error: true
    property alias textColor: text.color

    Text {
        id: text
        anchors.centerIn: parent
        color: error ? rectangle.border.color : Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        font.bold: error
        font.capitalization: error ? Font.AllUppercase : Font.MixedCase
    }
}
