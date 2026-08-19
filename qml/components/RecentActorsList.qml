//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import 'tdlib'

Item {
    implicitWidth: count ? height + paddingDifference * (count - 1) : 0

    property real paddingDifference: Theme.paddingMedium
    property bool inverted
    property alias model: repeater.model
    property alias count: repeater.count
    property bool userIds // specifies if the model contains user ids instead of messageSender objects

    property bool highlighted

    Repeater {
        id: repeater
        ProfileThumbnail {
            id: profileThumbnail
            height: parent.height
            width: height
            x: paddingDifference * (inverted ? repeater.count - index - 1 : index)

            highlighted: parent.highlighted

            accentColorId: userInfoLoader.info.accent_color_id
            photoData: isChat ? chatData.photo.small : userInfoLoader.info.profile_photo.small
            replacementStringHint: isChat ? chatData.title : utilities.getUserName(userInfoLoader.info)

            property bool isChat: !userIds && modelData['@type'] === 'messageSenderChat'
            property var chatData: isChat ? tdData.getChat(modelData.chat_id) : null

            TDLibUser {
                id: userInfoLoader
                userId: isChat ? 0 : (userIds ? modelData : modelData.user_id)
            }

            Connections {
                target: isChat ? tdData : null
                onChatRolesUpdated:
                    if (chatId === modelData.chat_id && utilities.hasRoleInVector(changedRoles, [TDLibChat.RoleTitle, TDLibChat.RolePhoto, TDLibChat.RoleAccentColorId]))
                        chatData = Qt.binding(function() { return isChat ? tdData.getChat(modelData.chat_id) : null })
            }
        }
    }
}
