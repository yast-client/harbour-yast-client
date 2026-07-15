//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

QtObject {
    id: root

    property var messageSender
    property bool isChat: !!messageSender && messageSender['@type'] === 'messageSenderChat'
    property bool isUser: !!messageSender && messageSender['@type'] === 'messageSenderUser'
    property var chatId: isChat ? messageSender.chat_id : undefined
    property var userId: isUser ? messageSender.user_id : undefined

    property var chatInformation: tdLibWrapper.getChat(chatId)
    property var userInformation: tdLibWrapper.getUserInformation(userId)

    property string title: (isChat ? chatInformation.title : utilities.getUserName(userInformation)) || qsTr("Unknown", "An unknown chat or user")
    property var smallPhoto: (isChat
                                ? (chatInformation && chatInformation.photo ? chatInformation.photo.small : {})
                                : (userInformation && userInformation.profile_photo ? userInformation.profile_photo.small : {}))
                            || {}

    property var __conn: Connections {
        target: tdLibWrapper

        onChatRolesUpdated:
            if (chatId === root.chatId)
                chatInformation = tdLibWrapper.getChat(chatId)

        onUserUpdated:
            if (userId === root.userId)
                userInformation = tdLibWrapper.getUserInformation(userId)
    }

    function open(chatOptions, replace) {
        if (isChat) {
            var options = chatOptions || {}
            options.chatInformation = chatInformation

            var f = replace ? pageStack.replace : pageStack.push // FIXME: why is this needed?
            f(Qt.resolvedUrl("../pages/ChatPage.qml"), options)
        } else if (isUser)
            tdLibWrapper.createPrivateChat(userId, 'openDirectly')
    }
}
