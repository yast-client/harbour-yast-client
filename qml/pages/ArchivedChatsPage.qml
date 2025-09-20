import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'

Page {
    allowedOrientations: Orientation.All

    property var overviewPage

    SilicaFlickable {
        anchors.fill: parent
        PullDownMenu {
            MenuItem {
                text: qsTr("How does it work?")
                onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/ArchiveChatListTutorialDialog.qml"))
            }
            MenuItem {
                text: qsTr("Archive settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), {initialArea: 'archive'})
            }
            MenuItem {
                text: qsTr("Mark as read")
                visible: archiveChatListModel.unreadChatCount > 0
                onClicked: tdLibWrapper.readChatList(true)
            }
        }


        OverviewPageHeader {
            id: header
            defaultTitle: qsTr("Archive")
        }

        ChatsView {
            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            model: archiveChatListModel
            inArchive: true
        }
    }

    Timer {
        id: openTutorialTimer
        interval: 0
        onTriggered: {
            pageStack.completeAnimation()
            pageStack.push(Qt.resolvedUrl("../dialogs/ArchiveChatListTutorialDialog.qml"))
        }
    }

    Component.onCompleted: if (!appSettings.archiveChatListHintCompleted)
                               openTutorialTimer.start()
}
