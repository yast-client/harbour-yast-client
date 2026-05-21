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
import io.libfernie 1.0
import Opal.SortFilterProxyModel 1.0
import "../components"

import "../components/messageContent/mediaAlbumPage"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: page

    property var chatManager
    property var message // despite the name, can be either a message or a photo object
    property var messageId: message ? message.id : 0
    property alias overlay: overlay
    property alias overlayActive: overlay.active
    property alias pagedView: pagedView
    property alias index: pagedView.currentIndex
    property alias count: pagedView.count
    property alias delegate: pagedView.delegate
    property bool singleElement: false
    property bool modelIsMedia: !singleElement
    property alias initializeMediaModel: mediaMessagesModelLoader.active
    property int searchMessagesFilter
    property alias model: pagedView.model
    // message.content.caption.text
    palette.colorScheme: Theme.LightOnDark
    clip: status !== PageStatus.Active || pageStack.dragInProgress
    navigationStyle: PageNavigation.Vertical
    backgroundColor: 'black'
    allowedOrientations: Orientation.All

    function goToScrollPosition() {
        // only called when model is media model
        var i = model.calculateScrollPosition()
        Debug.log("[MediaAlbumPage] Going to scroll position", i)
        if (i !== -1)
            pagedView.currentIndex = i
    }

    Connections {
        target: modelIsMedia ? model : null
        ignoreUnknownSignals: true
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
        model: singleElement ? [message] : mediaMessagesModelLoader.item
        wrapMode: PagedView.NoWrap
        direction: PagedView.RightToLeft

        // don't move this out of the pagedView data, otherwise will crash when closing the page due to a bug in PagedView
        Loader {
            id: mediaMessagesModelLoader
            active: modelIsMedia && searchMessagesFilter
            asynchronous: true
            sourceComponent: Component {
                InvertedMediaMessagesModel {
                    tdlib: tdLibWrapper
                    filter: searchMessagesFilter
                    Component.onCompleted: init(chatManager.chatId, messageId)
                }
            }
        }

        delegate: Component {
            Loader {
                id: loader
                asynchronous: true
                visible: status == Loader.Ready
                width: PagedView.contentWidth
                height: PagedView.contentHeight
                property var _model: modelIsMedia ? display : model.modelData

                states: [
                    State {
                        when: _model['@type'] === 'photo' || _model.content['@type'] === 'messagePhoto'
                        PropertyChanges {
                            target: loader
                            source: "../components/messageContent/mediaAlbumPage/PhotoComponent.qml"
                        }
                    },
                    State {
                        when: _model.content['@type'] === 'messageVideo' || _model.content['@type'] === 'messageAnimation' || _model.content['@type'] === 'messageVideoNote'
                        PropertyChanges {
                            target: loader
                            source: "../components/messageContent/mediaAlbumPage/VideoComponent.qml"
                        }
                    }
                ]
            }
        }

        onCurrentIndexChanged: {
            if (!modelIsMedia) return

            if (currentIndex <= 10)
                model.loadMoreFuture()
            else if (currentIndex >= count - 1 - 10)
                model.loadMoreHistory()
        }
    }

    // overlay
    FullscreenOverlay {
        id: overlay
        active: count > 0
        currentIndex: page.index
        message: (modelIsMedia && pagedView.currentItem) ? pagedView.currentItem._model : page.message
        hidePreview: singleElement
        forwardButtonVisible: !(singleElement && message && message['@type'] === 'photo')
        previewModel: modelIsMedia ? previewModelLoader.item : null
        previewCurrentIndex: previewModel ? previewModel.mapFromSource(page.index) : -1
        previewInverted: pagedView.direction == PagedView.RightToLeft

        Loader {
            id: previewModelLoader
            active: modelIsMedia && overlay.message.media_album_id !== '0'
            sourceComponent: Component {
                SortFilterProxyModel {
                    sourceModel: page.model
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
