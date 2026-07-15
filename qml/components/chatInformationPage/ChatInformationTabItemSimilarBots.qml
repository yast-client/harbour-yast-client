//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'
import '../tdlib'

ChatInformationTabItemChatsBase {
    loadInitial: false
    fullyLoaded: true
    model: botSimilarBots
    delegate: TDLibChatListItem {
        userId: modelData
        prologSecondaryText.text: ''
    }

    Component {
        id: infoLabelComponent
        InfoLabel {
            anchors.topMargin: Theme.paddingLarge
            anchors.bottomMargin: Theme.paddingLarge
            text: qsTr("Subscribe to Telegram Premium to unlock up to %Ln similar bots.", "Info label suggesting the user to get Telegram Premium to access more similar bots", botSimilarBotsCount)
        }
    }
    view.footer: botSimilarBotsCount > view.count ? infoLabelComponent : null
}
