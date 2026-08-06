//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/chat"
import "../js/debug.js" as Debug
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Page {
    objectName: 'chatPage'
    id: chatPage
    allowedOrientations: Orientation.All
    backNavigation: !messagesView || !messagesView.stickerPickerLoader.active

    property bool earlyInitialized
    property bool isInitialized
    property alias chatManager: chatManagerLoader.chatManager
    readonly property var chatInformation: chatManager.chatInformation
    property alias chatId: chatManagerLoader.chatId
    readonly property var secretChatDetails: chatManager.secretChatInfo
    property bool isPrivateChat: chatManagerLoader.chatManager.chatType === TDLibAPI.ChatTypePrivate
    property bool isSecretChat: chatManager.chatType === TDLibAPI.ChatTypeSecret
    property bool isSecretChatReady: chatPage.secretChatDetails && chatPage.secretChatDetails.state['@type'] === 'secretChatStateReady'
    property bool isBasicGroup: chatManager.chatType === TDLibAPI.ChatTypeBasicGroup
    property bool isSupergroup: chatManager.chatType === TDLibAPI.ChatTypeSupergroup
    property bool isChannel: chatManager.isChannel
    property bool isBot: chatManager.isBot
    property bool viewAsTopics: chatManager.viewAsTopics
    property bool isDeletedUser: !!chatPartnerInformation && chatPartnerInformation.type['@type'] === "userTypeDeleted"
    property var chatPartnerInformation: chatManager.userInfo
    property var botInformation
    property var chatGroupInformation: chatManager.groupInfo
    property int chatOnlineMemberCount: 0
    property var topicIdToShow
    property var messageIdToShow
    readonly property bool isSavedMessages: chatId === tdData.myUserId
    readonly property bool userIsMember: ((isPrivateChat || isSecretChat) &&
                                          chatInformation["@type"] &&
                                          !isSavedMessages) || // should be optimized
                                (isBasicGroup || isSupergroup) && (
                                    (chatGroupInformation.status["@type"] === "chatMemberStatusMember")
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusAdministrator")
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusRestricted" && chatGroupInformation.status.is_member)
                                    || (chatGroupInformation.status["@type"] === "chatMemberStatusCreator" && chatGroupInformation.status.is_member)
                                    )
    readonly property bool canSendMessages: hasSendPrivilege("can_send_basic_messages")
    property bool doSendBotStartMessage
    property string sendBotStartMessageParameter
    property bool timepointStatus

    readonly property MessagesView messagesView: viewAsTopics ? null : contentLoader.item
    readonly property TopicsListView topicsListView: viewAsTopics ? contentLoader.item : null

    ChatManagerLoader {
        id: chatManagerLoader
        parent: chatPage
        onReady: initializeChatManager()
        onInfoInitialized: initializeChatManager()
    }

    function log() {
        var a = Array.prototype.slice.call(arguments)
        a.splice(0,0,'[ChatPage] '+chatId)
        Debug.log.apply(console, a)
    }

    function getChatTitle(fontSize) {
        return chatPage.isDeletedUser ? qsTr("Deleted User") :
                                        chatInformation.title !== "" ?
                                            Emoji.emojify(utilities.fixReservedHtmlCharacters(chatInformation.title), fontSize)
                                          : qsTr("Unknown")
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
            headerDescription: qsTr("Forward %Ln messages", "dialog header", ids.length),
            payload: {fromChatId: chatId, messageIds:ids, neededPermissions: neededPermissions},
            state: "forwardMessages"
        })
    }

    function forwardMessages(fromChatId, messageIds) {
        if (viewAsTopics) {
            topicsListView.forwardFromChatId = fromChatId
            topicsListView.forwardMessageIds = messageIds
        } else
            messagesView.forwardMessages(fromChatId, messageIds)
    }

    function hasGroupPermission(memberPermission, adminPermission) {
        if ((!isBasicGroup && !isSupergroup) || !chatGroupInformation || !chatGroupInformation.status)
            return false

        switch (chatGroupInformation.status['@type']) {
        case 'chatMemberStatusCreator':
            return true
        case 'chatMemberStatusAdministrator':
            return adminPermission ? chatGroupInformation.status.rights[adminPermission] : true
        case 'chatMemberStatusMember':
            return chatManager.permissions[memberPermission]
        case 'chatMemberStatusRestricted':
            return chatGroupInformation.status.permissions[memberPermission]
        default:
            return false
        }
    }
    function hasSendPrivilege(privilege) {
        return isPrivateChat || (isSecretChat && isSecretChatReady) || hasGroupPermission(privilege)
    }

    function resetFocus() {
        if (searchInChatField.text === "")
            searchInChatItem.visible = false
        searchInChatField.focus = false
        chatPage.focus = true
    }

    // TODO: close when chat is deleted
    // left the chat, even if from another device; this follows the behaviour in Telegram Desktop
    onUserIsMemberChanged:
        if (chatManager.infoInitialized && !userIsMember)
            pageStack.pop(pageStack.previousPage(chatPage))

    Timer {
        id: searchInChatTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            Debug.log("Searching for '" + searchInChatField.text + "'")
            chatManager.model.searchQuery = searchInChatField.text
        }
    }

    Component.onDestruction: {
        tdLibWrapper.closeChat(chatId)
        if (notificationManager.activeChatId === chatId)
            notificationManager.activeChatId = 0
    }

    function initializeChatManager() {
        if (!chatManager || !chatManager.infoInitialized || isInitialized)
            return
        log("Initializing chat manager")

        if (!earlyInitialized && (status == PageStatus.Activating || status == PageStatus.Active)) {
            earlyInitialized = true

            if ((isPrivateChat || isSecretChat) && chatPartnerInformation.type["@type"] === "userTypeBot")
                tdLibWrapper.getUserFullInfo(chatId)
            tdLibWrapper.toggleChatIsMarkedAsUnread(chatId, false)

            if (messagesView) messagesView.prepareView()
        }

        if (status == PageStatus.Active) {
            isInitialized = true

            // From tests, the following line doesn't take more than 20 milliseconds, so for now we initialize this here:
            // The real issue might be that since it initializes early, UI also needs to be initialized earlier, so it could actually lag a bit
            // So, TBD if it's best to move it up or keep it here
            // also to move this up we need to not depend on isInitialized, because otherwise the code here won't ever run at all
            chatManager.initializeMainModels(messageIdToShow)

            if (topicIdToShow)
                switch (topicIdToShow['@type']) {
                case 'messageTopicForum':
                    if (topicsListView)
                        topicsListView.openAtTopicId(topicIdToShow.forum_topic_id)
                    break
                }

            pageStack.pushAttached(Qt.resolvedUrl("ChatInformationPage.qml"), {
                                       chatManager: chatManager,
                                       chatOnlineMemberCount: chatOnlineMemberCount
                                   })
            if (doSendBotStartMessage)
                tdLibWrapper.sendBotStartMessage(chatId, chatId, sendBotStartMessageParameter, "")
            notificationManager.activeChatId = chatId
        }
    }

    onStatusChanged:
        initializeChatManager()

    Connections {
        target: tdLibWrapper
        onChatOnlineMemberCountUpdated: {
            Debug.log(isSupergroup, "/", isBasicGroup, "/", chatPage.chatId, "/", chatId);
            if ((isSupergroup || isBasicGroup) && chatPage.chatId === chatId)
                chatOnlineMemberCount = onlineMemberCount
        }

        onCallbackQueryAnswer: {
            if (text.length > 0) // ignore bool "alert", just show as notification:
                appNotification.show(Emoji.emojify(text, Theme.fontSizeSmall))
            if (url.length > 0)
                utilities.handleLink(url)
        }
        onUserFullInfoReceived:
            if ((isPrivateChat || isSecretChat) && userId === chatId)
                chatPage.botInformation = userFullInfo.bot_info
        onUserFullInfoUpdated:
            if ((isPrivateChat || isSecretChat) && userId === chatId)
                chatPage.botInformation = userFullInfo.bot_info
    }

    Timer {
        id: chatContactTimeUpdater
        interval: 60000
        running: isPrivateChat || isSecretChat
        repeat: true
        onTriggered: chatHeader.updateStatusText()
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
                // TODO: saved messages topics
                // TODO: maybe use Opal Tabs for tabbed forums (perhaps actually implement that joke post with side tabs)
                visible: /*isSavedMessages ||*/ (isSupergroup && chatGroupInformation.is_forum && !chatGroupInformation.has_forum_tabs)
                text: viewAsTopics ? qsTr("View as Messages", "view a forum chat in full chat mode") : qsTr("View as Topics", "view a forum chat as topics")
                onClicked:
                    tdLibWrapper.toggleChatViewAsTopics(chatId, !viewAsTopics)

                rightPadding: viewAsTopics ? 0 : forumTopicsBetaIndicator.width + Theme.paddingLarge
                TextBadge {
                    id: forumTopicsBetaIndicator
                    visible: !viewAsTopics
                    anchors.verticalCenter: parent.verticalCenter
                    x: (parent.width + parent.contentWidth - width)/2
                    border.color: Theme.highlightColor
                    textColor: Theme.highlightColor
                    text: "BETA"
                }
            }

            MenuItem {
                visible: chatPage.isPrivateChat
                onClicked: {
                    var privateChatId = chatId
                    Remorse.popupAction(chatPage, qsTr("Chat deleted"), function() { tdLibWrapper.deleteChat(privateChatId) }, 10000)
                }
                text: qsTr("Delete chat")
            }

            MenuItem {
                visible: chatPage.isSecretChat && chatPage.secretChatDetails.state["@type"] !== "secretChatStateClosed"
                onClicked: {
                    var secretChatId = chatPage.secretChatDetails.id
                    Remorse.popupAction(chatPage, qsTr("Secret chat closed"), function() { tdLibWrapper.closeSecretChat(secretChatId) })
                }
                text: qsTr("Close secret chat")
            }

            MenuItem {
                visible: (chatPage.isSupergroup || chatPage.isBasicGroup) && chatGroupInformation && chatGroupInformation.status["@type"] !== "chatMemberStatusBanned"
                onClicked: {
                    if (chatPage.userIsMember) {
                        var chatId = chatInformation.id
                        Remorse.popupAction(chatPage, isChannel ? qsTr("Left the channel") : qsTr("Left the group"), function() { tdLibWrapper.leaveChat(chatId) })
                    } else
                        tdLibWrapper.joinChat(chatId, isChannel)
                }
                text: chatPage.userIsMember
                        ? (isChannel ? qsTr("Leave channel") : qsTr("Leave group"))
                        : (isChannel ? qsTr("Join channel") : qsTr("Join group"))
            }

            MenuItem {
                visible: chatPage.userIsMember
                text: Functions.getMuteButtonTitle(tdData.chatIsMuted(chatId, chatInformation.notification_settings), chatInformation.notification_settings, highlighted)
                onClicked: Functions.toggleChatIsMuted(chatId, chatInformation.notification_settings)
            }

            MenuItem {
                visible: !chatPage.isSecretChat && !chatPage.viewAsTopics && !searchInChatItem.visible
                onClicked: {
                    // This automatically shows the search field as well
                    searchInChatItem.visible = true
                    searchInChatField.focus = true
                }
                text: qsTr("Search in Chat")
            }
        }

        Column {
            id: chatColumn
            width: parent.width
            height: parent.height

            Item {
                width: parent.width
                height: chatHeader.height

                ChatHeader {
                    id: chatHeader

                    property bool connecting: tdLibWrapper.connectionState != TDLibAPI.ConnectionReady

                    isSecret: chatPage.isSecretChat
                    chatNameText.text: getChatTitle(chatNameText.font.pixelSize)
                    pictureThumbnail.photoData: chatManager.photo.small
                    chatBadges.verificationStatus: chatGroupInformation ? chatGroupInformation.verification_status : null

                    property bool _reloadStatus
                    function updateStatusText() { _reloadStatus = !_reloadStatus }
                    chatStatusText.text: {
                        // https://stackoverflow.com/questions/48325115/qml-programmatically-update-binding
                        if (_reloadStatus && !_reloadStatus) return ''

                        if (connecting) return tdLibWrapper.connectionStateText

                        if (!viewAsTopics) {
                            var chatActionsText = chatManager.chatActionsText
                            if (chatActionsText)
                                return chatActionsText
                        }

                        if (isBasicGroup || isSupergroup)
                            return Functions.getGroupStatusText(chatGroupInformation.member_count, isChannel, chatOnlineMemberCount)

                        var status = Functions.getChatPartnerStatusText(chatPartnerInformation.status['@type'], chatPartnerInformation.status.was_online, chatPartnerInformation.is_support, chatId, timepointStatus)
                        if (chatPage.secretChatDetails) {
                            var secretChatStatus = Functions.getSecretChatStatus(chatPage.secretChatDetails)
                            if (status && secretChatStatus)
                                status += " - "
                            if (secretChatStatus)
                                status += secretChatStatus
                        }
                        return status
                    }

                    chatActionIcon {
                        type: connecting ? TDLibAPI.Cancel : chatManager.chatMainActionType
                        actionProgress: chatManager.chatActionsProgress
                    }
                    chatStatusText.highlighted: !connecting && (chatHeader.highlighted || (!viewAsTopics && chatManager.chatActionsText)
                                                || (chatPartnerInformation && chatPartnerInformation.status && chatPartnerInformation['@type'] === 'userStatusOnline'))
                    //chatStatusText.isError: tdLibWrapper.connectionState != TDLibAPI.ConnectionReady

                    onClicked: {
                        if (messagesView && messagesView.isSelecting)
                            messagesView.selectedMessages = []
                        else pageStack.navigateForward()
                    }
                    onPressAndHold:
                        if (isPrivateChat || isSecretChat)
                            timepointStatus = !timepointStatus

                    textContainer.visible: !searchInChatField.visible
                }

                Item {
                    id: searchInChatItem
                    parent: chatHeader.container
                    width: chatHeader.textContainer.width
                    anchors {
                        bottom: parent.bottom
                        //bottomMargin: chatHeader.textContainer.anchors.bottomMargin
                    }
                    height: searchInChatField.height
                    visible: false
                    opacity: visible ? 1 : 0
                    Behavior on opacity { FadeAnimation {} }

                    SearchField {
                        id: searchInChatField
                        visible: false
                        width: visible ? parent.width : 0
                        placeholderText: qsTr("Search in chat")
                        active: searchInChatItem.visible
                        canHide: text === ""

                        onTextChanged: searchInChatTimer.restart()
                        onHideClicked: resetFocus()

                        EnterKey.iconSource: "image://theme/icon-m-enter-close"
                        EnterKey.onClicked: resetFocus()
                    }
                }
            }

            ChatBotSponsoredMessageItem {
                id: chatBotSponsoredMessageItem
                width: parent.width
                message: chatManager.botSponsoredMessage
                chatId: chatPage.chatId
            }

            ChatPendingJoinRequestsItem {
                id: pendingJoinRequestsItem
                width: parent.width
                pendingJoinRequests: chatManager.pendingJoinRequests
                chatId: chatPage.chatId
            }

            Loader {
                id: contentLoader
                width: parent.width
                height: chatColumn.height - chatHeader.height - chatBotSponsoredMessageItem.height - pendingJoinRequestsItem.height
                active: chatManager && chatManager.infoInitialized
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
