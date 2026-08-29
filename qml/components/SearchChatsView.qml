//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../components'
import '../components/tdlib'
import '../js/debug.js' as Debug
import '../js/twemoji.js' as Emoji

Item {
    id: root

    width: parent.width
    height: parent.height

    property Item remorseParent: parent

    signal resetFocus
    onResetFocus: searchField.focus = true

    property bool openOnSelected: true
    signal chatSelected(var chatId)

    Timer {
        id: searchPrivateChatsTimer
        interval: 200
        onTriggered: {
            Debug.log("Searching for '" + searchField.text + "' locally")
            localLoading = true
            localChatsFound = []
            recentlyFoundChatsFound = []
            tdLibWrapper.searchChats(searchField.text)
            tdLibWrapper.searchRecentlyFoundChats(searchField.text)
        }
    }

    Timer {
        id: searchPublicChatsTimer
        interval: 800
        onTriggered: {
            Debug.log("Searching for '" + searchField.text + "' globally")
            publicLoading = true
            publicChatsFound = []
            tdLibWrapper.searchPublicChats(searchField.text)
        }
    }

    Connections {
        target: tdLibWrapper
        onChatsReceived: {
            Debug.log("Chats found", extra, JSON.stringify(chatIds))
            if (extra == 'searchChats') {
                localChatsFound = chatIds
                localLoading = false
            } else if (extra == 'searchPublicChats') {
                publicChatsFound = chatIds
                tdLibWrapper.getSearchSponsoredChats(searchField.text)
                publicLoading = false
            } else if (extra == 'searchRecentlyFoundChats') {
                recentlyFoundChatsFound = chatIds
                publicLoading = false
            }
        }
        onSponsoredChatsReceived: {
            Debug.log("Sponsored chats received", JSON.stringify(chats))
            sponsoredChats = chats
            publicLoading = false
        }
        onErrorReceived: publicLoading = localLoading = false
        onOkReceived:
            if (extra == 'recentlyFound')
                tdLibWrapper.searchRecentlyFoundChats(searchField.text)
    }

    property bool publicLoading
    property bool localLoading: true
    readonly property bool haveNoLocalResults: localSearchListView.count == 0 && recentlyFoundSearchListView.count == 0
    readonly property bool isLoading: (publicLoading || localLoading) && haveNoLocalResults && topChatUsersView.count == 0
    property var recentlyFoundChatsFound: []
    property var localChatsFound: []
    property var publicChatsFound: []
    property var sponsoredChats: ({})

    // TODO: when fully hiding chat items depending on the filter (using hidden: property), contentHeight of ColumnViews breaks
    // as a workaround we disable the chats which don't match the filter for now, but ideally a model like UsersModel should be added to yaqt (with support for ChatPermissionFilterModel)
    property var requirePermissions: []
    property int additionalFilter: ChatPermissionFilterModel.AdditionalFilterNone

    function matchesFilter(isSecret, isPrivateChat, chatInformation, relatedInformation) {
        switch (additionalFilter) {
        case ChatPermissionFilterModel.AdditionalFilterNonSecret:
            if (isSecret) return false
            break
        case ChatPermissionFilterModel.AdditionalFilterSecretOnly:
            if (!isSecret) return false
        }

        if (!requirePermissions || !requirePermissions.length || isPrivateChat || isSecret)
            return true

        var status = relatedInformation.status
        var permissions
        switch (status['@type']) {
        case 'chatMemberStatusCreator':
        case 'chatMemberStatusAdministrator':
            return true
        case 'chatMemberStatusMember':
            permissions = chatInformation.permissions
            break
        case 'chatMemberStatusRestricted':
            permissions = status.permissions
            break
        default:
            return false
        }

        if (permissions)
            for (var i=0; i < requirePermissions.length; i++)
                if (permissions[requirePermissions[i]]) return true

        return false
    }

    Component.onCompleted: tdLibWrapper.searchRecentlyFoundChats()

    Column {
        width: parent.width
        height: parent.height

        SearchField {
            id: searchField
            width: parent.width
            placeholderText: qsTr("Search", "Placeholder text for chats search field")
            focus: true

            onTextChanged: {
                if (text) {
                    searchPrivateChatsTimer.restart()
                    searchPublicChatsTimer.restart()
                    Debug.log("Searching for '" + searchField.text + "' locally")
                } else {
                    searchPrivateChatsTimer.stop()
                    searchPublicChatsTimer.stop()
                    localChatsFound = []
                    publicChatsFound = []
                    tdLibWrapper.searchRecentlyFoundChats()
                }
            }

            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: resetFocus()
        }

        SilicaFlickable {
            id: flickable
            clip: true
            width: parent.width
            height: parent.height - searchField.height
            contentHeight: column.height
            opacity: isLoading ? 0 : 1
            Behavior on opacity { FadeAnimator {} }

            Column {
                id: column
                width: parent.width

                Loader {
                    active: searchField.text == ''
                    width: parent.width
                    height: active ? implicitHeight : 0
                    sourceComponent: Component {
                        Column {
                            width: parent.width
                            readonly property bool canExpand: topChatUsersView.count > topChatUsersView.columnsCount
                            property bool expanded: false

                            SectionHeader {
                                text: qsTr("Frequent contacts")
                                visible: topChatUsersView.count > 0
                                enabled: visible
                                rightPadding: expandButton.visible ? (expandButton.width + Theme.paddingLarge) : 0

                                highlighted: topChatUsersMouseArea.containsPress
                                color: highlighted ? Theme.secondaryHighlightColor : Theme.highlightColor

                                HighlightImage {
                                    id: expandButton
                                    anchors {
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    width: Theme.iconSizeMedium
                                    visible: canExpand
                                    highlighted: parent.highlighted
                                    color: Theme.highlightColor
                                    highlightColor: Theme.secondaryHighlightColor
                                    source: "image://theme/icon-m-down"
                                    rotation: expanded ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: topChatUsersMouseArea
                                    anchors.fill: parent
                                    enabled: canExpand
                                    onClicked: expanded = !expanded
                                }
                            }

                            NestedGridView {
                                id: topChatUsersView
                                width: parent.width
                                flickable: flickable
                                readonly property int columnsCount: Math.floor(width / Theme.itemSizeExtraLarge)
                                cellWidth: width / columnsCount
                                cellHeight: Theme.itemSizeHuge

                                clip: true//height < cellHeight//!expanded // always true could affect performance, but without it it doesn't look good since it doesn't apply instantly
                                property real contentHeight: expanded ? _listView.contentHeight : cellHeight
                                height: contentHeight + _listView._menuHeight
                                Behavior on contentHeight {
                                    NumberAnimation {
                                        id: expandAnimation
                                        duration: 150
                                    }
                                }

                                function update() {
                                    if (columnsCount)
                                        tdLibWrapper.getTopChats(TDLibAPI.TopChatCategoryUsers, columnsCount*2)
                                }
                                Component.onCompleted: update()
                                onColumnsCountChanged: update()
                                Connections {
                                    target: tdLibWrapper
                                    onChatsReceived:
                                        if (extra == 'topChatCategoryUsers')
                                            topChatUsersView.model = chatIds
                                    onOkReceived:
                                        if (extra == 'topChatCategoryUsers')
                                            update()
                                }

                                Item {
                                    id: gridViewProxy
                                    // HACK: GridItems inside NestedGridMenu don't properly move (down) when a menu is opened, this is the fix
                                    // this also fixes cellWidth and cellHeight not being picked up by GridItem
                                    // might've fixed remorse below too

                                    property real cellWidth: topChatUsersView.cellWidth
                                    property real cellHeight: topChatUsersView.cellHeight

                                    property Item __silica_contextmenu_instance: topChatUsersView._listView.__silica_contextmenu_instance
                                    property Item __silica_remorse_item: null
                                    property real __silica_menu_height: Math.max(__silica_contextmenu_instance
                                                                                 ? __silica_contextmenu_instance.height : 0,
                                                                                 __silica_remorse_height)
                                    property real __silica_remorse_height

                                    NumberAnimation {
                                        id: remorseHeightAnimation

                                        target: gridViewProxy
                                        property: "__silica_remorse_height"
                                        duration: 200
                                        to: 0.0
                                        easing.type: Easing.InOutQuad
                                    }
                                    on__Silica_remorse_itemChanged:
                                        if (!__silica_remorse_item)
                                            remorseHeightAnimation.restart()

                                    property int _menuOpenOffsetItemsIndex: { -1 }

                                    width: topChatUsersView._listView.width
                                }
                                Binding {
                                    target: topChatUsersView._listView
                                    property: "_menuHeight"
                                    value: gridViewProxy.__silica_menu_height
                                }

                                delegate: PhotoTextsGridItem {
                                    Component.onCompleted: _gridView = gridViewProxy

                                    enabled: (expanded && !expandAnimation.running) || index < topChatUsersView.columnsCount

                                    // FIXME: use TDLibMessageSender/TDLibChat/...
                                    property var chatInformation: tdData.getChat(modelData)
                                    primaryText.text: Emoji.emojify(chatInformation.title, primaryText.font.pixelSize)
                                    pictureThumbnail {
                                        accentColorId: typeof chatInformation.accent_color_id !== 'undefined' ? chatInformation.accent_color_id : -1
                                        minithumbnail: typeof chatInformation.photo.minithumbnail !== "undefined" ? chatInformation.photo.minithumbnail : ({})
                                        photoData: typeof chatInformation.photo.small !== "undefined" ? chatInformation.photo.small : ({})
                                        asSavedMessages: modelData === tdData.myUserId
                                    }

                                    menu: Component {
                                        ContextMenu {
                                            MenuItem {
                                                text: qsTr("Remove from Recents")
                                                onClicked: {
                                                    var tdlib = tdLibWrapper, chatId = modelData
                                                    remorseDelete(function() { tdlib.removeTopChat(TDLibAPI.TopChatCategoryUsers, chatId) })
                                                }
                                            }
                                        }
                                    }

                                    onClicked: {
                                        if (openOnSelected) pageStack.replace(Qt.resolvedUrl("../pages/ChatPage.qml"), {chatId: modelData})
                                        chatSelected(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // TODO: if user searches for saved messages, show it
                // additionally, if the chat matches by both TDLib and this, don't duplicate
                /*Loader {
                    width: parent.width
                    active: false
                    height: active ? Theme.itemSizeExtraLarge : 0
                    sourceComponent: Component {
                        TDLibChatListItem {
                            chatId: tdData.myUserId
                            asSavedMessages: true
                            openOnClick: root.openOnSelected
                            onClicked: {
                                tdLibWrapper.addRecentlyFoundChat(chatId)
                                chatSelected(chatId)
                            }
                        }
                    }
                }*/

                ColumnView {
                    id: localSearchListView
                    width: parent.width
                    model: localChatsFound
                    delegate: TDLibChatListItem {
                        chatId: modelData
                        asSavedMessages: true
                        handleGroupUpdates: true
                        enabled: matchesFilter(isSecret, isPrivateChat, chatInformation, relatedInformation)
                        openOnClick: root.openOnSelected
                        onClicked: {
                            tdLibWrapper.addRecentlyFoundChat(chatId)
                            chatSelected(chatId)
                        }
                    }
                    itemHeight: Theme.itemSizeLarge + Theme.paddingMedium
                }

                ButtonsSectionHeader {
                    visible: recentlyFoundSearchListView.count > 0
                    text: qsTr("Recent", "Recently found chats")

                    IconButton {
                        icon.source: "image://theme/icon-m-cancel"
                        onClicked: Remorse.popupAction(remorseParent, qsTr("Cleared recents", "Remorse popup indicating that recently found chats are cleared"), function() {
                            tdLibWrapper.clearRecentlyFoundChats()
                            recentlyFoundChatsFound = []
                        })
                    }
                }

                ColumnView {
                    id: recentlyFoundSearchListView
                    width: parent.width
                    model: recentlyFoundChatsFound.filter(function(x) { return localChatsFound.indexOf(x) < 0 })
                    delegate: TDLibChatListItem {
                        id: recentlyFoundChatDelegate
                        chatId: modelData
                        asSavedMessages: true
                        handleGroupUpdates: true
                        enabled: matchesFilter(isSecret, isPrivateChat, chatInformation, relatedInformation)
                        menu: Component {
                            ContextMenu {
                                MenuItem {
                                    text: qsTr("Remove from Recent", "Remove a chat from recently found chats")
                                    onClicked: tdLibWrapper.removeRecentlyFoundChat(recentlyFoundChatDelegate.chatId)
                                }
                            }
                        }
                        openOnClick: root.openOnSelected
                        onClicked: {
                            tdLibWrapper.addRecentlyFoundChat(chatId)
                            chatSelected(chatId)
                        }
                    }
                    itemHeight: Theme.itemSizeLarge + Theme.paddingMedium
                }

                SectionHeader {
                    visible: publicSearchListView.count > 0
                    text: qsTr("Global search results")
                }

                Column {
                    id: sponsoredPublicSearchListView
                    width: parent.width

                    Repeater {
                        model: sponsoredChats
                        TDLibChatListItem {
                            chatId: modelData.chat_id
                            asSavedMessages: true
                            handleGroupUpdates: true
                            enabled: matchesFilter(isSecret, isPrivateChat, chatInformation, relatedInformation)
                            ad: true
                            menu: Component {
                                ContextMenu {
                                    MenuLabel {
                                        visible: !!text
                                        text: modelData.sponsor_info
                                    }
                                    MenuLabel {
                                        visible: !!text
                                        text: modelData.additional_info
                                    }
                                }
                            }
                            openOnClick: root.openOnSelected
                            onClicked: {
                                tdLibWrapper.openSponsoredChat(chatId)
                                chatSelected(chatId)
                            }

                            property bool viewed
                            property bool scrolledTo: {
                                var mappedY = mapToItem(flickable.contentItem, 0, 0)
                                return (mappedY < (flickable.contentY + flickable.height)) && ((mappedY + height) > flickable.contentY)
                            }
                            onScrolledToChanged:
                                if (!viewed && scrolledTo) {
                                    Debug.log("Viewing sponsored result", modelData.unique_id, modelData.chat_id)
                                    tdLibWrapper.viewSponsoredChat(modelData.unique_id)
                                    viewed = true
                                }
                        }
                    }
                }

                ColumnView {
                    id: publicSearchListView
                    width: parent.width
                    model: publicChatsFound.filter(function(x) { return recentlyFoundChatsFound.indexOf(x) < 0 && localChatsFound.indexOf(x) < 0 })
                    delegate: TDLibChatListItem {
                        chatId: modelData
                        asSavedMessages: true
                        handleGroupUpdates: true
                        enabled: matchesFilter(isSecret, isPrivateChat, chatInformation, relatedInformation)
                        openOnClick: root.openOnSelected
                        onClicked: {
                            tdLibWrapper.addRecentlyFoundChat(chatId)
                            chatSelected(chatId)
                        }
                    }
                    itemHeight: Theme.itemSizeLarge + Theme.paddingMedium
                }
            }

            ViewPlaceholder {
                y: Theme.paddingLarge
                enabled: publicSearchListView.count == 0 && haveNoLocalResults
                text: searchField.text ? qsTr("No Results") : qsTr("No recent searches")
                hintText: searchField.text ? qsTr('There were no results for "%1". Try another search.').arg(searchField.text) : qsTr("Recent search results will appear here.")
            }

            VerticalScrollDecorator {}
        }
    }

    BusyLabel {
        text: qsTr("Searching chats")
        running: isLoading
    }
}
