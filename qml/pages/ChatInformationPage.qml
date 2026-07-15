//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
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

    property int chatOnlineMemberCount: 0;

    property bool isPrivateChat: false
    property bool isSecretChat: false
    property bool isBasicGroup: false
    property bool isSupergroup: false
    property bool isChannel: false

    property var chatUserOrGroupId

    property bool isInitialized: false

    readonly property bool isPrivateOrSecretChat: isPrivateChat || isSecretChat
    readonly property bool isGroup: isBasicGroup || isSupergroup

    readonly property bool isSavedMessages: isPrivateOrSecretChat && chatUserOrGroupId === tdLibWrapper.myUserId

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
    property var chatInformation: chatManager.chatInformation
    property var privateChatUserInformation: chatManager.userInfo
    property var chatPartnerFullInformation:({})
    property var groupInformation: chatManager.groupInfo
    property var groupFullInformation: ({})

    property bool fullInfoReady: false
    readonly property string username: isPrivateOrSecretChat ?
                                  (privateChatUserInformation.usernames.editable_username ? "@"+privateChatUserInformation.usernames.editable_username : "")
                                : ((groupInformation && groupInformation.usernames && groupInformation.usernames.editable_username)
                                   ? "@"+groupInformation.usernames.editable_username : "")

    ChatManagerLoader {
        id: chatManagerLoader
        parent: chatInformationPage
    }

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
