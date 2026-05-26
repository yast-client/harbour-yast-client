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

    function scrollUp(force) {
        if (force)
            // animation does not always work while quick scrolling
            scrollUpTimer.start()
        else
            scrollUpAnimation.start()
    }
    function scrollDown(force) {
        if (force)
            scrollDownTimer.start()
        else
            scrollDownAnimation.start()
    }

    function handleGroupMembers(members, clearFirst) {
        clearFirst = typeof clearFirst !== 'undefined' ? clearFirst : true
        if (clearFirst)
            membersList.clear()

        if (members && members.length > 0) {
            for (var i=0; i < members.length; i++)
                membersList.append(members[i])
        }
    }

    function handleGroupsInCommon(chatIds, totalCount) {
        groupsInCommonList.totalCount = totalCount
        for (var i=0; i < chatIds.length; i++)
            groupsInCommonList.append({chatId: chatIds[i]})
    }

    function handleBasicGroupFullInfo(groupFullInfo, groupId) {
        if (!chatInformationPage.isBasicGroup || chatInformationPage.chatUserOrGroupId !== groupId)
            return
        chatInformationPage.groupFullInformation = groupFullInfo
        fullInfoReady = true
        handleGroupMembers(groupFullInfo.members)
        if (groupFullInfo.members) {
            chatInformationPage.groupInformation.member_count = groupFullInformation.members.length
            chatInformationPage.groupInformationChanged()
        }
    }

    function handleSupergroupFullInfo(groupId, groupFullInfo, updated) {
        Debug.log(updated ? "onSupergroupFullInfoUpdated" : "onSupergroupFullInfoReceived",
                  chatInformationPage.isSupergroup, chatInformationPage.chatUserOrGroupId, groupId)
        if(chatInformationPage.isSupergroup && chatInformationPage.chatUserOrGroupId === groupId) {
            chatInformationPage.groupFullInformation = groupFullInfo
            fullInfoReady = true
        }
    }

    function handleUserFullInfo(userId, userFullInfo) {
        if (chatInformationPage.isPrivateOrSecretChat && userId === chatInformationPage.chatUserOrGroupId) {
            chatInformationPage.chatPartnerFullInformation = userFullInfo
            fullInfoReady = true
        }
    }

    Connections {
        target: tdLibWrapper

        onChatOnlineMemberCountUpdated:
            if (chatInformationPage.isGroup && chatInformationPage.chatInformation.id === chatId)
                chatInformationPage.chatOnlineMemberCount = onlineMemberCount

        onSupergroupFullInfoReceived: handleSupergroupFullInfo(groupId, groupFullInfo, false)
        onSupergroupFullInfoUpdated: handleSupergroupFullInfo(groupId, groupFullInfo, true)
        onBasicGroupFullInfoReceived: handleBasicGroupFullInfo(groupFullInfo, groupId)
        onBasicGroupFullInfoUpdated: handleBasicGroupFullInfo(groupFullInfo, groupId)

        onUserFullInfoReceived: handleUserFullInfo(userId, userFullInfo)
        onUserFullInfoUpdated: handleUserFullInfo(userId, userFullInfo)
    }

    Connections {
        ignoreUnknownSignals: true
        target: chatInformationPage.status === PageStatus.Active ? chatInformationPage : null
        onUserIsMemberChanged: if (!chatInformationPage.userIsMember)
                                   pageStack.pop(pageStack.find(function(page){ return(page._depth === 0)}))
    }

    Component.onCompleted: {
        switch (chatInformation.type['@type']) {
        case 'chatTypePrivate':
        case 'chatTypeSecret':
            if (chatInformation.type['@type'] === 'chatTypeSecret')
                chatInformationPage.isSecretChat = true
            else
                chatInformationPage.isPrivateChat = true
            chatInformationPage.chatUserOrGroupId = chatInformationPage.chatInformation.type.user_id
            if (!chatInformationPage.privateChatUserInformation.id)
                chatInformationPage.privateChatUserInformation = tdLibWrapper.getUserInformation(chatInformationPage.chatUserOrGroupId)
            tdLibWrapper.getUserFullInfo(chatInformationPage.chatUserOrGroupId)
            break
        case 'chatTypeBasicGroup':
            chatInformationPage.isBasicGroup = true
            chatInformationPage.chatUserOrGroupId = chatInformation.type.basic_group_id
            if (!chatInformationPage.groupInformation.id)
                chatInformationPage.groupInformation = tdLibWrapper.getBasicGroup(chatInformationPage.chatUserOrGroupId)
            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatUserOrGroupId, false)
            break;
        case 'chatTypeSupergroup':
            chatInformationPage.isSupergroup = true
            chatInformationPage.chatUserOrGroupId = chatInformation.type.supergroup_id
            if (!chatInformationPage.groupInformation.id)
                chatInformationPage.groupInformation = tdLibWrapper.getSuperGroup(chatInformationPage.chatUserOrGroupId)
            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatUserOrGroupId, true)
            chatInformationPage.isChannel = chatInformationPage.groupInformation.is_channel
            break;
        }
        Debug.log("is set up", chatInformationPage.isPrivateChat, chatInformationPage.isSecretChat, chatInformationPage.isBasicGroup, chatInformationPage.isSupergroup, chatInformationPage.chatUserOrGroupId)

        isInitialized = true
    }

    ListModel { id: membersList }
    ListModel {
        id: groupsInCommonList
        property int totalCount
    }

    PullDownMenu {
        MenuItem {
            visible: (chatInformationPage.isSupergroup || chatInformationPage.isBasicGroup) && chatInformationPage.groupInformation && chatInformationPage.groupInformation.status["@type"] !== "chatMemberStatusBanned"
            text: chatInformationPage.userIsMember ? qsTr("Leave Chat") : qsTr("Join Chat")
            onClicked: {
                // ensure it's done even if the page is closed:
                if (chatInformationPage.userIsMember) {
                    var chatId = chatInformationPage.chatInformation.id;
                    Remorse.popupAction(chatInformationPage, qsTr("Left chat"), function() { tdLibWrapper.leaveChat(chatId) })
                } else {
                    tdLibWrapper.joinChat(chatInformationPage.chatInformation.id);
                }
            }
        }
        MenuItem {
            visible: chatInformationPage.isPrivateChat
            onClicked: {
                tdLibWrapper.createNewSecretChat(chatInformationPage.chatUserOrGroupId, "openDirectly");
            }
            text: qsTr("New Secret Chat")
        }
        MenuItem {
            visible: isSupergroup && groupFullInformation.linked_chat_id !== 0
            text: isChannel ? qsTr("View discussion") : qsTr("View linked channel")
            onClicked: pageStack.replace(Qt.resolvedUrl("../../pages/ChatPage.qml"), {
                                          chatInformation: tdLibWrapper.getChat(groupFullInformation.linked_chat_id)
                                      })
        }
        MenuItem {
            visible: NO_HARBOUR_COMPLIANCE && isPrivateOrSecretChat
            text: qsTr("Call")
            onClicked:
                callsManager.createCall(chatInformation.id)
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

            property real thumbnailRadius: imageContainer.minDimension / 2

            function getEased(min,max,factor) {
                return min + (max-min)*factor
            }
            width: getEased(minDimension,maxDimension, tweenFactor)
            height: width
            x: getEased(minX,maxX, tweenFactor)
            y: getEased(minY,maxY, tweenFactor)

            ProfileThumbnail {
                id: chatPictureThumbnail
                photoData: imageContainer.hasImage ? chatInformation.photo.small : null
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
                sourceComponent: Component {
                    ProfileThumbnail {
                        id: chatPictureDetail
                        anchors.fill: parent
                        photoData: chatInformation.photo ? chatInformation.photo.big : null
                        replacementStringHint: ""
                        radius: imageContainer.thumbnailRadius
                        optimizeImageSize: false
                        highlighted: profileThumbnailMouseArea.containsPress

                        MouseArea {
                            id: profileThumbnailMouseArea
                            anchors.fill: parent
                            onClicked:
                                if (isPrivateOrSecretChat)
                                    pageStack.push(Qt.resolvedUrl("../../pages/ProfilePicturesPage.qml"), {userId: chatUserOrGroupId})
                                else
                                    pageStack.push(Qt.resolvedUrl("../../pages/ChatPhotosPage.qml"), {chatManager: chatManager})
                        }
                    }
                }
            }
        }
        leftMargin: imageContainer.getEased((imageContainer.minDimension + Theme.paddingMedium), 0, imageContainer.tweenFactor) + Theme.horizontalPageMargin
        title: chatInformationPage.chatInformation.title !== "" ? Emoji.emojify(chatInformationPage.chatInformation.title, Theme.fontSizeLarge) : qsTr("Unknown")
        description: {
            if (chatInformationPage.isGroup)
                return Functions.getGroupStatusText(chatInformationPage.groupInformation.member_count, isChannel, chatInformationPage.chatOnlineMemberCount)


            var status = Functions.getChatPartnerStatusText(chatInformationPage.privateChatUserInformation.status['@type'], chatInformationPage.privateChatUserInformation.status.was_online, chatInformationPage.privateChatUserInformation.is_support, chatInformationPage.chatUserOrGroupId)
            /*if (chatInformationPage.secretChatDetails) { // TODO
                var secretChatStatus = Functions.getSecretChatStatus(chatPage.secretChatDetails)
                if (status && secretChatStatus)
                    status += " - "
                if (secretChatStatus)
                    status += secretChatStatus
            }*/
            return status
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
            bottomPadding: tabViewLoader.active ? 0 : Theme.paddingLarge
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
                    text: chatInformationPage.chatUserOrGroupId
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
                    canEdit: (chatInformationPage.isPrivateOrSecretChat && chatInformationPage.privateChatUserInformation.id === chatInformationPage.myUserId) || ((chatInformationPage.isBasicGroup || chatInformationPage.isSupergroup) && chatInformationPage.groupInformation && (chatInformationPage.groupInformation.status.can_change_info || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator"))
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
                        text: chatInformationPage.username
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

            ListItem {
                id: notificationsItem
                visible: !isSavedMessages
                contentHeight: notificationsSwitch.height

                highlighted: notificationsSwitch.down || menuOpen
                _backgroundColor: 'transparent'
                openMenuOnPressAndHold: false

                TextSwitch {
                    id: notificationsSwitch
                    text: qsTr("Notifications")
                    highlighted: notificationsSwitch.highlighted

                    readonly property var settings: chatInformation.notification_settings
                    readonly property var scope: tdLibWrapper.getChatNotificationSettingsScope(chatInformation.id)
                    property var scopeSettings: tdLibWrapper.scopeNotificationSettings(scope)
                    readonly property int muteFor: (settings.use_default_mute_for ? scopeSettings : settings).mute_for

                    Connections {
                        target: tdLibWrapper
                        onScopeNotificationSettingsChanged:
                            if (scope === notificationsSwitch.scope)
                                scopeSettings = tdLibWrapper.scopeNotificationSettings(scope)
                    }

                    description: muteFor > 0
                                 ? (muteFor > 31622400
                                    ? qsTr("Muted") : qsTr("Muted for %1").arg(Format.formatDuration(muteFor)))
                                 : qsTr("Unmuted")

                    checked: muteFor == 0
                    automaticCheck: false

                    onClicked: {
                        busy = true
                        Functions.toggleChatIsMuted(chatInformation.id, settings)
                    }
                    onCheckedChanged: busy = false
                    onPressAndHold: notificationsItem.openMenu()
                }

                menu: ChatNotificationsContextMenu {
                    chatId: chatInformation.id
                    notificationSettings: chatInformation.notification_settings
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
                active: !!(chatInformationPage.chatPartnerFullInformation && chatInformationPage.chatPartnerFullInformation.personal_chat_id)
                sourceComponent: TDLibChatListItem {
                    chatId: chatInformationPage.chatPartnerFullInformation.personal_chat_id
                    showSeparator: false
                    doReplace: true
                }
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
            active: isInitialized && fullInfoReady
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
