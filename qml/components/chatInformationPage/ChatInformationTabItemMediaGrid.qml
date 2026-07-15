//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'
import '../tdlib'
import '../../js/debug.js' as Debug

ChatInformationTabItemMediaBase {
    id: tabBase
    scrollableView: gridView

    property alias model: gridView.model

    function loadMessage(index) {
        appWindow.pageStack.push(Qt.resolvedUrl("../../pages/MediaAlbumPage.qml"), {
                                    chatManager: chatManager,
                                    model: model,
                                    initializeMediaModel: false,
                                    index: index
                                })
    }

    SilicaGridView {
        id: gridView
        height: tabBase.height
        width: tabBase.width
        property int columnCount: Math.floor(width / Theme.itemSizeHuge)
        cellWidth: width / columnCount
        cellHeight: cellWidth

        delegate: GridItem {
            id: gridItem
            property var messageId: model.message_id
            property var message: model.display

            onClicked: loadMessage(index)

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

        Timer {
            id: cooldownTimer
            interval: 2000
            onTriggered: Debug.log("[ChatInformationTabItemMediaGrid] Cooldown completed...")
        }

        onContentYChanged: {
            if (active && !cooldownTimer.running && gridView.indexAt(gridView.contentX, gridView.contentY) > Math.max(0, gridView.count - 10*columnCount)) {
                Debug.log("[ChatInformationTabItemMediaGrid] Trying to get older history items...")
                cooldownTimer.restart()
                tabBase.model.loadMoreHistory()
            }
        }

        VerticalScrollDecorator {}
    }
}
