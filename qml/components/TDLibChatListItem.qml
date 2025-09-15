import QtQuick 2.0
import WerkWolf.Fernschreiber 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

PhotoTextsListItem {
    id: chatItem
    width: parent.width

    property var chatId

    // ad: !!sponsoredChats[modelData] // or modelData in sponsoredChats

    property var chatInformation: tdLibWrapper.getChat(chatId)
    property var relatedInformation
    property bool isPrivateChat
    property bool isBasicGroup
    property bool isSupergroup

    Component.onCompleted: {
        switch (chatInformation.type["@type"]) {
        case "chatTypePrivate":
            relatedInformation = tdLibWrapper.getUserInformation(chatInformation.type.user_id);
            prologSecondaryText.text = qsTr("Private Chat");
            secondaryText.text = "@" + (relatedInformation.usernames && relatedInformation.usernames.editable_username !== "" ? relatedInformation.usernames.editable_username : relatedInformation.id);
            tdLibWrapper.getUserFullInfo(chatInformation.type.user_id);
            isPrivateChat = true;
            break;
        case "chatTypeBasicGroup":
            relatedInformation = tdLibWrapper.getBasicGroup(chatInformation.type.basic_group_id);
            prologSecondaryText.text = qsTr("Group");
            tdLibWrapper.getGroupFullInfo(chatInformation.type.basic_group_id, false);
            isBasicGroup = true;
            break;
        case "chatTypeSupergroup":
            relatedInformation = tdLibWrapper.getSuperGroup(chatInformation.type.supergroup_id);
            prologSecondaryText.text = relatedInformation.is_channel ? qsTr("Channel") : qsTr("Group")
            tdLibWrapper.getGroupFullInfo(chatInformation.type.supergroup_id, true);
            isSupergroup = true;
            break;
        }
    }

    Connections {
        target: tdLibWrapper
        onUserFullInfoUpdated: {
            if (chatItem.isPrivateChat && userId.toString() === chatItem.chatInformation.type.user_id.toString()) {
                tertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), tertiaryText.font.pixelSize, "../js/emoji/");
            }
        }
        onUserFullInfoReceived: {
            if (chatItem.isPrivateChat && userFullInfo["@extra"].toString() === chatItem.chatInformation.type.user_id.toString()) {
                chatItemtertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), chatItemtertiaryText.font.pixelSize, "../js/emoji/");
            }
        }

        onBasicGroupFullInfoUpdated: {
            if (chatItem.isBasicGroup && groupId.toString() === chatItem.chatInformation.type.basic_group_id.toString()) {
                chatItemsecondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                chatItemtertiaryText.text = Emoji.emojify(groupFullInfo.description, chatItemtertiaryText.font.pixelSize, "../js/emoji/");
            }
        }
        onBasicGroupFullInfoReceived: {
            if (chatItem.isBasicGroup && groupId.toString() === chatItem.chatInformation.type.basic_group_id.toString()) {
                chatItemsecondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                chatItemtertiaryText.text = Emoji.emojify(groupFullInfo.description, chatItemtertiaryText.font.pixelSize, "../js/emoji/");
            }
        }

        onSupergroupFullInfoUpdated: {
            if (chatItem.isSupergroup && groupId.toString() === chatItem.chatInformation.type.supergroup_id.toString()) {
                if (chatItem.relatedInformation.is_channel) {
                    chatItemsecondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                } else {
                    chatItemsecondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                }
                chatItemtertiaryText.text = Emoji.emojify(groupFullInfo.description, chatItemtertiaryText.font.pixelSize, "../js/emoji/");
            }
        }
        onSupergroupFullInfoReceived: {
            if (chatItem.isSupergroup && groupId.toString() === chatItem.chatInformation.type.supergroup_id.toString()) {
                if (chatItem.relatedInformation.is_channel) {
                    chatItemsecondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                } else {
                    chatItemsecondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                }
                chatItemtertiaryText.text = Emoji.emojify(groupFullInfo.description, chatItemtertiaryText.font.pixelSize, "../js/emoji/");
            }
        }
    }

    pictureThumbnail.photoData: typeof chatInformation.photo.small !== "undefined" ? chatInformation.photo.small : {}

    primaryText.text: Emoji.emojify(chatInformation.title, primaryText.font.pixelSize, "../js/emoji/")
    tertiaryText.maximumLineCount: 1

    onClicked: {
        pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), {chatInformation: chatInformation})
    }
}
