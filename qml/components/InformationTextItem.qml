//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Column {
    id: textItem
    property alias headerText: headerItem.text
    property string text
    property bool isLinkedLabel // for telephone number
    property bool highlight
    width: parent.width
    visible: !!text
    SectionHeader {
        id: headerItem
        visible: text !== "" && labelLoader.status === Loader.Ready && labelLoader.item.text !== ""
        height: visible ? Theme.itemSizeSmall : 0
        x: 0
    }
    Loader {
        id: labelLoader
        active: true
        asynchronous: true
        sourceComponent: textItem.isLinkedLabel ? linkedLabelComponent : labelComponent
        width: textItem.width
    }

    Component {
        id: labelComponent
        Label {
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeMedium
            textFormat: Text.StyledText
            color: highlight && highlighted ? Theme.highlightColor : Theme.primaryColor
            text: Emoji.emojify( Functions.replaceUrlsWithLinks(textItem.text).replace(/\n/g, "<br>"), Theme.fontSizeExtraSmall)
            linkColor: highlighted ? Theme.primaryColor : Theme.highlightColor
            visible: text !== ""
            onLinkActivated: {
                utilities.handleLink(link);
            }
        }
    }
    Component {
        id: linkedLabelComponent
        LinkedLabel {
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeSmall
            textFormat: Text.StyledText
            color: Theme.highlightColor
            plainText: textItem.text
            visible: textItem.text !== ""
            onLinkActivated: utilities.handleLink(link)
        }
    }
}
