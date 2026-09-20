//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property var message

    Button {
        id: sponsoredMessageButton
        anchors.horizontalCenter: parent.horizontalCenter

        text: message ? message.button_text : ''
        onClicked: messagesView.getInternalLinkType(message.sponsor.url)
    }
}
