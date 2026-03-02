import QtQuick 2.0
import App.Logic 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

PhotoTextsListItem {
    id: chatItem
    width: parent.width

    property var chatId
    property var userId: chatInformation.type.user_id
    property bool doReplace

    property var chatInformation: tdLibWrapper.getChat(chatId)
    property var relatedInformation
    property bool isPrivateChat
    property bool isBasicGroup
    property bool isSupergroup
    property bool isSecret

    function handleUser() {
        relatedInformation = tdLibWrapper.getUserInformation(userId)
        secondaryText.text = "@" + (relatedInformation.usernames && relatedInformation.usernames.editable_username !== "" ? relatedInformation.usernames.editable_username : relatedInformation.id)
    }
    function handleBasicGroup() {
        relatedInformation = tdLibWrapper.getBasicGroup(chatInformation.type.basic_group_id)
    }
    function handleSupergroup() {
        relatedInformation = tdLibWrapper.getSuperGroup(chatInformation.type.supergroup_id)
        prologSecondaryText.text = relatedInformation.is_channel ? qsTr("Channel") : qsTr("Group")
    }

    function detectChatType() {
        if (!chatId && userId) {
            isPrivateChat = true
            prologSecondaryText.text = qsTr("Private Chat")
            handleUser()
            tdLibWrapper.getUserFullInfo(userId)
            return
        }

        switch (chatInformation.type["@type"]) {
        case "chatTypePrivate":
        case "chatTypeSecret":
            if (chatInformation.type["@type"] === 'chatTypeSecret')
                isSecret = true
            else isPrivateChat = true
            prologSecondaryText.text = isSecret ? qsTr("Secret Chat") : qsTr("Private Chat")
            handleUser()
            tdLibWrapper.getUserFullInfo(userId)
            break
        case "chatTypeBasicGroup":
            prologSecondaryText.text = qsTr("Group")
            isBasicGroup = true
            handleBasicGroup()
            tdLibWrapper.getGroupFullInfo(chatInformation.type.basic_group_id, false)
            break
        case "chatTypeSupergroup":
            isSupergroup = true
            handleSupergroup()
            tdLibWrapper.getGroupFullInfo(chatInformation.type.supergroup_id, true)
            break;
        }
    }

    Component.onCompleted: detectChatType()
    onChatInformationChanged: detectChatType()

    function handleUserFullInfo(userId, userFullInfo) {
        if ((isPrivateChat || isSecret) && userId === chatItem.userId)
            tertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), tertiaryText.font.pixelSize)
    }

    function handleBasicGroupFullInfo(groupId, groupFullInfo) {
        if (isBasicGroup && groupId === chatInformation.type.basic_group_id) {
            secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0))
            tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize)
        }
    }

    function handleSupergroupFullInfo(groupId, groupFullInfo) {
        if (isSupergroup && groupId === chatInformation.type.supergroup_id) {
            secondaryText.text = Functions.getGroupStatusText(groupFullInfo.member_count, relatedInformation.is_channel, 0, true)
            tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize)
        }
    }

    Connections {
        target: tdLibWrapper

        onChatRolesUpdated:
            if (chatId === chatItem.chatId)
                chatInformation = tdLibWrapper.getChat(chatId)

        onUserUpdated:
            if ((isPrivateChat || isSecret) && userId === chatItem.userId)
                handleUser()
        // We don't need to handle group updates for now (but if we do later, these can be restored)
        /*onBasicGroupUpdated:
            if (isBasicGroup && groupId === chatInformation.type.basic_group_id)
                handleBasicGroup()
        onSupergroupUpdated:
            if (isSupergroup && groupId === chatInformation.type.supergroup_id)
                handleSupergroup()*/

        onUserFullInfoUpdated: handleUserFullInfo(userId, userFullInfo)
        onUserFullInfoReceived: handleUserFullInfo(userId, userFullInfo)

        onBasicGroupFullInfoUpdated: handleBasicGroupFullInfo(groupId, groupFullInfo)
        onBasicGroupFullInfoReceived: handleBasicGroupFullInfo(groupId, groupFullInfo)

        onSupergroupFullInfoUpdated: handleSupergroupFullInfo(groupId, groupFullInfo)
        onSupergroupFullInfoReceived: handleSupergroupFullInfo(groupId, groupFullInfo)
    }

    pictureThumbnail.photoData: chatId
                                ? (typeof chatInformation.photo.small !== 'undefined' ? chatInformation.photo.small : {})
                                : (isPrivateChat && relatedInformation && relatedInformation.profile_photo ? relatedInformation.profile_photo.small : {})

    primaryText.text: Emoji.emojify(chatInformation.title || (isPrivateChat ? Functions.getUserName(relatedInformation) : qsTr("Unknown")), primaryText.font.pixelSize)
    tertiaryText.maximumLineCount: 1

    onClicked:
        if (chatId)
            (doReplace ? pageStack.replace : pageStack.push)(Qt.resolvedUrl("../pages/ChatPage.qml"), {chatInformation: chatInformation})
        else if (userId)
            tdLibWrapper.createPrivateChat(userId, "openDirectly")
}
