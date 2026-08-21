//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/chatList"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug
import Opal.Tabs 1.0

Page {
    id: overviewPage
    objectName: 'overviewPage'
    allowedOrientations: Orientation.All

    property bool loading: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationUnknown
    property bool logoutLoading: tdLibWrapper.authorizationState == TDLibAPI.LoggingOut
    property bool chatListCreated: false

    property bool titleInteractionHintActive

    signal scrollToTopRequired

    Binding {
        target: appWindow
        property: 'overviewPage'
        value: overviewPage
    }

    Connections {
        target: dBusAdaptor
        onDoOpenMessage: {
            Debug.log("[OverviewPage] Opening chat from external requested:", chatId, messageId)
            // We open the chat only for now - as it's automatically positioned at the last read message
            // this also doesn't highlight the message which isn't really needed
            var options = {topicIdToShow: topicId}
            if (!openChat(chatId, options, true)) {
                Debug.log("[OverviewPage] Requesting not yet received chat from TDLib to open externally", chatId)
                tdLibWrapper.getChatTd(chatId, {openDirectly: true, options: options, doPop: true})
            }
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
            var remainingInteractionHints = appConfig.remainingInteractionHints
            Debug.log("Remaining interaction hints: " + remainingInteractionHints)
            if (remainingInteractionHints > 0) {
                interactionHintTimer.start()
                titleInteractionHintActive = true
                appConfig.remainingInteractionHints = remainingInteractionHints - 1
            }
        }
    }

    Timer {
        id: openInitializationDialogTimer
        interval: 0
        onTriggered: {
            pageStack.completeAnimation()

            // Proxy links are the only deep links with a separate page which can be viewed from login page (as of now)
            var page = pageStack.pop(overviewPage, PageStackAction.Immediate)
            var proxyPageData
            if (page && page.objectName === 'addProxyDialog')
                proxyPageData = {server: page.server, port: page.port, proxyType: page.getTypeObject(), openAfterAdding: true}

            if (appConfig.welcomeTourCompleted)
                pageStack.push(Qt.resolvedUrl('../dialogs/InitializationDialog.qml'), {initial: true})
            else
                pageStack.push(Qt.resolvedUrl('../dialogs/WelcomeDialog.qml'))

            if (proxyPageData) {
                pageStack.completeAnimation()
                pageStack.push(Qt.resolvedUrl('../dialogs/AddProxyDialog.qml'), proxyPageData)
            }
        }
    }
    Timer {
        id: updateSecondaryContentTimer
        interval: 600
        onTriggered: {
            chatFoldersModel.calculateUnreadStates()
            tdLibWrapper.getRecentStickers()
            tdLibWrapper.getInstalledStickerSets()
            tdLibWrapper.getContacts()
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingAllowChatInvites)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingAllowFindingByPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowLinkInForwardedMessages)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowProfilePhoto)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowStatus)
        }
    }

    function chatIsOpen(chatId) {
        return pageStack.currentPage.objectName === 'chatPage' && pageStack.currentPage.chatId === chatId
    }

    function openChat(chatId, options, doPop) {
        if (chatId && tdData.hasChatData(chatId)) {
            Debug.log("[OverviewPage] Opening chat", chatId, "options:", JSON.stringify(options))
            pageStack.completeAnimation()

            if (doPop)
                pageStack.pop(overviewPage, PageStackAction.Immediate)
            else {
                // TODO: if a duplicate chat page is found in the page stack, remove it
                // also we should not add a maximum of pages after which they begin to pop
                /*var page = pageStack.find(function (page) {
                    return page.objectName === 'chatPage' && page.chatInformation.id === chatId
                })
                if (page)
                    pageStack.pop(page) // here it will pop the duplicate chat page AND everything above it, but we need just the duplicate chat page
                */
            }

            options = options || {}
            options.chatId = chatId
            pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), options, doPop ? PageStackAction.Immediate : PageStackAction.Animated)
            return true
        }
        return false
    }

    function handleAuthorizationState() {
        switch (tdLibWrapper.authorizationState) {
        case TDLibAPI.WaitPhoneNumber:
        case TDLibAPI.WaitPremiumPurchase:
        case TDLibAPI.WaitEmailAddress:
        case TDLibAPI.WaitEmailCode:
        case TDLibAPI.WaitCode:
        case TDLibAPI.WaitOtherDeviceConfirmation:
        case TDLibAPI.WaitRegistration:
        case TDLibAPI.WaitPassword:
            openInitializationDialogTimer.start() // pageStack isn't ready on start
            break;
        case TDLibAPI.LoggingOut:
            chatListCreatedTimer.stop()
            updateSecondaryContentTimer.stop()
            break
        default:
            // Nothing ;)
        }
    }

    Connections {
        target: tdData
        onSomeChatListUpdated:
            if (!overviewPage.chatListCreated)
                chatListCreatedTimer.restart()
            else chatFoldersModel.calculateUnreadStates()
    }

    Connections {
        target: tdLibWrapper
        onAuthorizationStateChanged:
            handleAuthorizationState()
        onChatReceived:
            if (extra && extra === 'openDirectly' || extra.openDirectly)
                openChat(chat.id, extra.options, extra.doPop)
        onCopyToDownloadsSuccessful:
            appNotification.show(qsTr("Download of %1 successful.", "in-app notification text").arg(fileName),
                                 function() { Qt.openUrlExternally(filePath) },
                                 qsTr("Open", "in-app notification button: open downloaded file"))

        onCopyToDownloadsError:
            appNotification.show(qsTr("Download failed", "in-app notification text"))
        onMessageLinkInfoReceived:
            if (chatId === 0)
                appNotification.show(qsTr("Unable to open link", "in-app notification text"))
            else if (messageId != 0)
                openChat(chatId, {messageIdToShow: messageId})
            else
                openChat(chatId)
        onChatInviteLinkInfoReceived:
            if (tdData.canSkipChatJoinDialog(info.chat_id))
                openChat(info.chat_id)
            else
                pageStack.push(Qt.resolvedUrl("../dialogs/ChatJoinDialog.qml"), {link: link, invite: info})
        onInternalLinkTypeProxyReceived:
            pageStack.push(Qt.resolvedUrl("../dialogs/AddProxyDialog.qml"), {server: server, port: port, proxyType: type, openAfterAdding: true})
        onAddedProxyReceived:
            if (extra == 'open')
                openProxySettings()
        onChatJoinResultReceived:
            switch (type) {
            case 'chatJoinResultSuccess':
                if (!chatIsOpen(info.chat_id))
                    openChat(info.chat_id)
                appNotification.show(isChannel ? qsTr("You joined this channel", "channel") : qsTr("You joined this group", "group"))
                break
            case 'chatJoinResultRequestSent':
                appNotification.show(isChannel ? qsTr("Request to join sent", "channel") : qsTr("Request to join sent", "group"))
                break
            case 'chatJoinResultDeclined':
                appNotification.show(isChannel ? qsTr("Your request to join the channel was declined", "channel") : qsTr("Your request to join the group was declined", "group"))
                break
            case 'chatJoinResultGuardBotApprovalRequired':
                // TODO (requires web apps support)
                appNotification.show(qsTr("An approval from a guard bot is required to join the chat, but guard bots are not yet supported"))
                break
            }
        onHttpUrlReceived:
            if (extra == 'copy') {
                Clipboard.text = url
                appNotification.show(qsTr("Link copied to clipboard"))
            }
    }

    Binding {
        target: notificationManager
        property: 'forceInChatOutgoingNgf'
        value: overviewPage.status == PageStatus.Active
    }

    Component.onCompleted:
        overviewPage.handleAuthorizationState()

    function openProxySettings() {
        pageStack.completeAnimation()
        pageStack.push(Qt.resolvedUrl("ProxiesPage.qml"))
    }
    function clickTitleBar() {
        switch (tdLibWrapper.connectionState) {
        case TDLibAPI.WaitingForNetwork:
        case TDLibAPI.Connecting:
        case TDLibAPI.ConnectingToProxy:
            openProxySettings()
            break
        default:
            pageStack.push(Qt.resolvedUrl("SearchChatsPage.qml"), {fromTitleBar: true}, PageStackAction.Immediate)
        }
    }

    OverviewPageHeader {
        id: header
        y: Math.max(0, -tabView.baseYOffset)

        // in case MoueArea here fails, we also have one inside the tab's flickable
        MouseArea {
            anchors.fill: parent
            onClicked: clickTitleBar()
        }

        // this does not follow sailfish guidelines at all,
        // but having 6 pulley menu items doesn't either and this seems better
        // better ideas are always welcome
        IconButton {
            id: proxySettingsButton
            y: (parent.height - height) / 2 + Screen.topCutout.height
            anchors.left: header.statusItem.right
            // When connection is not ready, clicking on the whole page header opens proxy settings anyways
            visible: (tdLibWrapper.connectionState == TDLibAPI.ConnectionReady || tdLibWrapper.connectionState == TDLibAPI.Updating)
                        && !!(tdData.options.expect_blocking || tdData.options.enabled_proxy_id)
            enabled: visible
            icon.source: 'image://theme/icon-m-vpn'

            property bool externalMouseAreaDown
            highlighted: down || externalMouseAreaDown

            onClicked: openProxySettings()
        }
        // don't add additional paddings, both icon and statusItem have enough of them
        leftMargin: Theme.itemSizeMedium + (proxySettingsButton.visible ? proxySettingsButton.width : 0)
    }

    ChatFoldersViewBase {
        id: tabView
        anchors.fill: parent
        extraTopMargin: header.height

        tabComponent: Component {
            ChatFolderTabBase {
                function readChatList() {
                    if (tabModel.type === ChatFoldersModel.FolderFolder)
                        tdLibWrapper.readFolderChatList(tabModel.id)
                    else
                        tdLibWrapper.readChatList(tabModel.type === ChatFoldersModel.FolderArchive)
                }

                MouseArea {
                    parent: flickable
                    y: header.y
                    width: header.width
                    height: header.height
                    onClicked: clickTitleBar()
                }
                MouseArea {
                    parent: flickable
                    x: proxySettingsButton.x
                    y: proxySettingsButton.y
                    width: proxySettingsButton.width
                    height: proxySettingsButton.height
                    enabled: proxySettingsButton.enabled
                    onClicked: openProxySettings()

                    // not sure why but Binding didn't work
                    onContainsPressChanged:
                        if (isCurrentItem)
                            proxySettingsButton.externalMouseAreaDown = containsPress
                }

                Loader {
                    parent: flickable
                    asynchronous: true
                    // even if the first tab is not main chat list, still use the pulley menu
                    sourceComponent: tabIndex === 0 ? mainPullDownMenu : folderPullDownMenu

                    Component {
                        id: mainPullDownMenu
                        PullDownMenu {
                            busy: tdLibWrapper.connectionState == TDLibAPI.Updating
                            MenuItem {
                                text: "Debug"
                                visible: DebugLog.enabled
                                onClicked: pageStack.push(Qt.resolvedUrl("../pages/DebugPage.qml"), {overviewPage: overviewPage})
                            }
                            MenuItem {
                                text: qsTr("Settings")
                                onClicked: pageStack.push(Qt.resolvedUrl("../pages/SettingsPage.qml"))
                            }
                            MenuItem {
                                text: qsTr("Search", "pulley menu option for opening search page")
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
                                visible: tabModel.count > 0
                                onClicked: chatsFlickable.readChatList()
                            }
                        }
                    }

                    Component {
                        id: folderPullDownMenu
                        PullDownMenu {
                            busy: tdLibWrapper.connectionState == TDLibAPI.Updating
                            // this will be hidden if muted chats won't be included in folder counters (by settings) and only muted chats will be unread, which might not be ideal:
                            visible: active || tabModel.count > 0
                            MenuItem {
                                text: qsTr("Mark as read")
                                onClicked: chatsFlickable.readChatList()
                            }
                        }
                    }
                }
            }
        }
    }

    BusyLabel {
        anchors.verticalCenter: parent.verticalCenter
        y: undefined
        text: overviewPage.logoutLoading ? qsTr("Logging out") : qsTr("Loading")
        running: !overviewPage.chatListCreated || overviewPage.logoutLoading
    }

    InteractionHintLabel {
        id: titleInteractionHint
        text: qsTr("Tap on the title bar to quickly open search")
        visible: opacity > 0
        invert: true
        anchors.fill: parent
        Behavior on opacity { FadeAnimator {} }
        opacity: overviewPage.titleInteractionHintActive ? 1 : 0
    }

    Timer {
        id: interactionHintTimer
        running: false
        interval: 4000
        onTriggered: titleInteractionHintActive = false
    }
}
