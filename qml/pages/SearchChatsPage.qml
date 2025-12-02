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
import App.Logic 1.0
import "../components"
import "../js/debug.js" as Debug
import "../js/twemoji.js" as Emoji

Page {
    id: searchChatsPage
    allowedOrientations: Orientation.All

    property bool fromTitleBar

    function resetFocus() {
        searchField.focus = false;
        searchChatsPage.focus = true;
    }

    Timer {
        id: searchPublicChatsTimer
        interval: 800
        running: false
        repeat: false
        onTriggered: {
            Debug.log("Searching for '" + searchField.text + "' globally")
            publicChatsFound = []
            recentlyFoundChatsFound = []
            tdLibWrapper.searchPublicChats(searchField.text)
            searchChatsPage.publicLoading = true
        }
    }

    Connections {
        target: tdLibWrapper
        onChatsReceived: {
            Debug.log("Chats found", extra, JSON.stringify(chatIds))
            if (extra == 'searchChats') {
                localChatsFound = chatIds
            } else if (extra == 'searchPublicChats') {
                publicChatsFound = chatIds
                tdLibWrapper.getSearchSponsoredChats(searchField.text)
                searchChatsPage.publicLoading = false
            } else if (extra == 'searchRecentlyFoundChats') {
                recentlyFoundChatsFound = chatIds
                searchChatsPage.publicLoading = false
            }
        }
        onSponsoredChatsReceived: {
            Debug.log("Sponsored chats received", JSON.stringify(chats))
            for (var i=0; i < chats.length; i++) {
                var chatId = chats[i].chat_id
                sponsoredChats[chatId] = chats[i]
                publicChatsFound.unshift(chatId)
            }
            sponsoredChatsChanged()
            chatsFoundChanged()

            searchChatsPage.publicLoading = false
        }
        onErrorReceived:
            searchChatsPage.publicLoading = false
        onOkReceived: {
            if (request == 'recentlyFound')
                tdLibWrapper.searchRecentlyFoundChats(searchField.text)
        }
    }

    property bool publicLoading: false
    readonly property bool isLoading: publicLoading && publicSearchListView.haveNoLocalResults
    property var recentlyFoundChatsFound: []
    property var localChatsFound: []
    property var publicChatsFound: []
    property var sponsoredChats: ({})

    Component.onCompleted: {
        tdLibWrapper.searchRecentlyFoundChats()
    }

    SilicaFlickable {
        id: searchChatsContainer
        contentHeight: searchChatsPage.height
        anchors.fill: parent

        Column {
            id: searchChatsPageColumn
            width: searchChatsPage.width
            height: searchChatsPage.height

            PageHeader {
                id: searchChatsPageHeader
                title: qsTr("Search", "page header for search page")

                MouseArea {
                    anchors.fill: parent
                    enabled: fromTitleBar
                    onClicked: pageStack.pop(undefined, PageStackAction.Immediate)
                }
            }

            Item {
                id: publicChatsItem

                width: searchChatsPageColumn.width
                height: searchChatsPageColumn.height - searchChatsPageHeader.height

                Column {
                    width: parent.width
                    height: parent.height

                    SearchField {
                        id: searchField
                        width: parent.width
                        placeholderText: qsTr("Search", "Placeholder text for chats search field")
                        focus: true

                        onTextChanged: {
                            tdLibWrapper.searchRecentlyFoundChats(searchField.text)
                            if (text) {
                                tdLibWrapper.searchChats(searchField.text)
                                searchPublicChatsTimer.restart();
                                Debug.log("Searching for '" + searchField.text + "' locally")
                            } else {
                                localChatsFound = []
                                publicChatsFound = []
                            }
                        }

                        EnterKey.iconSource: "image://theme/icon-m-enter-close"
                        EnterKey.onClicked: resetFocus()
                    }

                    SilicaListView {
                        id: publicSearchListView
                        clip: true
                        width: parent.width
                        height: parent.height - searchField.height
                        visible: !searchChatsPage.isLoading
                        opacity: visible ? 1 : 0
                        Behavior on opacity { FadeAnimation {} }

                        readonly property bool haveNoLocalResults: headerItem
                                                                   && headerItem.localSearchListView.count == 0
                                                                   && headerItem.recentlyFoundSearchListView.count == 0
                        
                        header: Column {
                            width: parent.width
                            property alias localSearchListView: localSearchListView
                            property alias recentlyFoundSearchListView: recentlyFoundSearchListView

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
                                                source: "image://theme/icon-m-left"
                                                rotation: expanded ? 90 : -90
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
                                            flickable: publicSearchListView
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
                                                tdLibWrapper.getTopChats(tdLibWrapper.TopChatCategoryUsers, columnsCount*2)
                                            }
                                            Component.onCompleted: update()
                                            Connections {
                                                target: tdLibWrapper
                                                onChatsReceived:
                                                    if (extra == 'topChatCategoryUsers')
                                                        topChatUsersView.model = chatIds
                                                onOkReceived:
                                                    if (request == 'topChatCategoryUsers')
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

                                                property var chatInformation: tdLibWrapper.getChat(modelData)
                                                primaryText.text: Emoji.emojify(chatInformation.title, primaryText.font.pixelSize)
                                                pictureThumbnail.photoData: typeof chatInformation.photo.small !== "undefined" ? chatInformation.photo.small : {}

                                                menu: Component {
                                                    ContextMenu {
                                                        MenuItem {
                                                            text: qsTr("Remove from Recents")
                                                            onClicked: remorseDelete(function() { tdLibWrapper.removeTopChat(tdLibWrapper.TopChatCategoryUsers, modelData) })
                                                        }
                                                    }
                                                }

                                                onClicked: pageStack.replace(Qt.resolvedUrl("ChatPage.qml"), {chatInformation: chatInformation})
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnView {
                                id: localSearchListView
                                width: parent.width
                                model: searchChatsPage.localChatsFound
                                delegate: TDLibChatListItem {
                                    chatId: modelData
                                    onClicked: tdLibWrapper.addRecentlyFoundChat(chatId)
                                }
                                itemHeight: Theme.itemSizeExtraLarge
                            }

                            ButtonsSectionHeader {
                                visible: recentlyFoundSearchListView.count > 0
                                text: qsTr("Recent", "Recently found chats")

                                IconButton {
                                    icon.source: "image://theme/icon-m-cancel"
                                    onClicked: Remorse.popupAction(searchChatsPage, qsTr("Cleared recents", "Remorse popup indicating that recently found chats are cleared"), function() {
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
                                    menu: Component {
                                        ContextMenu {
                                            MenuItem {
                                                text: qsTr("Remove from Recent", "Remove a chat from recently found chats")
                                                onClicked: tdLibWrapper.removeChat(recentlyFoundChatDelegate.chatId)
                                            }
                                        }
                                    }
                                    onClicked: tdLibWrapper.addRecentlyFoundChat(chatId)
                                }
                                itemHeight: Theme.itemSizeExtraLarge
                            }

                            SectionHeader {
                                visible: publicSearchListView.count > 0
                                text: qsTr("Global search results")
                            }
                        }

                        model: publicChatsFound.filter(function(x) { return recentlyFoundChatsFound.indexOf(x) < 0 && localChatsFound.indexOf(x) < 0 })
                        delegate: TDLibChatListItem {
                            chatId: modelData
                            ad: modelData in sponsoredChats
                            onClicked: tdLibWrapper.addRecentlyFoundChat(chatId)
                        }

                        ViewPlaceholder {
                            y: Theme.paddingLarge
                            enabled: publicSearchListView.count == 0 && publicSearchListView.haveNoLocalResults
                            text: searchField.text.length < 5 ? qsTr("Enter your query to start searching (at least 5 characters needed)") : qsTr("No chats found.")
                        }

                        VerticalScrollDecorator {}
                    }
                }

                BusyLabel {
                    text: qsTr("Searching chats...")
                    running: searchChatsPage.isLoading
                }
            }
        }
    }
}
