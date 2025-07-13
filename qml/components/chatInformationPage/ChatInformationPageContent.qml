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
import "../"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug


SilicaFlickable {
    id: pageContent
    property alias membersList: membersList

    function scrollUp(force) {
        if(force) {
            // animation does not always work while quick scrolling
            scrollUpTimer.start()
        } else {
            scrollUpAnimation.start()
        }
    }
    function scrollDown(force) {
        if(force) {
            scrollDownTimer.start()
        } else {
            scrollDownAnimation.start()
        }
    }
    function handleBasicGroupFullInfo(groupFullInfo, groupId) {
        if(!chatInformationPage.isBasicGroup || chatInformationPage.chatPartnerGroupId !== groupId) return
        chatInformationPage.groupFullInformation = groupFullInfo;
        membersList.clear();
        if(groupFullInfo.members && groupFullInfo.members.length > 0) {
            for(var memberIndex in groupFullInfo.members) {
                var memberData = groupFullInfo.members[memberIndex];
                var userInfo = tdLibWrapper.getUserInformation(memberData.member_id.user_id) || {user:{}, bot_info:{}};
                memberData.user = userInfo;
                memberData.bot_info = memberData.bot_info || {};
                membersList.append(memberData);
            }
            chatInformationPage.groupInformation.member_count = groupFullInfo.members.length
            updateGroupStatusText();
        }
    }
    function updateGroupStatusText() {
        if (chatInformationPage.chatOnlineMemberCount > 0) {
            headerItem.description = qsTr("%1, %2", "combination of '[x members], [y online]', which are separate translations")
                .arg(qsTr("%1 members", "", chatInformationPage.groupInformation.member_count)
                    .arg(Functions.getShortenedCount(chatInformationPage.groupInformation.member_count)))
                .arg(qsTr("%1 online", "", chatInformationPage.chatOnlineMemberCount)
                    .arg(Functions.getShortenedCount(chatInformationPage.chatOnlineMemberCount)));
        } else {
            if (isChannel) {
                headerItem.description = qsTr("%1 subscribers", "", chatInformationPage.groupInformation.member_count).arg(Functions.getShortenedCount(chatInformationPage.groupInformation.member_count))
            } else {
                headerItem.description = qsTr("%1 members", "", chatInformationPage.groupInformation.member_count).arg(Functions.getShortenedCount(chatInformationPage.groupInformation.member_count))
            }
        }
    }

    Connections {
        target: tdLibWrapper

        onUserUpdated: {
            if ((chatInformationPage.isPrivateChat || chatInformationPage.isSecretChat) && chatInformationPage.privateChatUserInformation.id.toString() === userId) {
                chatInformationPage.privateChatUserInformation = userInformation
            }
        }
        onBasicGroupUpdated: {
            if (chatInformationPage.isBasicGroup && chatInformationPage.groupInformation.id === groupId) {
                chatInformationPage.groupInformation = tdLibWrapper.getBasicGroup(groupId)
            }
        }
        onSuperGroupUpdated: {
            if (chatInformationPage.isSuperGroup && chatInformationPage.groupInformation.id === groupId) {
                chatInformationPage.groupInformation = tdLibWrapper.getSuperGroup(groupId)
            }
        }

        onChatOnlineMemberCountUpdated: {
            if ((chatInformationPage.isSuperGroup || chatInformationPage.isBasicGroup) && chatInformationPage.chatInformation.id.toString() === chatId) {
                chatInformationPage.chatOnlineMemberCount = onlineMemberCount;
                updateGroupStatusText();
            }
        }
        onSupergroupFullInfoReceived: {
            Debug.log("onSupergroupFullInfoReceived", chatInformationPage.isSuperGroup, chatInformationPage.chatPartnerGroupId, groupId)
            if(chatInformationPage.isSuperGroup && chatInformationPage.chatPartnerGroupId === groupId) {
                chatInformationPage.groupFullInformation = groupFullInfo
            }
        }
        onSupergroupFullInfoUpdated: {
            Debug.log("onSupergroupFullInfoUpdated", chatInformationPage.isSuperGroup, chatInformationPage.chatPartnerGroupId, groupId)
            if(chatInformationPage.isSuperGroup && chatInformationPage.chatPartnerGroupId === groupId) {
                chatInformationPage.groupFullInformation = groupFullInfo
            }
        }
        onBasicGroupFullInfoReceived: handleBasicGroupFullInfo(groupFullInfo, groupId)
        onBasicGroupFullInfoUpdated: handleBasicGroupFullInfo(groupFullInfo, groupId)

        onUserFullInfoReceived: {
            if(chatInformationPage.isPrivateOrSecretChat && userFullInfo["@extra"] === chatInformationPage.chatPartnerGroupId) {
                chatInformationPage.chatPartnerFullInformation = userFullInfo
            }
        }
        onUserFullInfoUpdated: {
            if(chatInformationPage.isPrivateOrSecretChat && userId === chatInformationPage.chatPartnerGroupId) {
                chatInformationPage.chatPartnerFullInformation = userFullInfo
            }
        }

        onUserProfilePhotosReceived: {
            if(chatInformationPage.isPrivateOrSecretChat && extra === chatInformationPage.chatPartnerGroupId) {
                chatInformationPage.chatPartnerProfilePhotos = photos
            }
        }
        onChatPermissionsUpdated: {
            if (chatInformationPage.chatInformation.id.toString() === chatId) {
                // set whole object to trigger change
                var newInformation = chatInformation;
                newInformation.permissions = permissions
                chatInformationPage.chatInformation = newInformation
            }
        }
        onChatTitleUpdated: {
            if (chatInformationPage.chatInformation.id.toString() === chatId) {
                // set whole object to trigger change
                var newInformation = chatInformation;
                newInformation.title = title
                chatInformationPage.chatInformation = newInformation
            }
        }
        onChatNotificationSettingsUpdated: {
            if (chatInformationPage.chatInformation.id.toString() === chatId) {
                // set whole object to trigger change
                var newInformation = chatInformation;
                newInformation.notification_settings = chatNotificationSettings;
                chatInformationPage.chatInformation = newInformation;
            }
        }
    }

    Connections {
        id: destructiveChatActionConnection
        property var pendingChatId
        ignoreUnknownSignals: true
        target: (chatInformationPage.status === PageStatus.Active && typeof pendingChatId !== 'undefined') ? tdLibWrapper : undefined
        onOkReceived: if (request == "leaveChat:"+pendingChatId)
                          pageStack.pop(pageStack.find(function(page){ return(page._depth === 0)}))
        //onErrorReceived: if (extra == "leaveChat:"+pendingChatId)
        //                     pendingChatId = undefined
    }

    Component.onCompleted: {
        membersList.clear()
        switch(chatInformation.type["@type"]) {
        case "chatTypePrivate":
            chatInformationPage.isPrivateChat = true;
            chatInformationPage.chatPartnerGroupId = chatInformationPage.chatInformation.type.user_id.toString();
            if(!chatInformationPage.privateChatUserInformation.id) {
                chatInformationPage.privateChatUserInformation = tdLibWrapper.getUserInformation(chatInformationPage.chatPartnerGroupId);
            }
            tdLibWrapper.getUserFullInfo(chatInformationPage.chatPartnerGroupId);
            tdLibWrapper.getUserProfilePhotos(chatInformationPage.chatPartnerGroupId, 100, 0);
            break;
        case "chatTypeSecret":
            chatInformationPage.isSecretChat = true;
            chatInformationPage.chatPartnerGroupId = chatInformationPage.chatInformation.type.user_id.toString();
            if(!chatInformationPage.privateChatUserInformation.id) {
                chatInformationPage.privateChatUserInformation = tdLibWrapper.getUserInformation(chatInformationPage.chatPartnerGroupId);
            }
            tdLibWrapper.getUserFullInfo(chatInformationPage.chatPartnerGroupId);
            tdLibWrapper.getUserProfilePhotos(chatInformationPage.chatPartnerGroupId, 100, 0);
            break;
        case "chatTypeBasicGroup":
            chatInformationPage.isBasicGroup = true;
            chatInformationPage.chatPartnerGroupId = chatInformation.type.basic_group_id.toString();
            if(!chatInformationPage.groupInformation.id) {
                chatInformationPage.groupInformation = tdLibWrapper.getBasicGroup(chatInformationPage.chatPartnerGroupId);
            }
            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatPartnerGroupId, false);
            break;
        case "chatTypeSupergroup":
            chatInformationPage.isSuperGroup = true;
            chatInformationPage.chatPartnerGroupId = chatInformation.type.supergroup_id.toString();
            if(!chatInformationPage.groupInformation.id) {
                chatInformationPage.groupInformation = tdLibWrapper.getSuperGroup(chatInformationPage.chatPartnerGroupId);
            }

            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatPartnerGroupId, true);
            chatInformationPage.isChannel = chatInformationPage.groupInformation.is_channel;
            break;
        }
        Debug.log("is set up", chatInformationPage.isPrivateChat, chatInformationPage.isSecretChat, chatInformationPage.isBasicGroup, chatInformationPage.isSuperGroup, chatInformationPage.chatPartnerGroupId)
        if(!chatInformationPage.isPrivateOrSecretChat) {
            updateGroupStatusText()
        }


        tabViewLoader.active = true
    }

    ListModel {
        id: membersList
    }

    PullDownMenu {
        MenuItem {
            visible: (chatInformationPage.isSuperGroup || chatInformationPage.isBasicGroup) && chatInformationPage.groupInformation && chatInformationPage.groupInformation.status["@type"] !== "chatMemberStatusBanned"
            text: chatInformationPage.userIsMember ? qsTr("Leave Chat") : qsTr("Join Chat")
            onClicked: {
                // ensure it's done even if the page is closed:
                if (chatInformationPage.userIsMember) {
                    var chatId = chatInformationPage.chatInformation.id;
                    Remorse.popupAction(chatInformationPage, qsTr("Left chat"), function() {
                        destructiveChatActionConnection.pendingChatId = chatInformation.id
                        tdLibWrapper.leaveChat(chatId)
                    })
                } else {
                    tdLibWrapper.joinChat(chatInformationPage.chatInformation.id);
                }
            }
        }
        MenuItem {
            visible: chatInformationPage.userIsMember
            onClicked: {
                var newNotificationSettings = chatInformationPage.chatInformation.notification_settings;
                if (newNotificationSettings.mute_for > 0) {
                    newNotificationSettings.mute_for = 0;
                } else {
                    newNotificationSettings.mute_for = 6666666;
                }
                newNotificationSettings.use_default_mute_for = false;
                tdLibWrapper.setChatNotificationSettings(chatInformationPage.chatInformation.id, newNotificationSettings);
            }
            text: chatInformation.notification_settings.mute_for > 0 ? qsTr("Unmute Chat") : qsTr("Mute Chat")
        }
        MenuItem {
            visible: chatInformationPage.isPrivateChat
            onClicked: {
                tdLibWrapper.createNewSecretChat(chatInformationPage.chatPartnerGroupId, "openDirectly");
            }
            text: qsTr("New Secret Chat")
        }
        MenuItem {
            visible: isSuperGroup && groupFullInformation.linked_chat_id !== 0
            text: isChannel ? qsTr("View discussion") : qsTr("View linked channel")
            onClicked: pageStack.replace(Qt.resolvedUrl("../../pages/ChatPage.qml"), {
                                          chatInformation: tdLibWrapper.getChat(groupFullInformation.linked_chat_id)
                                      })
        }
    }
    // header
    PageHeader {
        id: headerItem
        z: 5
        Item {
            id: imageContainer
            property bool hasImage: typeof chatInformationPage.chatInformation.photo !== "undefined"
            property int minDimension: chatInformationPage.isLandscape ? Theme.itemSizeSmall : Theme.itemSizeMedium
            property int maxDimension: Screen.width / 2
            property int minX: Theme.horizontalPageMargin
            property int maxX: (chatInformationPage.width - maxDimension)/2
            property int minY: Theme.paddingMedium
            property int maxY: parent.height
            property double tweenFactor: {
                if(!hasImage) {
                    return 0
                }
                return 1 - Math.max(0, Math.min(1, contentFlickable.contentY / maxDimension))
            }
            property bool thumbnailVisible: imageContainer.tweenFactor > 0.8
            property bool thumbnailActive: imageContainer.tweenFactor === 1.0
            property var thumbnailModel: chatInformationPage.chatPartnerProfilePhotos
            property int thumbnailRadius: imageContainer.minDimension / 2

            function getEased(min,max,factor) {
                return min + (max-min)*factor
            }
            width: getEased(minDimension,maxDimension, tweenFactor)
            height: width
            x: getEased(minX,maxX, tweenFactor)
            y: getEased(minY,maxY, tweenFactor)

            ProfileThumbnail {
                id: chatPictureThumbnail
                photoData: imageContainer.hasImage ? chatInformationPage.chatInformation.photo.small : ""
                replacementStringHint: headerItem.title
                width: parent.width
                height: width
                radius: imageContainer.thumbnailRadius
                opacity: profilePictureLoader.status !== Loader.Ready || profilePictureLoader.item.opacity < 1 ? 1.0 : 0.0
                optimizeImageSize: false
            }

            Loader {
                id: profilePictureLoader
                active: imageContainer.hasImage
                asynchronous: true
                anchors.fill: chatPictureThumbnail
                source: chatInformationPage.isPrivateOrSecretChat
                        ? "../ProfilePictureList.qml"
                        : "ChatInformationProfilePicture.qml"
            }
        }
        leftMargin: imageContainer.getEased((imageContainer.minDimension + Theme.paddingMedium), 0, imageContainer.tweenFactor) + Theme.horizontalPageMargin
        title: chatInformationPage.chatInformation.title !== "" ? Emoji.emojify(chatInformationPage.chatInformation.title, Theme.fontSizeLarge) : qsTr("Unknown")
        description: chatInformationPage.username

        MouseArea {
            parent: headerItem._descriptionLabel
            anchors.fill: parent
            enabled: !!headerItem.description && headerItem.description === chatInformationPage.username
            onClicked: {
                Clipboard.text = chatInformationPage.username
                appNotification.show(qsTr("Username has been copied to the clipboard"))
            }
        }
    }

    SilicaFlickable {
        id: contentFlickable
        contentHeight: groupInfoItem.height + tabViewLoader.height
        clip: true
        interactive: !scrollUpAnimation.running && !scrollDownAnimation.running

        anchors {
            top: headerItem.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        NumberAnimation {
            id: scrollDownAnimation
            target: contentFlickable
            to: groupInfoItem.height
            property: "contentY"
            duration: 500
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            id: scrollUpAnimation
            target: contentFlickable
            to: 0
            property: "contentY"
            duration: 500
            easing.type: Easing.InOutCubic
            property Timer scrollUpTimer: Timer {
                id: scrollUpTimer
                interval: 50
                onTriggered: {
                    contentFlickable.scrollToTop()
                }
            }
            property Timer scrollDownTimer: Timer {
                id: scrollDownTimer
                interval: 50
                onTriggered: {
                    contentFlickable.scrollToBottom()
                }
            }
        }

        Column {
            id: groupInfoItem
            bottomPadding: Theme.paddingLarge
            topPadding: Theme.paddingLarge
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                Item { //large image placeholder
                    width: parent.width
                    height: imageContainer.hasImage ? imageContainer.maxDimension : 0
                }

                Label {
                    id: copyIdText
                    x: Math.max(headerItem.x + imageContainer.x - parent.x + (imageContainer.width - width)/2, 0)
                    text: chatInformationPage.chatPartnerGroupId
                    font.pixelSize: Theme.fontSizeSmall
                    color: copyIdMouseArea.pressed ? Theme.secondaryHighlightColor : Theme.highlightColor
                    visible: text !== ""

                    MouseArea {
                        id: copyIdMouseArea
                        anchors {
                            fill: parent
                            margins: -Theme.paddingLarge
                        }
                        onClicked: {
                            Clipboard.text = copyIdText.text
                            appNotification.show(qsTr("ID has been copied to the clipboard."));
                        }
                    }
                }

                InformationEditArea {
                    visible: canEdit
                    canEdit: !chatInformationPage.isPrivateOrSecretChat && chatInformationPage.groupInformation.status && (chatInformationPage.groupInformation.status.can_change_info  || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator")
                    headerText: qsTr("Chat Title", "group title header")
                    text: chatInformationPage.chatInformation.title

                    onSaveButtonClicked: {
                        if(!editItem.errorHighlight) {
                            tdLibWrapper.setChatTitle(chatInformationPage.chatInformation.id, textValue);
                        } else {
                            isEditing = true
                        }
                    }

                    onTextEdited: {
                        if(textValue.length > 0 && textValue.length < 129) {
                            editItem.errorHighlight = false
                            editItem.label = ""
                            editItem.placeholderText = ""
                        } else {
                            editItem.label = qsTr("Enter 1-128 characters")
                            editItem.placeholderText = editItem.label
                            editItem.errorHighlight = true
                        }
                    }
                }
                InformationEditArea {
                    canEdit: (chatInformationPage.isPrivateOrSecretChat && chatInformationPage.privateChatUserInformation.id === chatInformationPage.myUserId) || ((chatInformationPage.isBasicGroup || chatInformationPage.isSuperGroup) && chatInformationPage.groupInformation && (chatInformationPage.groupInformation.status.can_change_info || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator"))
                    emptyPlaceholderText: qsTr("There is no information text available, yet.")
                    headerText: qsTr("Info", "group or user infotext header")
                    multiLine: true
                    text: (chatInformationPage.isPrivateOrSecretChat ? Functions.enhanceMessageText(chatInformationPage.chatPartnerFullInformation.bio, false) : chatInformationPage.groupFullInformation.description) || ""
                    onSaveButtonClicked: {
                        if (chatInformationPage.isPrivateOrSecretChat) { // own bio
                            tdLibWrapper.setBio(textValue)
                        } else { // group info
                            tdLibWrapper.setChatDescription(chatInformationPage.chatInformation.id, textValue)
                        }
                    }
                }

                InformationTextItem {
                    headerText: qsTr("Phone Number", "user phone number header")
                    text: (chatInformationPage.isPrivateOrSecretChat && chatInformationPage.privateChatUserInformation.phone_number ? "+"+chatInformationPage.privateChatUserInformation.phone_number : "") || ""
                    isLinkedLabel: true
                }

                BackgroundItem {
                    height: contentHeight
                    contentHeight: usernameItem.height
                    visible: !!usernameItem.text
                    _showPress: false

                    InformationTextItem {
                        id: usernameItem
                        highlight: true
                        headerText: qsTr("Username", "header")
                        text: headerItem.description != chatInformationPage.username ? chatInformationPage.username : ""
                    }
                    onClicked: {
                        Clipboard.text = usernameItem.text
                        appNotification.show(qsTr("Username has been copied to the clipboard"))
                    }
                }

                InformationTextItem {
                    headerText: qsTr("Date of birth")
                    property var birthdate: chatInformationPage.isPrivateOrSecretChat && !!chatInformationPage.chatPartnerFullInformation.birthdate ?
                                                new Date(
                                                    chatInformationPage.chatPartnerFullInformation.birthdate.year,
                                                    chatInformationPage.chatPartnerFullInformation.birthdate.month-1, // 0-11 months index in js, 1-12 in tdlib
                                                    chatInformationPage.chatPartnerFullInformation.birthdate.day
                                                    ) : null
                    text: birthdate ? Format.formatDate(birthdate, chatInformationPage.chatPartnerFullInformation.birthdate.year ? Formatter.DateMedium : Formatter.DateMediumWithoutYear) : ''
                    // TODO: edit
                }

                SectionHeader {
                    font.pixelSize: Theme.fontSizeExtraSmall
                    visible: !!inviteLinkItem.text
                    height: visible ? Theme.itemSizeExtraSmall : 0
                    text: qsTr("Invite Link", "header")
                    x: 0
                }

                Row {
                    width: parent.width
                    visible: !!inviteLinkItem.text
                    InformationTextItem {
                        id: inviteLinkItem
                        text: !chatInformationPage.isPrivateOrSecretChat ? chatInformationPage.groupFullInformation.invite_link.invite_link : ""
                        width: parent.width - inviteLinkButton.width
                    }
                    IconButton {
                        id: inviteLinkButton
                        icon.source: "image://theme/icon-m-clipboard"
                        anchors.verticalCenter: inviteLinkItem.verticalCenter
                        onClicked: {
                            Clipboard.text = chatInformationPage.groupFullInformation.invite_link.invite_link
                            appNotification.show(qsTr("The Invite Link has been copied to the clipboard."))
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
                visible: personalChatLoader.active
            }

            Loader {
                id: personalChatLoader
                width: parent.width
                asynchronous: true
                height: item ? item.height : 0
                sourceComponent: Item {
                    id: foundChatListDelegate
                    width: parent.width
                    height: foundChatListItem.height

                    property bool setupCompleted
                    property var foundChatInformation: tdLibWrapper.getChat(chatInformationPage.chatPartnerFullInformation.personal_chat_id)
                    property var relatedInformation
                    property bool isPrivateChat: false
                    property bool isBasicGroup: false
                    property bool isSupergroup: false

                    function detectChatType() {
                        if (setupCompleted || !foundChatInformation || !foundChatInformation.type) return;
                        setupCompleted = true
                        switch (foundChatInformation.type["@type"]) {
                        case "chatTypePrivate":
                            relatedInformation = tdLibWrapper.getUserInformation(foundChatInformation.type.user_id);
                            foundChatListItem.prologSecondaryText.text = qsTr("Private Chat");
                            foundChatListItem.secondaryText.text = "@" + ( relatedInformation.username !== "" ? relatedInformation.username : relatedInformation.user_id );
                            tdLibWrapper.getUserFullInfo(foundChatInformation.type.user_id);
                            isPrivateChat = true;
                            break;
                        case "chatTypeBasicGroup":
                            relatedInformation = tdLibWrapper.getBasicGroup(foundChatInformation.type.basic_group_id);
                            foundChatListItem.prologSecondaryText.text = qsTr("Group");
                            tdLibWrapper.getGroupFullInfo(foundChatInformation.type.basic_group_id, false);
                            isBasicGroup = true;
                            break;
                        case "chatTypeSupergroup":
                            relatedInformation = tdLibWrapper.getSuperGroup(foundChatInformation.type.supergroup_id);
                            if (relatedInformation.is_channel) {
                                foundChatListItem.prologSecondaryText.text = qsTr("Channel");
                            } else {
                                foundChatListItem.prologSecondaryText.text = qsTr("Group");
                            }
                            tdLibWrapper.getGroupFullInfo(foundChatInformation.type.supergroup_id, true);
                            isSupergroup = true;
                            break;
                        }
                    }

                    Component.onCompleted: detectChatType()
                    onFoundChatInformationChanged: detectChatType()

                    Connections {
                        target: tdLibWrapper
                        onUserFullInfoUpdated: {
                            if (foundChatListDelegate.isPrivateChat && userId.toString() === foundChatListDelegate.foundChatInformation.type.user_id.toString()) {
                                foundChatListItem.tertiaryText.text = Emoji.emojify(userFullInfo.bio, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }
                        onUserFullInfoReceived: {
                            if (foundChatListDelegate.isPrivateChat && userFullInfo["@extra"].toString() === foundChatListDelegate.foundChatInformation.type.user_id.toString()) {
                                foundChatListItem.tertiaryText.text = Emoji.emojify(userFullInfo.bio, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }

                        onBasicGroupFullInfoUpdated: {
                            if (foundChatListDelegate.isBasicGroup && groupId.toString() === foundChatListDelegate.foundChatInformation.type.basic_group_id.toString()) {
                                foundChatListItem.secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                                foundChatListItem.tertiaryText.text = Emoji.emojify(groupFullInfo.description, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }
                        onBasicGroupFullInfoReceived: {
                            if (foundChatListDelegate.isBasicGroup && groupId.toString() === foundChatListDelegate.foundChatInformation.type.basic_group_id.toString()) {
                                foundChatListItem.secondaryText.text = qsTr("%1 members", "", groupFullInfo.members.length).arg(Number(groupFullInfo.members.length).toLocaleString(Qt.locale(), "f", 0));
                                foundChatListItem.tertiaryText.text = Emoji.emojify(groupFullInfo.description, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }

                        onSupergroupFullInfoUpdated: {
                            if (foundChatListDelegate.isSupergroup && groupId.toString() === foundChatListDelegate.foundChatInformation.type.supergroup_id.toString()) {
                                if (foundChatListDelegate.relatedInformation.is_channel) {
                                    foundChatListItem.secondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                                } else {
                                    foundChatListItem.secondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                                }
                                foundChatListItem.tertiaryText.text = Emoji.emojify(groupFullInfo.description, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }
                        onSupergroupFullInfoReceived: {
                            if (foundChatListDelegate.isSupergroup && groupId.toString() === foundChatListDelegate.foundChatInformation.type.supergroup_id.toString()) {
                                if (foundChatListDelegate.relatedInformation.is_channel) {
                                    foundChatListItem.secondaryText.text = qsTr("%1 subscribers", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                                } else {
                                    foundChatListItem.secondaryText.text = qsTr("%1 members", "", groupFullInfo.member_count).arg(Number(groupFullInfo.member_count).toLocaleString(Qt.locale(), "f", 0));
                                }
                                foundChatListItem.tertiaryText.text = Emoji.emojify(groupFullInfo.description, foundChatListItem.tertiaryText.font.pixelSize, "../js/emoji/");
                            }
                        }
                    }

                    PhotoTextsListItem {
                        id: foundChatListItem

                        pictureThumbnail.photoData: typeof foundChatInformation.photo.small !== "undefined" ? foundChatInformation.photo.small : {}
                        width: parent.width
                        showSeparator: false

                        primaryText.text: Emoji.emojify(foundChatInformation.title, primaryText.font.pixelSize, "../js/emoji/")
                        tertiaryText.maximumLineCount: 1

                        onClicked: pageStack.replace(Qt.resolvedUrl("../../pages/ChatPage.qml"), {chatInformation: foundChatInformation})
                    }
                }

                // for some reason, when the loader is disabled by default, connections don't work; thus we only disable it later
                Component.onCompleted: active = !!chatInformationPage.chatPartnerFullInformation && !!chatInformationPage.chatPartnerFullInformation.personal_chat_id
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
                horizontalAlignment: Qt.AlignHCenter
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                opacity: (tabViewLoader.status === Loader.Ready && tabViewLoader.item.count > 0) ? 1.0 : 0.0

                Behavior on opacity { FadeAnimation {}}
            }
        }

        Loader {
            id: tabViewLoader
            asynchronous: true
            active: false
            anchors {
                left: parent.left
                right: parent.right
                top: groupInfoItem.bottom
            }
            sourceComponent: Component {
                ChatInformationTabView {
                    id: tabView
                    height: tabView.count > 0 ? chatInformationPage.height - headerItem.height : 0
                }
            }
        }
    }
}
