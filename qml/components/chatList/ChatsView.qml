//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import io.yaqtlib 1.0

SilicaListView {
    id: view
    visible: !overviewPage.loading
    clip: true
    opacity: (overviewPage.chatListCreated || overviewPage.logoutLoading) ? 1 : 0
    Behavior on opacity { FadeAnimator {} }

    //property bool replacePage
    property int chatListType: ChatFoldersModel.FolderMain
    property int folderId

    property var chatsModel: model

    property alias viewPlaceholder: viewPlaceholder

    delegate: ChatListViewItem {
        chatListType: view.chatListType
        folderId: view.folderId
        onClicked: pageStack.push(Qt.resolvedUrl("../../pages/ChatPage.qml"), {chatId: chat_id})
    }

    Component.onCompleted:
        if (chatListType == ChatFoldersModel.FolderFolder)
            chatsModel.load()

    onContentYChanged: {
        if (view.count == 0) return

        var i = view.indexAt(view.contentX, view.contentY + view.height)
        if (i === -1 || i > Math.max(0, view.count - 10))
            chatsModel.load()
    }

    ViewPlaceholder {
        id: viewPlaceholder
        enabled: view.count === 0
        text: qsTr("You don't have any chats yet.")
        hintText: qsTr("Pull down to search public chats or create a new chat")
    }

    VerticalScrollDecorator {}
}
