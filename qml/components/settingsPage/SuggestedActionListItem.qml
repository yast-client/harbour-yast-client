//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

ListItem {
    id: listItem
    width: parent.width

    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    property string name

    contentHeight: column.height

    function hide() {
        tdLibWrapper.hideSuggestedAction(name)
    }

    onClicked: openMenu()

    Column {
        id: column
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        spacing: Theme.paddingMedium
        bottomPadding: Theme.paddingMedium

        Label {
            id: titleLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeMedium
            //color: Theme.highlightColor
            font.bold: true
        }

        Label {
            id: descriptionLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
