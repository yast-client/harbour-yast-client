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
        onClicked:
            // don't use utilities.handleLink here because we can't get yaqtlib-specific links here
            tdLibWrapper.getInternalLinkType(message.sponsor.url)
    }
}
