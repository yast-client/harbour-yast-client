//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import io.yaqtlib 1.0
import '..'
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

PhotoTextsListItem {
    id: chatItem
    width: parent.width
    compact: true

    property var messageSender
    property var chatId: messageSender && messageSender['@type'] === 'messageSenderChat' ? messageSender.chat_id : undefined
    property var userId: messageSender && messageSender['@type'] === 'messageSenderUser' ? messageSender.user_id : chatInformation.type.user_id
    property bool openOnClick
    property bool doReplace: true

    property bool showFullInfo: true

    property var chatInformation: tdData.getChat(chatId)
    property var relatedInformation
    property bool isPrivateChat
    property bool isBasicGroup
    property bool isSupergroup
    property bool isSecret

    property bool handleGroupUpdates

    property string chatTypeName: {
        if (isPrivateChat)
            return qsTr("Private Chat")
        if (isSecret)
            qsTr("Secret Chat")
        if (isSupergroup)
            return relatedInformation.is_channel ? qsTr("Channel") : qsTr("Group")
        if (isBasicGroup)
            return qsTr("Group")
        return '' // Loading
    }

    function handleUser() {
        relatedInformation = tdData.getUserInformation(userId)
        if (showFullInfo)
            secondaryText.text = "@" + (relatedInformation.usernames && relatedInformation.usernames.editable_username !== "" ? relatedInformation.usernames.editable_username : relatedInformation.id)
    }
    function handleBasicGroup() {
        relatedInformation = tdData.getBasicGroup(chatInformation.type.basic_group_id)
    }
    function handleSupergroup() {
        relatedInformation = tdData.getSuperGroup(chatInformation.type.supergroup_id)
    }

    function detectChatType() {
        if (!chatId && userId) {
            isPrivateChat = true
            handleUser()
            if (showFullInfo)
                tdLibWrapper.getUserFullInfo(userId)
            return
        }

        switch (chatInformation.type["@type"]) {
        case "chatTypePrivate":
        case "chatTypeSecret":
            if (chatInformation.type["@type"] === 'chatTypeSecret')
                isSecret = true
            else isPrivateChat = true
            handleUser()
            if (showFullInfo)
                tdLibWrapper.getUserFullInfo(userId)
            break
        case "chatTypeBasicGroup":
            isBasicGroup = true
            handleBasicGroup()
            if (showFullInfo)
                tdLibWrapper.getGroupFullInfo(chatInformation.type.basic_group_id, false)
            break
        case "chatTypeSupergroup":
            isSupergroup = true
            handleSupergroup()
            if (showFullInfo)
                tdLibWrapper.getGroupFullInfo(chatInformation.type.supergroup_id, true)
            break;
        }
    }

    Component.onCompleted: detectChatType()
    onChatInformationChanged: detectChatType()

    function handleUserFullInfo(userId, userFullInfo) {
        if (showFullInfo && (isPrivateChat || isSecret) && userId === chatItem.userId)
            tertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), tertiaryText.font.pixelSize)
    }

    function handleBasicGroupFullInfo(groupId, groupFullInfo) {
        if (showFullInfo && isBasicGroup && groupId === chatInformation.type.basic_group_id) {
            secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0))
            tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize)
        }
    }

    function handleSupergroupFullInfo(groupId, groupFullInfo) {
        if (showFullInfo && isSupergroup && groupId === chatInformation.type.supergroup_id) {
            secondaryText.text = Functions.getGroupStatusText(groupFullInfo.member_count, relatedInformation.is_channel, 0, true)
            tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize)
        }
    }

    Connections {
        target: tdData
        onChatRolesUpdated:
            if (chatId === chatItem.chatId)
                chatInformation = tdData.getChat(chatId)

        onUserUpdated:
            if ((isPrivateChat || isSecret) && userId === chatItem.userId)
                handleUser()
    }
    Connections {
        target: handleGroupUpdates ? tdData : null
        ignoreUnknownSignals: true

        onBasicGroupUpdated:
            if (isBasicGroup && groupId === chatInformation.type.basic_group_id)
                handleBasicGroup()
        onSupergroupUpdated:
            if (isSupergroup && groupId === chatInformation.type.supergroup_id)
                handleSupergroup()
    }

    Connections {
        target: tdLibWrapper

        onUserFullInfoUpdated: handleUserFullInfo(userId, userFullInfo)
        onUserFullInfoReceived: handleUserFullInfo(userId, userFullInfo)

        onBasicGroupFullInfoUpdated: handleBasicGroupFullInfo(groupId, groupFullInfo)
        onBasicGroupFullInfoReceived: handleBasicGroupFullInfo(groupId, groupFullInfo)

        onSupergroupFullInfoUpdated: handleSupergroupFullInfo(groupId, groupFullInfo)
        onSupergroupFullInfoReceived: handleSupergroupFullInfo(groupId, groupFullInfo)
    }

    pictureThumbnail {
        accentColorId: (chatId ? chatInformation : relatedInformation).accent_color_id
        photoData: chatId
                   ? (typeof chatInformation.photo.small !== 'undefined' ? chatInformation.photo.small : {})
                   : (isPrivateChat && relatedInformation && relatedInformation.profile_photo ? relatedInformation.profile_photo.small : {})
    }

    primaryText.text: Emoji.emojify(chatInformation.title || (isPrivateChat ? utilities.getUserName(relatedInformation) : qsTr("Unknown")), primaryText.font.pixelSize)
    prologSecondaryText.text: chatTypeName

    tertiaryText.maximumLineCount: 1
    tertiaryText.visible: !compact

    function open() {
        if (chatId)
            (doReplace ? pageStack.replace : pageStack.push)(Qt.resolvedUrl("../../pages/ChatPage.qml"), {chatId: chatId})
        else if (userId)
            tdLibWrapper.createPrivateChat(userId, 'openDirectly')
    }
    onClicked: if (openOnClick) open()
}
