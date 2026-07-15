//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

BackgroundItem {
    id: queryResultItem

    function sendInlineQueryResultMessage() {
        tdLibWrapper.sendInlineQueryResultMessage(inlineQueryLoader.chatId, 0, 0, inlineQueryComponent.inlineQueryId, model.id);
        inlineQueryLoader.textField.text = "";
    }
    onClicked: {
        sendInlineQueryResultMessage()
    }

}
