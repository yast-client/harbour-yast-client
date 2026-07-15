//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../messageContent"
import "../../js/functions.js" as Functions

ChatInformationTabItemMediaList {
    messageDelegate: Component {
        MessageDocument {
            width: parent.width
            messageListItem: parent.listItem
            rawMessage: parent.listItem.message
            tertiaryText: Functions.getDateTimeElapsed(rawMessage.date)
            openMouseArea.enabled: false

            onClicked: download()
        }
    }
}
