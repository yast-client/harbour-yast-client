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
import Opal.SortFilterProxyModel 1.0
import "../components"

import "../components/messageContent/mediaAlbumPage"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: page

    property var message
    property var messageId: message ? message.id : 0
    property alias overlayActive: overlay.active
    property alias index: pagedView.currentIndex
    property alias delegate: pagedView.delegate
    property alias model: pagedView.model
    property var messages: []
    // message.content.caption.text
    palette.colorScheme: Theme.LightOnDark
    clip: status !== PageStatus.Active || pageStack.dragInProgress
    navigationStyle: PageNavigation.Vertical
    backgroundColor: 'black'
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        chatManager.initializeMediaMessagesModel(messageId)
    }
    Component.onDestruction: {
        // if end is reached model could be re-used in the media chat information tab
        if (!chatManager.mediaMessagesModel.endReached)
            chatManager.mediaMessagesModel.clear()
    }

    function goToScrollPosition() {
        var i = chatManager.mediaMessagesModel.calculateScrollPosition()
        Debug.log("[MediaAlbumPage] Going to scroll position", i)
        if (i !== -1)
            pagedView.currentIndex = i
    }

    Connections {
        target: chatManager.mediaMessagesModel
        onMessagesReceived:
            if (!fromIncrementalUpdate)
                goToScrollPosition()
        onAlreadyLoaded:
            goToScrollPosition()
    }

    // content
    PagedView {
        id: pagedView
        anchors.fill: parent
        model: chatManager.mediaMessagesModel
        wrapMode: PagedView.NoWrap
        delegate: Component {
            Loader {
                id: loader
                asynchronous: true
                visible: status == Loader.Ready
                width: PagedView.contentWidth
                height: PagedView.contentHeight
                property var _model: display

                states: [
                    State {
                        when: display.content['@type'] === 'messagePhoto'
                        PropertyChanges {
                            target: loader
                            source: "../components/messageContent/mediaAlbumPage/PhotoComponent.qml"
                        }
                    },
                    State {
                        when: display.content['@type'] === 'messageVideo' || model.modelData.content['@type'] === 'messageAnimation' || model.modelData.content['@type'] === 'messageVideoNote'
                        PropertyChanges {
                            target: loader
                            source: "../components/messageContent/mediaAlbumPage/VideoComponent.qml"
                        }
                    }
                ]
            }
        }

        onCurrentIndexChanged: {
            if (currentIndex <= 10)
                chatManager.mediaMessagesModel.loadMoreHistory()
            else if (currentIndex >= count - 1 - 10)
                chatManager.mediaMessagesModel.loadMoreFuture()
        }
    }

    // overlay
    FullscreenOverlay {
        id: overlay
        pageCount: messages.length
        currentIndex: page.index
        message: pagedView.currentItem ? pagedView.currentItem._model : page.message
        previewModel: previewModelLoader.item

        Loader {
            id: previewModelLoader
            active: overlay.message.media_album_id !== '0'
            sourceComponent: Component {
                SortFilterProxyModel {
                    sourceModel: chatManager.mediaMessagesModel
                    filters: ValueFilter {
                        roleName: 'album_id'
                        value: overlay.message.media_album_id
                    }
                }
            }
        }

        onJumpedToIndex: page.index = index
    }
}
