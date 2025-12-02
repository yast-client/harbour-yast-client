import QtQuick 2.0
import App.Logic 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

PhotoTextsListItem {
    id: chatItem
    width: parent.width

    property var chatId
    property bool doReplace

    property var chatInformation: tdLibWrapper.getChat(chatId)
    property var relatedInformation
    property bool isPrivateChat
    property bool isBasicGroup
    property bool isSupergroup
    property bool isSecret

    function detectChatType() {
        switch (chatInformation.type["@type"]) {
        case "chatTypePrivate":
        case "chatTypeSecret":
            relatedInformation = tdLibWrapper.getUserInformation(chatInformation.type.user_id);
            if (chatInformation.type["@type"] == 'chatTypeSecret')
                isSecret = true
            else isPrivateChat = true
            prologSecondaryText.text = isSecret ? qsTr("Secret Chat") : qsTr("Private Chat");
            secondaryText.text = "@" + (relatedInformation.usernames && relatedInformation.usernames.editable_username !== "" ? relatedInformation.usernames.editable_username : relatedInformation.id);
            tdLibWrapper.getUserFullInfo(chatInformation.type.user_id);
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

    Component.onCompleted: detectChatType()
    onChatInformationChanged: detectChatType()

    Connections {
        target: tdLibWrapper
        onUserFullInfoUpdated: {
            if ((isPrivateChat || isSecret) && userId.toString() === chatInformation.type.user_id.toString()) {
                tertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), tertiaryText.font.pixelSize);
            }
        }
        onUserFullInfoReceived: {
            if ((isPrivateChat || isSecret) && userFullInfo["@extra"].toString() === chatInformation.type.user_id.toString()) {
                tertiaryText.text = Emoji.emojify(Functions.enhanceMessageText(userFullInfo.bio), tertiaryText.font.pixelSize);
            }
        }

        onBasicGroupFullInfoUpdated: {
            if (isBasicGroup && groupId.toString() === chatInformation.type.basic_group_id.toString()) {
                secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize);
            }
        }
        onBasicGroupFullInfoReceived: {
            if (isBasicGroup && groupId.toString() === chatInformation.type.basic_group_id.toString()) {
                secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize);
            }
        }

        onSupergroupFullInfoUpdated: {
            if (isSupergroup && groupId.toString() === chatInformation.type.supergroup_id.toString()) {
                if (relatedInformation.is_channel) {
                    secondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                } else {
                    secondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                }
                tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize);
            }
        }
        onSupergroupFullInfoReceived: {
            if (isSupergroup && groupId.toString() === chatInformation.type.supergroup_id.toString()) {
                if (relatedInformation.is_channel) {
                    secondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                } else {
                    secondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                }
                tertiaryText.text = Emoji.emojify(groupFullInfo.description, tertiaryText.font.pixelSize);
            }
        }
    }

    pictureThumbnail.photoData: typeof chatInformation.photo.small !== "undefined" ? chatInformation.photo.small : {}

    primaryText.text: Emoji.emojify(chatInformation.title, primaryText.font.pixelSize)
    tertiaryText.maximumLineCount: 1

    onClicked: {
        (doReplace ? pageStack.replace : pageStack.push)(Qt.resolvedUrl("../pages/ChatPage.qml"), {chatInformation: chatInformation})
    }
}
