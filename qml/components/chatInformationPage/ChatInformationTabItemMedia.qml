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

import ".."
import "../../js/debug.js" as Debug

ChatInformationTabItemBase {
    id: tabBase
    loading: gridView.count == 0

    function loadMessage(id) {
        chatManager.model.triggerLoadHistoryForMessage(id) // FIXME: need to use chatPage.showMessage (improves performance in case message is already loaded and shows an animation after message is shown). Need to map album messages to main album message though
        appWindow.pageStack.navigateBack()
    }

    SilicaGridView {
        id: gridView
        height: tabBase.height
        width: tabBase.width
        property int columnCount: Math.floor(width / Theme.itemSizeHuge)
        cellWidth: width / columnCount
        cellHeight: cellWidth

        model: InvertedProxyModel {
            sourceModel: chatManager.mediaMessagesModel
        }

        delegate: GridItem {
            id: gridItem
            property var messageId: model.message_id
            property var message: model.display

            onClicked: loadMessage(messageId)

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
        }

        Component.onCompleted: chatManager.initializeMediaMessagesModel()

        Timer {
            id: cooldownTimer
            interval: 2000
            onTriggered: Debug.log("[ChatInformationTabItemMedia] Cooldown completed...")
        }

        onContentYChanged: {
            if (!cooldownTimer.running && gridView.indexAt(gridView.contentX, gridView.contentY) > Math.max(0, gridView.count - 10*columnCount)) {
                Debug.log("[ChatInformationTabItemMedia] Trying to get older history items...")
                cooldownTimer.restart()
                chatManager.mediaMessagesModel.triggerLoadMoreHistory()
            }
        }

        VerticalScrollDecorator {}
    }
}
