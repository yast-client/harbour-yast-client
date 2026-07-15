//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import io.yaqtlib 1.0

QtObject {
    id: root

    property var chatManager
    property var chatId
    property var parent
    property bool doInit: true

    signal ready
    signal infoInitialized

    property Loader loader: Loader {
        active: false
        sourceComponent: Component {
            ChatManager {
                tdlib: tdLibWrapper
                chatId: root.chatId
                onInfoInitializedChanged:
                    if (infoInitialized)
                        root.infoInitialized()
            }
        }
        onStatusChanged: {
            if (status == Loader.Ready) {
                root.chatManager = item
                root.ready()
            }
        }
    }

    function init() {
        if (typeof chatManager === 'undefined')
            loader.active = true
        else
            ready()
    }

    Component.onCompleted: if (doInit) init()
}
