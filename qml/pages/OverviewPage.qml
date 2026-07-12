import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/chatList"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug
import "../modules/Opal/Tabs"

Page {
    id: overviewPage
    objectName: 'overviewPage'
    allowedOrientations: Orientation.All

    property bool loading: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationUnknown
    property bool logoutLoading: tdLibWrapper.authorizationState == TDLibAPI.LoggingOut
    property bool chatListCreated: false

    property bool titleInteractionHintActive

    signal scrollToTopRequired

    Connections {
        target: dBusAdaptor
        onDoOpenMessage: {
            Debug.log("[OverviewPage] Opening chat from external requested: ", chatId, messageId)
            // We open the chat only for now - as it's automatically positioned at the last read message
            // this also doesn't highlight the message which isn't really needed
            openChat(chatId, {topicIdToShow: topicId}, true)
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
            tdLibWrapper.chatListsCalculateUnreadState()
            tdLibWrapper.getRecentStickers()
            tdLibWrapper.getInstalledStickerSets()
            tdLibWrapper.getContacts()
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingAllowChatInvites)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingAllowFindingByPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowLinkInForwardedMessages)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowPhoneNumber)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowProfilePhoto)
            tdLibWrapper.getUserPrivacySettingRules(TDLibAPI.SettingShowStatus)
            tdLibWrapper.getProxies()
        }
    }

    function chatIsOpen(chatId) {
        return pageStack.currentPage.objectName === 'chatPage' && pageStack.currentPage.chatId === chatId
    }

    function openChat(chatId, options, doPop) {
        if (chatId && tdLibWrapper.hasChatData(chatId)) {
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
            options.chatInformation = tdLibWrapper.getChat(chatId)
            pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), options, doPop ? PageStackAction.Immediate : PageStackAction.Animated)
        }
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
        target: tdLibWrapper
        onAuthorizationStateChanged:
            handleAuthorizationState()
        onSomeChatListUpdated:
            if (!overviewPage.chatListCreated)
                chatListCreatedTimer.restart()
            else tdLibWrapper.chatListsCalculateUnreadState()
        onChatReceived: {
            var openAndSendStartToBot = chat["@extra"].toString().indexOf("openAndSendStartToBot:") === 0
            if (chat['@extra'] === 'openDirectly' || chat['@extra'].openDirectly || (openAndSendStartToBot && chat.type["@type"] === "chatTypePrivate")) {
                // why was this here: "if we get a new chat (no messages?), we can not use the provided data"?
                // it doesn't seem to be true, TGX and Unigram don't do additional
                // createPrivateChat/createBasicGroupChat/createSupergroupChat calls after searchPublicChat...
                var options = {}
                if (openAndSendStartToBot) {
                    options.doSendBotStartMessage = true
                    options.sendBotStartMessageParameter = chat["@extra"].substring(22)
                }
                openChat(chat.id, options)
            }
        }
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
        onChatInviteLinkInfoReceived: {
            if (tdLibWrapper.canSkipChatJoinDialog(info.chat_id))
                openChat(info.chat_id)
            else
                pageStack.push(Qt.resolvedUrl("../dialogs/ChatJoinDialog.qml"), {link: link, invite: info})
        }
        onInternalLinkTypeProxyReceived:
            pageStack.push(Qt.resolvedUrl("../dialogs/AddProxyDialog.qml"), {server: server, port: port, proxyType: type, openAfterAdding: true})
        onAddedProxyReceived:
            if (extra == 'open')
                openProxySettings()
        onAddedProxiesReceived:
            // FIXME: we could use options.enabled_proxy_id instead, but then button would not show up when a proxy is added but not currently enabled
            if (proxies.length > 0)
                proxySettingsButton.visible = true
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

    Component.onCompleted:
        overviewPage.handleAuthorizationState()

    function openSearch() {
        pageStack.push(Qt.resolvedUrl("SearchChatsPage.qml"), {fromTitleBar: true}, PageStackAction.Immediate)
    }
    function openProxySettings() {
        pageStack.completeAnimation()
        pageStack.push(Qt.resolvedUrl("ProxiesPage.qml"))
    }

    OverviewPageHeader {
        id: header
        y: Math.max(0, -tabView.pulleyYOffset)

        // in case MoueArea here fails, we also have one inside the tab's flickable
        MouseArea {
            anchors.fill: parent
            onClicked: openSearch()
        }

        // this does not follow sailfish guidelines at all,
        // but having 6 pulley menu items doesn't either and this seems better
        // better ideas are always welcome
        IconButton {
            id: proxySettingsButton
            y: (parent.height - height) / 2 + Screen.topCutout.height
            anchors.left: header.statusItem.right
            visible: false
            enabled: visible
            icon.source: 'image://theme/icon-m-browser-permissions'

            property bool externalMouseAreaDown
            highlighted: down || externalMouseAreaDown

            onClicked: openProxySettings()
        }
        // don't add additional paddings, both icon and statusItem have enough of them
        leftMargin: Theme.itemSizeMedium + (proxySettingsButton.visible ? proxySettingsButton.width : 0)
    }

    TabView {
        id: tabView
        anchors.fill: parent
        model: chatFoldersModel

        // TODO: currently, we use some terrible hacks for making header work,
        // and to make pulley menu openable when swiping from it.
        // Ideally these patches should be improved and upstreamed.

        maxYOffset: header.height
        yOffset: pulleyYOffset - header.height

        Component.onCompleted: {
            tabView.tabBarItem.countRole = Qt.binding(function() { return yaqtSettings.showFolderUnreadCount ? 'count' : '' })
            tabView.tabBarItem.iconRole = Qt.binding(function() { return appSettings.chatFoldersTabBarShowIcons ? 'icon' : '' })

            tabView.tabBarItem.iconSize = Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
            tabView.tabBarItem.iconColor = Qt.binding(function() { return Theme.primaryColor })
        }

        tabBarVisible: count > 1
        tabBarPosition: appSettings.chatFoldersTabBarOnBottom ? Qt.AlignBottom : Qt.AlignTop

        tabComponent: Component {
            TabItem {
                id: tabItem
                allowDeletion: tabIndex !== 0 // always keep first tab in cache

                topMargin: (parent._ctxTopMargin || _ctxTopMargin || 0) + header.height
                alterFlickablePulleyMenu: false

                property bool isEmpty: true
                Binding {
                    target: tabItem.parent
                    property: 'loading'
                    value: Qt.application.active && isCurrentItem && chatsViewLoader.status == Loader.Loading && isEmpty
                }

                //opacity: 1
                flickable: chatsFlickable
                SilicaFlickable {
                    id: chatsFlickable
                    parent: tabItem
                    anchors.fill: parent

                    function readChatList() {
                        if (tabModel.type === ChatFoldersModel.FolderFolder)
                            tdLibWrapper.readFolderChatList(tabModel.id)
                        else
                            tdLibWrapper.readChatList(tabModel.type === ChatFoldersModel.FolderArchive)
                    }

                    MouseArea {
                        y: header.y
                        width: header.width
                        height: header.height
                        onClicked: openSearch()
                    }
                    MouseArea {
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
                        asynchronous: true
                        // even if the first tab is not main chat list, still use the pulley menu
                        sourceComponent: tabIndex === 0 ? mainPullDownMenu : folderPullDownMenu

                        Component {
                            id: mainPullDownMenu
                            PullDownMenu {
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
                                // this will be hidden if muted chats won't be included in folder counters (by settings) and only muted chats will be unread, which might not be ideal:
                                visible: active || tabModel.count > 0
                                MenuItem {
                                    text: qsTr("Mark as read")
                                    onClicked: chatsFlickable.readChatList()
                                }
                            }
                        }
                    }

                    // FIXME: is loading the chats list separately from the actual tab correct?
                    Loader {
                        id: chatsViewLoader
                        anchors {
                            top: parent.top
                            topMargin: tabItem.topMargin
                        }
                        width: parent.width
                        height: parent.height - anchors.topMargin - tabItem.bottomMargin

                        asynchronous: true
                        sourceComponent: Component {
                            ChatsView {
                                id: chatsView
                                anchors.fill: parent
                                model: tabModel.chat_list_model
                                chatListType: tabModel.type
                                folderId: tabModel.folder_id

                                Binding {
                                    target: tabItem
                                    property: 'isEmpty'
                                    value: chatsView.count == 0
                                }
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
        Behavior on opacity { FadeAnimation {} }
        opacity: overviewPage.titleInteractionHintActive ? 1 : 0
    }

    Timer {
        id: interactionHintTimer
        running: false
        interval: 4000
        onTriggered: titleInteractionHintActive = false
    }
}
