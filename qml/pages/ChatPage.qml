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
import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../components"
import "../components/chat"
import "../js/debug.js" as Debug
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Page {
    id: chatPage
    allowedOrientations: Orientation.All
    backNavigation: !messagesView || !messagesView.stickerPickerLoader.active

    property bool loading: true
    property bool isInitialized: false
    readonly property int myUserId: tdLibWrapper.getUserInformation().id
    property alias chatManager: chatManagerLoader.chatManager
    property var chatInformation
    property var secretChatDetails
    property alias chatPicture: chatPictureThumbnail.photoData
    property bool isPrivateChat: chatManagerLoader.chatManager.chatType === TDLibAPI.ChatTypePrivate
    property bool isSecretChat: chatManager.chatType === TDLibAPI.ChatTypeSecret
    property bool isSecretChatReady: false
    property bool isBasicGroup: chatManager.chatType === TDLibAPI.ChatTypeBasicGroup
    property bool isSuperGroup: chatManager.chatType === TDLibAPI.ChatTypeSupergroup
    property bool isChannel: !!(chatGroupInformation && chatGroupInformation.is_channel)
    property bool viewAsTopics: chatManager.viewAsTopics
    property bool isDeletedUser: !!chatPartnerInformation && chatPartnerInformation.type['@type'] === "userTypeDeleted"
    property var chatPartnerInformation: chatManager.userInfo
    property var botInformation
    property var chatGroupInformation: chatManager.groupInfo
    property int chatOnlineMemberCount: 0
    property var messageToShow
    property string messageIdToShow
    readonly property bool userIsMember: ((isPrivateChat || isSecretChat) &&
                                          chatInformation["@type"] &&
                                          chatInformation.id !== chatPage.myUserId) || // should be optimized
                                (isBasicGroup || isSuperGroup) && (
                                    (chatGroupInformation.status["@type"] === "chatMemberStatusMember")
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusAdministrator")
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusRestricted" && chatGroupInformation.status.is_member)
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusCreator" && chatGroupInformation.status.is_member)
                                    )
    readonly property bool canSendMessages: hasSendPrivilege("can_send_basic_messages")
    property bool doSendBotStartMessage
    property string sendBotStartMessageParameter
    property var availableReactions
    property bool timepointStatus

    readonly property MessagesView messagesView: viewAsTopics ? null : contentLoader.item
    readonly property TopicsListView topicsListView: viewAsTopics ? contentLoader.item : null

    ChatManagerLoader {
        id: chatManagerLoader
        parent: chatPage
        onReady: initializeChatManager()
    }

    function setMessageText(text, doSend) {
        if (messagesView)
            messagesView.setMessageText(text, doSend)
    }

    function startForwardingMessages(messages) {
        var ids = Functions.getMessagesArrayIds(messages)
        var neededPermissions = Functions.getMessagesNeededForwardPermissions(messages)
        var chatId = chatInformation.id
        pageStack.push(Qt.resolvedUrl("../pages/ChatSelectionPage.qml"), {
            myUserId: chatPage.myUserId,
            headerDescription: qsTr("Forward %Ln messages", "dialog header", ids.length),
            payload: {fromChatId: chatId, messageIds:ids, neededPermissions: neededPermissions},
            state: "forwardMessages"
        })
    }

    function forwardMessages(fromChatId, messageIds) {
        forwardMessagesTimer.fromChatId = fromChatId
        forwardMessagesTimer.messageIds = messageIds
        forwardMessagesTimer.start()
    }
    function hasSendPrivilege(privilege) {
        var groupStatus = chatGroupInformation ? chatGroupInformation.status : null
        var groupStatusType = groupStatus ? groupStatus["@type"] : null
        return chatPage.isPrivateChat
                    || (groupStatusType === "chatMemberStatusMember" && chatInformation.permissions[privilege])
                    || groupStatusType === "chatMemberStatusAdministrator"
                    || groupStatusType === "chatMemberStatusCreator"
                    || (groupStatusType === "chatMemberStatusRestricted" && groupStatus.permissions[privilege])
                    || (chatPage.isSecretChat && chatPage.isSecretChatReady)
    }
    function canPinMessages() {
        Debug.log("Can we pin messages?")
        if (chatPage.isPrivateChat || chatPage.isSecretChat) {
            Debug.log("Private/Secret Chat: No!")
            return false
        }
        if (chatPage.chatGroupInformation.status["@type"] === "chatMemberStatusCreator") {
            Debug.log("Creator of this chat: Yes!")
            return true
        }
        if (chatPage.chatInformation.permissions.can_pin_messages) {
            Debug.log("All people can pin: Yes!")
            return true
        }
        if (chatPage.chatGroupInformation.status["@type"] === "chatMemberStatusAdministrator") {
            Debug.log("Admin with privileges? ", chatPage.chatGroupInformation.status.can_pin_messages)
            return chatPage.chatGroupInformation.status.can_pin_messages
        }
        if (chatPage.chatGroupInformation.status["@type"] === "chatMemberStatusRestricted") {
            Debug.log("Restricted, but can pin messages? ", chatPage.chatGroupInformation.status.permissions.can_pin_messages)
            return chatPage.chatGroupInformation.status.permissions.can_pin_messages
        }
        Debug.log("Something else: No!")
        return false
    }

    function resetFocus() {
        if (searchInChatField.text === "")
            chatOverviewItem.visible = true
        searchInChatField.focus = false
        chatPage.focus = true
    }

    // TODO: close when chat is deleted
    // left the chat, even if from another device; this follows the behaviour in Telegram Desktop
    onUserIsMemberChanged: if (chatManager.infoInitialized && !userIsMember)
                               pageStack.pop(pageStack.find(function(page){ return(page._depth === 0)}))

    Timer {
        id: forwardMessagesTimer
        interval: 200

        property string fromChatId
        property var messageIds
        onTriggered: {
            if(chatPage.loading)
                forwardMessagesTimer.start()
            else
                tdLibWrapper.forwardMessages(chatInformation.id, fromChatId, messageIds, isSecretChat /* forwardedToSecretChat */, false)
        }
    }

    Timer {
        id: searchInChatTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            Debug.log("Searching for '" + searchInChatField.text + "'")
            chatManager.model.setSearchQuery(searchInChatField.text)
        }
    }

    Component.onCompleted: {
        Debug.log("[ChatPage] Initializing chat page...")

        if (isSecretChat)
            tdLibWrapper.getSecretChat(chatInformation.type.secret_chat_id)
        if (isPrivateChat || isSecretChat) {
            if(chatPartnerInformation.type["@type"] === "userTypeBot")
                tdLibWrapper.getUserFullInfo(chatPartnerInformation.id)
        }

        if (stickerManager.needsReload()) {
            Debug.log("[ChatPage] Recent stickers will be reloaded!")
            tdLibWrapper.getRecentStickers()
            stickerManager.setNeedsReload(false)
        }
        tdLibWrapper.getChatPinnedMessage(chatInformation.id)
        tdLibWrapper.toggleChatIsMarkedAsUnread(chatInformation.id, false)
        availableReactions = tdLibWrapper.getChatReactions(chatInformation.id)
    }

    Component.onDestruction: {
        tdLibWrapper.closeChat(chatInformation.id)
        if (notificationManager.activeChatId === chatInformation.id)
            notificationManager.activeChatId = 0
    }

    function initializeChatManager() {
        if (!chatManager) return

        switch(status) {
        case PageStatus.Activating:
            tdLibWrapper.openChat(chatInformation.id)
            if(!chatPage.isInitialized) {
                if (messagesView) messagesView.prepareView()
                chatManager.beginInitialization(chatInformation)
            }
            break
        case PageStatus.Active:
            if (!chatPage.isInitialized) {
                chatManager.finishInitialization(chatInformation, messageIdToShow)
                pageStack.pushAttached(Qt.resolvedUrl("ChatInformationPage.qml"), {
                                           chatManager: chatManager,
                                           chatOnlineMemberCount: chatOnlineMemberCount,
                                       })
                if(doSendBotStartMessage)
                    tdLibWrapper.sendBotStartMessage(chatInformation.id, chatInformation.id, sendBotStartMessageParameter, "")
                notificationManager.activeChatId = chatInformation.id
            }
            break
        }
    }

    onStatusChanged:
        initializeChatManager()

    Connections {
        target: tdLibWrapper
        onChatOnlineMemberCountUpdated: {
            Debug.log(isSuperGroup, "/", isBasicGroup, "/", chatInformation.id.toString(), "/", chatId);
            if ((isSuperGroup || isBasicGroup) && chatInformation.id.toString() === chatId) {
                chatOnlineMemberCount = onlineMemberCount
            }
        }

        onSecretChatReceived: {
            if (secretChatId === chatInformation.type.secret_chat_id) {
                Debug.log("[ChatPage] Received detailed information about this secret chat")
                chatPage.secretChatDetails = secretChat
                chatPage.isSecretChatReady = chatPage.secretChatDetails.state["@type"] === "secretChatStateReady"
            }
        }
        onSecretChatUpdated: {
            if (secretChatId.toString() === chatInformation.type.secret_chat_id.toString()) {
                Debug.log("[ChatPage] Detailed information about this secret chat was updated")
                chatPage.secretChatDetails = secretChat
                chatPage.isSecretChatReady = chatPage.secretChatDetails.state["@type"] === "secretChatStateReady"
            }
        }
        onCallbackQueryAnswer: {
            if(text.length > 0) { // ignore bool "alert", just show as notification:
                appNotification.show(Emoji.emojify(text, Theme.fontSizeSmall))
            }
            if(url.length > 0) {
                Functions.handleLink(url)
            }
        }
        onUserFullInfoReceived: {
            if ((isPrivateChat || isSecretChat) && userFullInfo["@extra"] === chatPartnerInformation.id.toString())
                chatPage.botInformation = userFullInfo.bot_info
        }
        onUserFullInfoUpdated: {
            if ((isPrivateChat || isSecretChat) && userId === chatPartnerInformation.id)
                chatPage.botInformation = userFullInfo.bot_info
        }
        onReactionsUpdated: availableReactions = tdLibWrapper.getChatReactions(chatInformation.id)
    }

    Connections {
        target: chatListModel
        onChatJoined:
            appNotification.show(qsTr("You joined the chat %1").arg(chatTitle))
    }

    Timer {
        id: chatContactTimeUpdater
        interval: 60000
        running: isPrivateChat || isSecretChat
        repeat: true
        onTriggered: chatStatusText.update()
    }

    Connections {
        target: chatManager
        onChatInformationChanged:
            // FIXME 2: this if statement shouldn't be needed now because chat manager is loaded along with the page now
            //if (!!chatManager.chatInformation.id) // this is needed for closeChat request and some other stuff
                chatPage.chatInformation = chatManager.chatInformation // FIXME
    }

    SilicaFlickable {
        id: chatContainer

        onContentYChanged:
            // For some strange reason contentY sometimes is > 0 which doesn't make sense without a PushUpMenu (?)
            // That leads to the problem that the whole flickable is moved slightly (or sometimes considerably) up
            // which creates UX issues... As a workaround we are setting it to 0 in such cases.
            // Better solutions are highly appreciated, contributions always welcome! ;)
            if (contentY > 0) contentY = 0

        anchors.fill: parent
        contentHeight: height
        contentWidth: width

        PullDownMenu {
            visible: !messagesView || !messagesView.overlayActive

            MenuItem {
                id: deleteChatMenuItem
                visible: chatPage.isPrivateChat
                onClicked: {
                    var privateChatId = chatInformation.id
                    Remorse.popupAction(chatPage, qsTr("Chat deleted"), function() { tdLibWrapper.deleteChat(privateChatId) }, 10000)
                }
                text: qsTr("Delete Chat")
            }

            MenuItem {
                id: closeSecretChatMenuItem
                visible: chatPage.isSecretChat && chatPage.secretChatDetails.state["@type"] !== "secretChatStateClosed"
                onClicked: {
                    var secretChatId = chatPage.secretChatDetails.id
                    Remorse.popupAction(chatPage, qsTr("Closing chat"), function(){ tdLibWrapper.closeSecretChat(secretChatId) })
                }
                text: qsTr("Close Chat")
            }

            MenuItem {
                id: joinLeaveChatMenuItem
                visible: (chatPage.isSuperGroup || chatPage.isBasicGroup) && chatGroupInformation && chatGroupInformation.status["@type"] !== "chatMemberStatusBanned"
                onClicked: {
                    if (chatPage.userIsMember) {
                        var chatId = chatInformation.id
                        Remorse.popupAction(chatPage, qsTr("Left chat"), function() { tdLibWrapper.leaveChat(chatId) })
                    } else tdLibWrapper.joinChat(chatInformation.id)
                }
                text: chatPage.userIsMember ? qsTr("Leave Chat") : qsTr("Join Chat")
            }

            MenuItem {
                id: muteChatMenuItem
                visible: chatPage.userIsMember
                onClicked: {
                    var newNotificationSettings = chatInformation.notification_settings
                    if (newNotificationSettings.mute_for > 0)
                        newNotificationSettings.mute_for = 0
                    else
                        newNotificationSettings.mute_for = 6666666
                    newNotificationSettings.use_default_mute_for = false
                    tdLibWrapper.setChatNotificationSettings(chatInformation.id, newNotificationSettings)
                }
                text: chatInformation.notification_settings.mute_for > 0 ? qsTr("Unmute Chat") : qsTr("Mute Chat")
            }

            MenuItem {
                id: searchInChatMenuItem
                visible: !chatPage.isSecretChat && !chatPage.viewAsTopics && chatOverviewItem.visible
                onClicked: {
                    // This automatically shows the search field as well
                    chatOverviewItem.visible = false
                    searchInChatField.focus = true
                }
                text: qsTr("Search in Chat")
            }
        }

        Column {
            id: chatColumn
            width: parent.width
            height: parent.height

            BackgroundItem {
                id: header
                height: row.height

                onClicked: {
                    if (messagesView && messagesView.isSelecting)
                        messagesView.selectedMessages = []
                    else pageStack.navigateForward()
                }
                onPressAndHold:
                    if (isPrivateChat || isSecretChat)
                        timepointStatus = !timepointStatus

                Row {
                    id: row
                    width: parent.width - (3 * Theme.horizontalPageMargin)
                    height: chatOverviewItem.height +
                            ( chatPage.isPortrait ?
                                    ( Theme.paddingMedium + (!Screen.hasCutouts ? Theme.paddingMedium : Screen.topCutout.height) )
                                : Theme.paddingSmall * 2
                                )
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium

                    Item {
                        width: chatOverviewItem.height
                        height: chatOverviewItem.height
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: chatPage.isPortrait ? Theme.paddingMedium : Theme.paddingSmall

                        ProfileThumbnail {
                            id: chatPictureThumbnail
                            replacementStringHint: chatNameText.text
                            width: parent.height
                            height: parent.height

                            // Setting it directly may cause an stale state for the thumbnail in case the chat page
                            // was previously loaded with a picture and now it doesn't have one. Instead setting it
                            // when the ChatModel indicates a change. This also avoids flickering when the page is loaded...
                            Connections {
                                target: chatManager
                                ignoreUnknownSignals: true
                                onSmallPhotoChanged:
                                    chatPictureThumbnail.photoData = chatManager.smallPhoto
                            }
                        }

                        Rectangle {
                            id: chatSecretBackground
                            color: Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityFaint)
                            width: chatPage.isPortrait ? Theme.fontSizeLarge : Theme.fontSizeMedium
                            height: width
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            radius: parent.width / 2
                            visible: chatPage.isSecretChat
                        }

                        Image {
                            source: "image://theme/icon-s-secure"
                            width: chatPage.isPortrait ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall
                            height: width
                            anchors.centerIn: chatSecretBackground
                            visible: chatPage.isSecretChat
                        }

                    }

                    Item {
                        id: chatOverviewItem
                        opacity: visible ? 1 : 0
                        Behavior on opacity { FadeAnimation {} }
                        width: parent.width - chatPictureThumbnail.width - Theme.paddingMedium
                        height: chatNameRow.height + chatStatusText.height
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: chatPage.isPortrait ? Theme.paddingMedium : Theme.paddingSmall

                        Row {
                            id: chatNameRow
                            anchors.right: parent.right
                            spacing: Theme.paddingMedium

                            Label {
                                id: chatNameText
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, chatOverviewItem.width - chatBadges.width - parent.spacing)
                                text: chatPage.isDeletedUser ? qsTr("Deleted User") :
                                                      chatInformation.title !== "" ?
                                                          Emoji.emojify(utilities.fixReservedHtmlCharacters(chatInformation.title), font.pixelSize)
                                                        : qsTr("Unknown")
                                textFormat: Text.StyledText
                                font.pixelSize: chatPage.isPortrait ? Theme.fontSizeLarge : Theme.fontSizeMedium
                                font.family: Theme.fontFamilyHeading
                                color: Theme.highlightColor
                                truncationMode: TruncationMode.Fade
                                maximumLineCount: 1
                            }

                            ChatBadges {
                                id: chatBadges
                                anchors.verticalCenter: parent.verticalCenter
                                verificationStatus: chatGroupInformation ? chatGroupInformation.verification_status : null
                            }
                        }

                        Label {
                            id: chatStatusText
                            width: Math.min(implicitWidth, parent.width)
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                            }
                            property bool _reload
                            function update() { _reload = !_reload }
                            text: {
                                // https://stackoverflow.com/questions/48325115/qml-programmatically-update-binding
                                if (_reload && !_reload) return ''

                                var status = Functions.getChatActionsText(chatManager.chatActionsByChats, chatManager.chatActionsByUsers, isPrivateChat || isSecretChat)
                                if (status) return status

                                if (isBasicGroup || isSuperGroup)
                                    return Functions.getGroupStatusText(chatGroupInformation.member_count, chatOnlineMemberCount, isChannel)


                                status = Functions.getChatPartnerStatusText(chatPartnerInformation.status['@type'], chatPartnerInformation.status.was_online, chatPartnerInformation.is_support, chatInformation.id, timepointStatus)
                                if (chatPage.secretChatDetails) {
                                    var secretChatStatus = Functions.getSecretChatStatus(chatPage.secretChatDetails)
                                    if (status && secretChatStatus)
                                        status += " - "
                                    if (secretChatStatus)
                                        status += secretChatStatus
                                }
                                return status
                            }

                            textFormat: Text.StyledText
                            font.pixelSize: chatPage.isPortrait ? Theme.fontSizeExtraSmall : Theme.fontSizeTiny
                            minimumPixelSize: Theme.fontSizeTiny
                            fontSizeMode: Text.Fit
                            font.family: Theme.fontFamilyHeading
                            color: header.pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                            maximumLineCount: 1
                        }
                    }

                    Item {
                        id: searchInChatItem
                        visible: !chatOverviewItem.visible
                        opacity: visible ? 1 : 0
                        Behavior on opacity { FadeAnimation {} }
                        width: parent.width - chatPictureThumbnail.width - Theme.paddingMedium
                        height: searchInChatField.height
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: chatPage.isPortrait ? Theme.paddingSmall : 0

                        SearchField {
                            id: searchInChatField
                            visible: false
                            width: visible ? parent.width : 0
                            placeholderText: qsTr("Search in chat...")
                            active: searchInChatItem.visible
                            canHide: text === ""

                            onTextChanged: searchInChatTimer.restart()
                            onHideClicked: resetFocus()

                            EnterKey.iconSource: "image://theme/icon-m-enter-close"
                            EnterKey.onClicked: resetFocus()
                        }
                    }
                }
            }

            ChatPendingJoinRequestsItem {
                id: pendingJoinRequestsItem
                width: parent.width
                pendingJoinRequests: chatManager.pendingJoinRequests
                chatId: chatInformation.id
            }

            Loader {
                id: contentLoader
                width: parent.width
                height: chatColumn.height - header.height - pendingJoinRequestsItem.height
                sourceComponent: viewAsTopics ? topicsListViewComponent : messagesViewComponent

                Component {
                    id: messagesViewComponent
                    MessagesView {
                        anchors.fill: parent
                    }
                }

                Component {
                    id: topicsListViewComponent
                    TopicsListView {
                        anchors.fill: parent
                    }
                }
            }
        }
    }

    Timer {
        id: doubleTapHintTimer
        running: true
        triggeredOnStart: false
        repeat: false
        interval: 6000
        onTriggered: {
            tapHint.visible = false
            tapHintLabel.visible = false
        }
    }

    TapInteractionHint {
        id: tapHint
        loops: Animation.Infinite
        taps: 2
        anchors.centerIn: parent
        visible: false
    }

    InteractionHintLabel {
        id: tapHintLabel
        anchors.bottom: parent.bottom
        text: qsTr("Double-tap on a message to choose a reaction")
        visible: false
    }
}
