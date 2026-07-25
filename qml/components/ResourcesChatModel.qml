//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import io.yaqtlib 1.0
import '../js/debug.js' as Debug

MediaMessagesModel {
    // Additional resources are fetched from a special chat
    // They are filtered using hashtags, for example `query: '#mycoolpage #smallscreen #whatever_you_want_here'`

    property bool fetchAll: true

    tdlib: tdLibWrapper

    readonly property bool authorizationReady: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady
    property bool searchingChat

    function fetch() {
        if (!authorizationReady) return

        if (tdLibWrapper.hasChatData(appConfig.resourcesChatId)) {
            searchingChat = false
            init(appConfig.resourcesChatId)
        } else if (!searchingChat) {
            searchingChat = true
            tdLibWrapper.searchPublicChat(appConfig.resourcesUsername)
        }
    }

    Component.onCompleted: fetch()
    onAuthorizationReadyChanged: fetch()

    property Connections tdConnections: Connections {
        target: searchingChat ? tdLibWrapper : null
        ignoreUnknownSignals: true
        onChatReceived:
            if (chat.id === appConfig.resourcesChatId)
                fetch()
    }

    onMessagesReceived:
        if (fetchAll && !endReached) loadMoreHistory()
}
