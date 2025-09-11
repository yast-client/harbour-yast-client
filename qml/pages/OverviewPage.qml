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
import Nemo.Notifications 1.0
import WerkWolf.Fernschreiber 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug
import "../modules/Opal/Tabs"

Page {
    id: overviewPage
    allowedOrientations: Orientation.All

    property bool initializationCompleted: false;
    property bool loading: true;
    property bool logoutLoading: false;
    property int ownUserId;
    property bool chatListCreated: false;

    property bool titleInteractionHintActive
    property string loadingText
    signal scrollToTopRequired

    // link handler:
    property string urlToOpen;
    property var chatToOpen: null; //null or [chatId, messageId]

    onStatusChanged: {
        if (status === PageStatus.Active && initializationCompleted && !chatListCreated && !logoutLoading) {
            updateContent();
        }
    }

    Connections {
        target: dBusAdaptor
        onPleaseOpenMessage: {
            Debug.log("[OverviewPage] Opening chat from external requested: ", chatId, messageId);
            // We open the chat only for now - as it's automatically positioned at the last read message
            // it's probably better as if the message itself is displayed in the overlay
            openChat(chatId)
        }
        onPleaseOpenUrl: {
            Debug.log("[OverviewPage] Opening URL requested: ", url)
            openUrl(url)
        }
    }

    Timer {
        id: chatListCreatedTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            overviewPage.chatListCreated = true
            scrollToTopRequired()
            updateSecondaryContentTimer.start()
            var remainingInteractionHints = appSettings.remainingInteractionHints
            Debug.log("Remaining interaction hints: " + remainingInteractionHints)
            if (remainingInteractionHints > 0) {
                interactionHintTimer.start()
                titleInteractionHintActive = true
                appSettings.remainingInteractionHints = remainingInteractionHints - 1
            }
            processUrlToOpen()
        }
    }

    Timer {
        id: openInitializationPageTimer
        interval: 0
        onTriggered:
            pageStack.push(Qt.resolvedUrl("../pages/InitializationPage.qml"))
    }
    Timer {
        id: updateSecondaryContentTimer
        interval: 600
        onTriggered: {
            tdLibWrapper.chatListsCalculateUnreadState()
            tdLibWrapper.getRecentStickers()
            tdLibWrapper.getInstalledStickerSets()
            tdLibWrapper.getContacts()
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingAllowChatInvites)
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingAllowFindingByPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingShowLinkInForwardedMessages)
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingShowPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingShowProfilePhoto)
            tdLibWrapper.getUserPrivacySettingRules(TelegramAPI.SettingShowStatus)
        }
    }

    function openChat(chatId) {
        if(chatListCreated && chatId) {
            Debug.log("[OverviewPage] Opening Chat: ", chatId)
            pageStack.pop(overviewPage, PageStackAction.Immediate)
            pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), { "chatInformation" : tdLibWrapper.getChat(chatId) }, PageStackAction.Immediate)
            chatToOpen = null
        }
    }

    function openChatWithMessageId(chatId, messageId) {
        if(chatId && messageId) {
            chatToOpen = [chatId, messageId];
        }
        if(chatListCreated && chatToOpen && chatToOpen.length === 2) {
            Debug.log("[OverviewPage] Opening Chat: ", chatToOpen[0], "message ID: " + chatToOpen[1])
            pageStack.pop(overviewPage, PageStackAction.Immediate)
            pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), { "chatInformation" : tdLibWrapper.getChat(chatToOpen[0]), "messageIdToShow" : chatToOpen[1] }, PageStackAction.Immediate)
            chatToOpen = null
        }
    }

    function openChatWithMessage(chatId, message) {
        if(chatId && message) {
            chatToOpen = [chatId, message];
        }
        if(chatListCreated && chatToOpen && chatToOpen.length === 2) {
            Debug.log("[OverviewPage] Opening Chat (with provided message): ", chatToOpen[0]);
            pageStack.pop(overviewPage, PageStackAction.Immediate);
            pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), { "chatInformation" : tdLibWrapper.getChat(chatToOpen[0]), "messageToShow" : chatToOpen[1] }, PageStackAction.Immediate);
            chatToOpen = null;
        }
    }

    function processUrlToOpen() {
        if(chatListCreated && urlToOpen && urlToOpen.length > 1) {
            Debug.log("[OverviewPage] Opening URL: ", urlToOpen);
            Functions.handleLink(urlToOpen);
            urlToOpen = "";
        }
    }

    function openUrl(url) {
        if(url && url.length > 0) {
            urlToOpen = url;
        }
        processUrlToOpen()
    }

    function updateContent() {
        tdLibWrapper.loadChats()
        tdLibWrapper.loadChats(true)
    }

    function handleAuthorizationState(isOnInitialization) {
        switch (tdLibWrapper.authorizationState) {
        case TelegramAPI.WaitPhoneNumber:
        case TelegramAPI.WaitCode:
        case TelegramAPI.WaitPassword:
        case TelegramAPI.WaitRegistration:
            overviewPage.loading = false;
            overviewPage.logoutLoading = false;
            if(isOnInitialization) // pageStack isn't ready on Component.onCompleted
                openInitializationPageTimer.start()
            else
                pageStack.push(Qt.resolvedUrl("../pages/InitializationPage.qml"))
            break;
        case TelegramAPI.AuthorizationReady:
            loadingText = qsTr("Loading chat list...")
            overviewPage.loading = false
            overviewPage.initializationCompleted = true
            overviewPage.updateContent()
            break;
        case TelegramAPI.LoggingOut:
            if (logoutLoading) {
                Debug.log("Resources cleared already");
                return;
            }
            Debug.log("Logging out")
            overviewPage.initializationCompleted = false
            overviewPage.loading = false
            chatListCreatedTimer.stop()
            updateSecondaryContentTimer.stop()
            loadingText = qsTr("Logging out")
            overviewPage.logoutLoading = true
            tdLibWrapper.chatListsReset()
            break
        default:
            // Nothing ;)
        }
    }

    Connections {
        target: tdLibWrapper
        onAuthorizationStateChanged:
            handleAuthorizationState(false)
        onOwnUserIdFound:
            overviewPage.ownUserId = ownUserId
        onSomeChatListUpdated: {
            if (!overviewPage.chatListCreated)
                chatListCreatedTimer.restart()
            else tdLibWrapper.chatListsCalculateUnreadState()
        }
        onChatsReceived: {
            if(chats && chats.chat_ids && chats.chat_ids.length === 0) {
                chatListCreatedTimer.restart();
            }
        }
        onChatReceived: {
            var openAndSendStartToBot = chat["@extra"].toString().indexOf("openAndSendStartToBot:") === 0
            if(chat["@extra"] === "openDirectly" || openAndSendStartToBot && chat.type["@type"] === "chatTypePrivate") {
                pageStack.pop(overviewPage, PageStackAction.Immediate)
                // if we get a new chat (no messages?), we can not use the provided data
                var chatinfo = tdLibWrapper.getChat(chat.id)
                var options = {chatInformation: chatinfo}
                if(openAndSendStartToBot) {
                    options.doSendBotStartMessage = true
                    options.sendBotStartMessageParameter = chat["@extra"].substring(22)
                }
                pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), options)
            }
        }
        onCopyToDownloadsSuccessful: {
            appNotification.show(qsTr("Download of %1 successful.", "in-app notification text").arg(fileName),
                                 function() { tdLibWrapper.openFileOnDevice(filePath) },
                                 qsTr("Open", "in-app notification button: open downloaded file"));
        }

        onCopyToDownloadsError: {
            appNotification.show(qsTr("Download failed.", "in-app notification text"));
        }
        onMessageLinkInfoReceived: {
            if (extra === "openDirectly") {
                if (messageLinkInfo.chat_id === 0) {
                    appNotification.show(qsTr("Unable to open link.", "in-app notification text"));
                } else {
                    openChatWithMessage(messageLinkInfo.chat_id, messageLinkInfo.message);
                }
            }
        }
    }

    Component.onCompleted:
        overviewPage.handleAuthorizationState(true)

    TabView {
        id: tabView
        anchors.fill: parent
        model: chatFoldersModel

        Binding {
            target: tabView.tabBarItem
            property: 'countRole'
            when: !!tabView.tabBarItem
            value: appSettings.showFolderUnreadCount ? 'count' : ''
        }

        tabBarVisible: count > 1
        tabBarPosition: appSettings.chatFoldersTabsOnBottom ? Qt.AlignBottom : Qt.AlignTop

        delegate: Loader { // BIG HACK
            id: tabLoader
            asynchronous: true

            readonly property real _yOffset: item && item._yOffset || 0

            // Loader's status is Loader.Loading when the component is partially loaded. We don't want the busy indicator in this state since the view is already usable in it, so for now we disable loading indicator completely.
            //readonly property bool loading: Qt.application.active && PagedView.isCurrentItem && status === Loader.Loading

            width: item ? item.implicitWidth : PagedView.contentWidth
            height: item ? item.implicitHeight : PagedView.contentHeight

            sourceComponent: Component {
                TabItem {
                    // this might break with Opal.Tabs updates:
                    _page: tabView._page
                    _tabContainer: tabLoader
                    topMargin: tabView._tabBarIsTop ? tabView.tabBarHeight : 0
                    bottomMargin: tabView._tabBarIsTop ? 0 : tabView.tabBarHeight

                    allowDeletion: index != 0 // always keep first tab in cache

                    //opacity: 1
                    flickable: chatsView
                    ChatsView {
                        id: chatsView
                        headerText: title
                        model: chat_list_model

                        function readChatList() {
                            if (type == ChatFoldersModel.FolderFolder)
                                tdLibWrapper.readFolderChatList(id)
                            else
                                tdLibWrapper.readChatList(type == ChatFoldersModel.FolderArchive)
                        }

                        Loader {
                            asynchronous: true
                            sourceComponent: index == 0 ? mainPullDownMenu : folderPullDownMenu

                            Component {
                                id: mainPullDownMenu
                                PullDownMenu {
                                    MenuItem {
                                        text: "Debug"
                                        visible: DebugLog.enabled
                                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/DebugPage.qml"))
                                    }
                                    MenuItem {
                                        text: qsTr("Settings")
                                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/SettingsPage.qml"))
                                    }
                                    MenuItem {
                                        text: qsTr("Search Chats")
                                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/SearchChatsPage.qml"))
                                    }
                                    MenuItem {
                                        text: qsTr("New Chat")
                                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/NewChatPage.qml"))
                                    }
                                    MenuItem {
                                        text: qsTr("Archive")
                                        visible: archiveChatListModel.count > 0

                                        rightPadding: archiveChatListModel.unreadChatCount > 0 ? archiveUnreadCount.width + Theme.paddingLarge : 0
                                        Rectangle {
                                            id: archiveUnreadCount
                                            visible: archiveChatListModel.unreadChatCount > 0
                                            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: (parent.width + parent.contentWidth - width)/2
                                            width: Theme.fontSizeExtraLarge
                                            height: Theme.fontSizeExtraLarge
                                            radius: width/2
                                            Text {
                                                anchors.centerIn: parent
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.bold: true
                                                color: Theme.primaryColor
                                                text: Functions.formatUnreadCount(archiveChatListModel.unreadChatCount)
                                            }
                                        }

                                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/ArchivedChatsPage.qml"), {overviewPage: overviewPage})
                                    }
                                    MenuItem {
                                        text: qsTr("Mark as read")
                                        visible: count > 0
                                        onClicked: chatsView.readChatList()
                                    }
                                }
                            }

                            Component {
                                id: folderPullDownMenu
                                PullDownMenu {
                                    // this will be hidden if muted chats won't be included in folder counters (by settings) and only muted chats will be unread, which might not be ideal:
                                    visible: active || count > 0
                                    MenuItem {
                                        text: qsTr("Mark as read")
                                        onClicked: chatsView.readChatList()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            onItemChanged: {
                if (!item) return
                //itemLoaded = true
                tabFadeAnimation.target = null
                item.focus = true
                item.opacity = 0
                tabFadeAnimation.target = item
                tabFadeAnimation.from = 0
                tabFadeAnimation.to = 1
                tabFadeAnimation.restart()
            }

            FadeAnimation {
                id: tabFadeAnimation
            }

            /*BusyIndicator {
                running: !delayBusy.running && loading

                // Avoid flicker when tab container gets repositioned
                parent: tabLoader.parent
                x: (tabLoader.width - width) / 2 + tabLoader.x
                y: root.height/3 - height/2 - tabView.tabBarLoader.height
                size: BusyIndicatorSize.Large

                Timer {
                    id: delayBusy
                    interval: 800
                    running: tabLoader.loading
                }
            }*/
        }
    }

    Timer {
        id: interactionHintTimer
        running: false
        interval: 4000
        onTriggered: titleInteractionHintActive = false
    }

}
