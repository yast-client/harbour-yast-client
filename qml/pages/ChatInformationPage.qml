/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
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
    property var myUserId: tdLibWrapper.getUserInformation().id;

    property bool isPrivateChat: false
    property bool isSecretChat: false
    property bool isBasicGroup: false
    property bool isSuperGroup: false
    property bool isChannel: false

    property var chatUserOrGroupId

    property bool isInitialized: false

    readonly property bool isPrivateOrSecretChat: isPrivateChat || isSecretChat
    readonly property bool isGroup: isBasicGroup || isSuperGroup

    readonly property bool isSavedMessages: isPrivateOrSecretChat && chatUserOrGroupId == myUserId

    readonly property bool canGetMembers: ("can_get_members" in groupFullInformation) && groupFullInformation.can_get_members
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
    property var chatPartnerProfilePhotos:([])
    property bool chatPartnerProfilePhotosRequested
    property var groupInformation: chatManager.groupInfo
    property var groupFullInformation: ({})

    property bool fullInfoReady: false
    readonly property string username: isPrivateOrSecretChat ?
                                  (privateChatUserInformation.usernames.editable_username ? "@"+privateChatUserInformation.usernames.editable_username : "")
                                : ((groupInformation && groupInformation.usernames && groupInformation.usernames.editable_username)
                                   ? "@"+groupInformation.usernames.editable_username : "")

//    property alias membersList: membersList

    ChatManagerLoader {
        id: chatManagerLoader
        parent: chatInformationPage
    }

    onStatusChanged: {
        switch(status) {
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
        source: Qt.resolvedUrl("../components/chatInformationPage/ChatInformationPageContent.qml");
    }

}
