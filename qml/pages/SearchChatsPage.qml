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
import WerkWolf.Fernschreiber 1.0
import "../components"
import "../js/debug.js" as Debug

Page {
    id: searchChatsPage
    allowedOrientations: Orientation.All

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
                title: qsTr("Search Chats")
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
                        placeholderText: qsTr("Search a chat...")
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
                                    icon.source: "image://theme/icon-m-clear"
                                    onClicked: Remorse.popupAction(searchChatsPage, qsTr("Cleared recents", "Remorse popup indicating that recently found chats are cleared"), function() {
                                        tdLibWrapper.clearRecentlyFoundChats()
                                        recentlyFoundChatsFound = []
                                    })
                                }
                            }

                            ColumnView {
                                id: recentlyFoundSearchListView
                                width: parent.width
                                model: searchChatsPage.recentlyFoundChatsFound
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

                        model: searchChatsPage.publicChatsFound
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
