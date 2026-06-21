import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import io.yaqtlib 1.0
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
        if (chatListType == ChatFoldersModel.FolderFolder)
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
