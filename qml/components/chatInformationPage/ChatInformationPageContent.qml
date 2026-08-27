//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import '..'
import '../tdlib'
import '../../js/twemoji.js' as Emoji
import '../../js/functions.js' as Functions
import '../../js/debug.js' as Debug


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
        if (!chatInformationPage.isBasicGroup || chatInformationPage.groupInformation.id !== groupId)
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
                  isSupergroup, groupInformation ? groupInformation.id : '', groupId)
        if(isSupergroup && groupInformation.id === groupId) {
            chatInformationPage.groupFullInformation = groupFullInfo
            fullInfoReady = true
        }
    }

    function handleUserFullInfo(userId, info) {
        if (chatInformationPage.isPrivateOrSecretChat && userId === chatInformationPage.userInformation.id) {
            userFullInformation = info
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
        onUserIsMemberChanged: if (!chatInformationPage.userIsMember) {
                                   var page = pageStack.previousPage(chatInformationPage)
                                   if (page.objectName === 'chatPage' && page.chatId == chatId)
                                       page = pageStack.previousPage(page)
                                   pageStack.pop(page)
                               }
    }

    Component.onCompleted: {
        switch (chatInformation.type['@type']) {
        case 'chatTypePrivate':
        case 'chatTypeSecret':
            tdLibWrapper.getUserFullInfo(chatInformationPage.chatUserOrGroupId)
            break
        case 'chatTypeBasicGroup':
            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatUserOrGroupId, false)
            break;
        case 'chatTypeSupergroup':
            tdLibWrapper.getGroupFullInfo(chatInformationPage.chatUserOrGroupId, true)
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
                } else
                    tdLibWrapper.joinChat(chatInformationPage.chatInformation.id, isChannel)
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
            onClicked: pageStack.replace(Qt.resolvedUrl("../../pages/ChatPage.qml"),
                                            {chatId: groupFullInformation.linked_chat_id})
        }
        MenuItem {
            visible: isPrivateOrSecretChat && !isSavedMessages && !isBot
            text: userInformation.is_contact ? qsTr("Edit contact") : qsTr("Add to contacts")
            onClicked: pageStack.push(Qt.resolvedUrl("../../dialogs/AddContactDialog.qml"),
                                    {
                                        userId: userInformation.id,
                                        note: noteEditArea.editText,
                                        needPhoneNumberPrivacyException: userFullInformation.need_phone_number_privacy_exception,
                                        requestFullInfo: false
                                    })
        }
        MenuItem {
            visible: NO_HARBOUR_COMPLIANCE && isPrivateOrSecretChat && (userFullInformation.has_private_calls || userFullInformation.can_be_called)
            text: qsTr("Call")
            onClicked:
                if (userFullInformation.has_private_calls)
                    appNotification.show(qsTr("Unfortunately, you cannot call %1 because of their privacy settings. You can ask them to modify their setting or to call you instead").arg(headerItem.title))
                else
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
                accentColorId: chatManager.accentColorId
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
                                    pageStack.push(Qt.resolvedUrl("../../pages/ProfilePicturesPage.qml"), {userId: userInformation.id})
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


            var status = Functions.getChatPartnerStatusText(userInformation.status['@type'], userInformation.status.was_online, userInformation.is_support, chatInformationPage.chatUserOrGroupId)
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
                    text: chatId
                    font.pixelSize: Theme.fontSizeSmall
                    color: copyIdMouseArea.pressed ? palette.secondaryHighlightColor : palette.highlightColor
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
                    id: titleEditArea
                    visible: canEdit
                    canEdit: !chatInformationPage.isPrivateOrSecretChat && chatInformationPage.groupInformation.status && (chatInformationPage.groupInformation.status.can_change_info  || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator")
                    headerText: qsTr("Chat Title", "group title header")
                    text: chatInformationPage.chatInformation.title

                    onSaveButtonClicked:
                        if (!editItem.errorHighlight)
                            tdLibWrapper.setChatTitle(chatInformationPage.chatInformation.id, textValue);
                        else isEditing = true

                    onTextEdited:
                        if (textValue.length > 0 && textValue.length < 129) {
                            editItem.errorHighlight = false
                            editItem.label = editItem.placeholderText = ''
                        } else {
                            editItem.label = qsTr("Enter 1-%Ln characters", '', 128)
                            editItem.placeholderText = editItem.label
                            editItem.errorHighlight = true
                        }
                }
                InformationEditArea {
                    canEdit: isSavedMessages || titleEditArea.canEdit
                    emptyPlaceholderText: qsTr("There is no information text available, yet.")
                    headerText: qsTr("Info", "group or user infotext header")
                    multiLine: true
                    text: (chatInformationPage.isPrivateOrSecretChat ? Functions.enhanceMessageText(userFullInformation.bio, false) : chatInformationPage.groupFullInformation.description) || ""
                    onSaveButtonClicked:
                        if (chatInformationPage.isPrivateOrSecretChat) // own bio
                            tdLibWrapper.setBio(textValue)
                        else tdLibWrapper.setChatDescription(chatInformationPage.chatInformation.id, textValue) // group
                }

                InformationTextItem {
                    headerText: qsTr("Phone Number", "user phone number header")
                    text: (chatInformationPage.isPrivateOrSecretChat && userInformation.phone_number ? "+"+userInformation.phone_number : "") || ""
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
                    property var birthdate: chatInformationPage.isPrivateOrSecretChat && !!userFullInformation.birthdate ?
                                                new Date(
                                                    userFullInformation.birthdate.year,
                                                    userFullInformation.birthdate.month-1, // 0-11 months index in js, 1-12 in tdlib
                                                    userFullInformation.birthdate.day
                                                    ) : null
                    text: birthdate ? Format.formatDate(birthdate, userFullInformation.birthdate.year ? Formatter.DateMedium : Formatter.DateMediumWithoutYear) : ''
                    // TODO: edit
                }

                InformationEditArea {
                    id: noteEditArea
                    visible: isPrivateOrSecretChat && !isSavedMessages && !!userFullInformation.note
                    headerText: qsTr("Note (only visible to you)")
                    text: visible ? Emoji.emojify(utilities.enhanceMessageText(userFullInformation.note)) : ''
                    multiLine: true
                    editText: utilities.enhanceMessageText(tdLibWrapper.getMarkdownText(userFullInformation.note), true, false)
                    onSaveButtonClicked:
                        tdLibWrapper.setUserNote(userInformation.id, utilities.newFormattedText(textValue))
                    onTextEdited: {
                        var maxLength = tdData.options.user_note_text_length_max
                        if (textValue.length <= maxLength) {
                            editItem.description = ''
                            editItem.errorHighlight = false
                        } else {
                            editItem.description = qsTr("Enter 0-%Ln characters", '', maxLength)
                            editItem.errorHighlight = true
                        }
                    }
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

            NotificationsSwitch {
                visible: !isSavedMessages
                chatId: chatInformation.id
                settings: chatInformation.notification_settings
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
                active: !!(userFullInformation && userFullInformation.personal_chat_id)
                sourceComponent: TDLibChatListItem {
                    chatId: userFullInformation.personal_chat_id
                    compact: false
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
                color: palette.primaryColor
                horizontalAlignment: Qt.AlignHCenter
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                opacity: (tabViewLoader.status === Loader.Ready && tabViewLoader.item.count > 0) ? 1.0 : 0.0

                Behavior on opacity { FadeAnimator {}}
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
