import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."
import "../messageContent"
import "../../js/debug.js" as Debug
import "../../js/functions.js" as Functions

ChatInformationTabItemBase {
    id: tabBase
    loading: listView.count == 0

    property alias model: listView.model

    function jumpToMessage(id) {
        chatManager.model.loadHistoryForMessage(id) // FIXME: need to use chatPage.showMessage (improves performance in case message is already loaded and shows an animation after message is shown). Need to map album messages to main album message though
        appWindow.pageStack.navigateBack()
    }

    SilicaListView {
        id: listView
        width: tabBase.width
        height: tabBase.height

        delegate: ListItem {
            id: listItem
            contentWidth: parent.width
            contentHeight: messageDocument.height

            property var messageId: model.message_id
            property var message: model.display

            MessageDocument {
                id: messageDocument
                width: parent.width - 2*Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                messageListItem: listItem
                rawMessage: message
                tertiaryText: Functions.getDateTimeElapsed(message.date)
                openMouseArea.enabled: false
            }
            onClicked: messageDocument.download()

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Jump to message")
                        onClicked: jumpToMessage(listItem.messageId)
                    }
                }
            }
        }

        Timer {
            id: cooldownTimer
            interval: 2000
            onTriggered: Debug.log("[ChatInformationTabItemFiles] Cooldown completed...")
        }

        onContentYChanged: {
            if (active && !cooldownTimer.running && listView.indexAt(listView.contentX, listView.contentY) > Math.max(0, listView.count - 10)) {
                Debug.log("[ChatInformationTabItemFiles] Trying to get older history items...")
                cooldownTimer.restart()
                tabBase.model.loadMoreHistory()
            }
        }

        VerticalScrollDecorator {}
    }
}
