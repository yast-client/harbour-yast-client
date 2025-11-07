import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."
import "../../js/debug.js" as Debug

ChatInformationTabItemBase {
    id: tabBase
    loading: gridView.count == 0

    property var model
    property alias viewModel: gridView.model

    function jumpToMessage(id) {
        chatManager.model.loadHistoryForMessage(id) // FIXME: need to use chatPage.showMessage (improves performance in case message is already loaded and shows an animation after message is shown). Need to map album messages to main album message though
        appWindow.pageStack.navigateBack()
    }

    function loadMessage(message) {
        appWindow.pageStack.push(Qt.resolvedUrl("../../pages/MediaAlbumPage.qml"), {message: message})
    }

    SilicaGridView {
        id: gridView
        height: tabBase.height
        width: tabBase.width
        property int columnCount: Math.floor(width / Theme.itemSizeHuge)
        cellWidth: width / columnCount
        cellHeight: cellWidth

        model: tabBase.model

        delegate: GridItem {
            id: gridItem
            property var messageId: model.message_id
            property var message: model.display

            onClicked: loadMessage(message)

            Loader {
                anchors.fill: parent
                sourceComponent: message.content['@type'] === 'messagePhoto' ? photoComponent : videoComponent
            }

            Component {
                id: photoComponent
                TDLibPhoto {
                    anchors.fill: parent
                    photo: message.content.photo
                    highlighted: gridItem.highlighted
                }
            }
            Component {
                id: videoComponent
                TDLibThumbnail {
                    property var videoData: {
                        switch (message.content['@type']) {
                        case "messageVideo":
                            return message.content.video
                        case "messageAnimation":
                            return message.content.animation
                        case "messageVideoNote":
                            return message.content.video_note

                        default:
                            return message.content.video
                        }
                    }

                    width: parent.width //don't use anchors here for easier custom scaling
                    height: parent.height

                    thumbnail: videoData.thumbnail
                    minithumbnail: videoData.minithumbnail
                    highlighted: gridItem

                    OpaqueIcon {
                        anchors.centerIn: parent
                        icon.source: "image://theme/icon-l-play?white"
                        highlighted: gridItem.highlighted
                    }
                }
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Jump to message")
                        onClicked: jumpToMessage(gridItem.messageId)
                    }
                }
            }
        }

        Component.onCompleted:
            chatManager.initializeMediaMessagesModel(tabBase.model)

        Connections {
            target: tabBase.model
            onMessagesReceived: {
                Debug.log("[ChatInformationTabItemMedia] Messages received, from incremental update: ", fromIncrementalUpdate, ", view has ", gridView.count, " messages")

                if (!fromIncrementalUpdate)
                    busyIndicator.running = false

                //cooldownTimer.restart()
            }
            onAlreadyLoaded: {
                Debug.log("[ChatInformationTabItemMedia] Chat history end already loaded")
                busyIndicator.running = false
            }
        }

        Timer {
            id: cooldownTimer
            interval: 2000
            onTriggered: Debug.log("[ChatInformationTabItemMedia] Cooldown completed...")
        }

        onContentYChanged: {
            if (active && !cooldownTimer.running && gridView.indexAt(gridView.contentX, gridView.contentY) > Math.max(0, gridView.count - 10*columnCount)) {
                Debug.log("[ChatInformationTabItemMedia] Trying to get older history items...")
                cooldownTimer.restart()
                tabBase.model.loadMoreHistory()
            }
        }

        VerticalScrollDecorator {}

        BusyLabel {
            id: busyIndicator
            running: true
        }
    }
}
