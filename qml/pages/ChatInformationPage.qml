//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/tdlib"
import "../components/chatInformationPage"
import "../components/chat"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: chatInformationPage
    property bool isChatInformationPage: true

    allowedOrientations: Orientation.All
    property string searchString

    property int chatOnlineMemberCount: 0

    readonly property bool isPrivateChat: chatManager.chatType === TDLibAPI.ChatTypePrivate
    readonly property bool isSecretChat: chatManager.chatType === TDLibAPI.ChatTypeSecret
    readonly property bool isBasicGroup: chatManager.chatType === TDLibAPI.ChatTypeBasicGroup
    readonly property bool isSupergroup: chatManager.chatType === TDLibAPI.ChatTypeSupergroup
    readonly property bool isChannel: chatManager.isChannel

    property alias chatId: chatManagerLoader.chatId
    property var chatUserOrGroupId: isPrivateOrSecretChat ? userInformation.id : groupInformation.id

    property bool isInitialized: false

    readonly property bool isPrivateOrSecretChat: isPrivateChat || isSecretChat
    readonly property bool isGroup: isBasicGroup || isSupergroup

    readonly property bool isSavedMessages: isPrivateOrSecretChat && chatUserOrGroupId === tdData.myUserId
    readonly property bool isBot: isPrivateOrSecretChat && userInformation.type['@type'] === 'userTypeBot'

    readonly property bool canGetMembers: !!(groupFullInformation && groupFullInformation.can_get_members)
    readonly property bool userIsMember: (isPrivateOrSecretChat && chatInformation["@type"]) || // should be optimized
                                isGroup && (
                                    (groupInformation.status["@type"] === "chatMemberStatusMember")
                                    || (groupInformation.status["@type"] === "chatMemberStatusAdministrator")
                                    || (groupInformation.status["@type"] === "chatMemberStatusRestricted" && groupInformation.status.is_member)
                                    || (groupInformation.status["@type"] === "chatMemberStatusCreator" && groupInformation.status.is_member)
                                    )
    readonly property bool isGroupCreator: isGroup && groupInformation.status["@type"] === "chatMemberStatusCreator"

    property alias chatManager: chatManagerLoader.chatManager
    readonly property var chatInformation: chatManager.chatInformation
    readonly property var userInformation: chatManager.userInfo
    property var userFullInformation:({})
    property var groupInformation: chatManager.groupInfo
    property var groupFullInformation: ({})

    property bool fullInfoReady: false
    readonly property string username: isPrivateOrSecretChat ?
                                  (userInformation.usernames.editable_username ? "@"+userInformation.usernames.editable_username : "")
                                : ((groupInformation && groupInformation.usernames && groupInformation.usernames.editable_username)
                                   ? "@"+groupInformation.usernames.editable_username : "")

    readonly property double communityId: (isPrivateOrSecretChat ? userFullInformation : groupFullInformation).community_id || 0
    property var communityInfo

    ChatManagerLoader {
        id: chatManagerLoader
        parent: chatInformationPage
    }

    TDLibAccentColor {
        id: profileAccentColor
        colorId: chatInformation.profile_accent_color_id
    }
    palette.highlightColor: profileAccentColor.invalid ? Theme.highlightColor : profileAccentColor.colors[0]
    palette.secondaryHighlightColor: profileAccentColor.invalid ? Theme.secondaryHighlightColor : profileAccentColor.colors[1]

    onStatusChanged: {
        switch (status) {
        case PageStatus.Activating:
            Debug.log("activating Loader")
            mainContentLoader.active = true
            break
        case PageStatus.Active:
            break
        }
    }

    Loader {
        id: mainContentLoader
        active: false
        asynchronous: true
        anchors.fill: parent
        source: Qt.resolvedUrl("../components/chatInformationPage/ChatInformationPageContent.qml")
    }
}
