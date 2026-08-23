//@ SPDX-FileCopyrightText: 2026 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import Opal.Tabs 1.0

TabItem {
    id: tabItem
    allowDeletion: tabIndex !== 0 // always keep first tab in cache

    property bool fillFlickable: !!(flickable && flickable.pullDownMenu)

    bodyItem.height: fillFlickable ? tabItem.implicitHeight : bodyItem.implicitHeight
    Binding {
        target: bodyItem.anchors
        when: fillFlickable
        property: 'topMargin'
        value: 0
    }
    alterPullDownMenuFlickable: !fillFlickable

    property bool isEmpty: true
    Binding {
        target: tabItem.parent
        property: 'loading'
        value: Qt.application.active && isCurrentItem && chatsViewLoader.status == Loader.Loading && isEmpty
    }

    property var chatsModel: tabModel.chat_list_model
    property var chatsSourceModel: chatsModel
    property Component delegate: ChatListViewItem {
        chatListType: ListView.view.chatListType
        folderId: ListView.view.folderId
        onClicked: pageStack.push(Qt.resolvedUrl("../../pages/ChatPage.qml"), {chatId: chat_id})
    }

    property string viewPlaceholderText: qsTr("You have no chats")
    property string viewPlaceholderHintText

    //opacity: 1
    flickable: chatsFlickable
    SilicaFlickable {
        id: chatsFlickable
        anchors.fill: parent

        // FIXME: is loading the chats list separately from the actual tab correct?
        Loader {
            id: chatsViewLoader
            width: parent.width
            height: parent.height

            asynchronous: true
            sourceComponent: Component {
                ChatsView {
                    id: chatsView
                    anchors {
                        top: parent.top
                        topMargin: fillFlickable ? tabItem.topMargin : 0
                    }
                    width: parent.width
                    height: parent.height - anchors.topMargin
                    clip: true

                    model: tabItem.chatsModel
                    chatsModel: chatsSourceModel
                    chatListType: tabModel.type
                    folderId: tabModel.folder_id

                    delegate: tabItem.delegate

                    viewPlaceholder {
                        text: tabItem.viewPlaceholderText
                        hintText: tabItem.viewPlaceholderHintText
                    }

                    Binding {
                        target: tabItem
                        property: 'isEmpty'
                        value: chatsView.count == 0
                    }

                    Connections {
                        target: overviewPage
                        ignoreUnknownSignals: true
                        onScrollToTopRequired: chatsView.scrollToTop()
                    }
                }
            }
        }
    }
}
