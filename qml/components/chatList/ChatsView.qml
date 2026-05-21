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
import io.libfernie 1.0
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug

SilicaListView {
    id: view
    visible: !overviewPage.loading
    clip: true
    opacity: (overviewPage.chatListCreated || overviewPage.logoutLoading) ? 1 : 0
    Behavior on opacity { FadeAnimation {} }

    //property bool replacePage
    property int chatListType: ChatFoldersModel.FolderMain
    property int folderId

    Connections {
        target: overviewPage
        onScrollToTopRequired: view.scrollToTop()
    }

    delegate: ChatListViewItem {
        chatListType: view.chatListType
        folderId: view.folderId
        onClicked: {
            pageStack.push(Qt.resolvedUrl("../../pages/ChatPage.qml"), {
                chatInformation : display,
                chatPicture: photo_data.small
            })
        }
    }

    Component.onCompleted:
        model.load()

    onContentYChanged: {
        if (view.count == 0) return

        var i = view.indexAt(view.contentX, view.contentY + view.height)
        if (i === -1 || i > Math.max(0, view.count - 10))
            model.load()
    }

    ViewPlaceholder {
        enabled: view.count === 0
        text: qsTr("You don't have any chats yet.")
        hintText: qsTr("Pull down to search public chats or create a new chat")
    }

    VerticalScrollDecorator {}
}
