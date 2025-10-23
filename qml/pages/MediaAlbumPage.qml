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
import "../components"

import "../components/messageContent/mediaAlbumPage"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Page {
    // id
    id: page
    // property declarations

    property alias index: pagedView.currentIndex
    property alias overlayActive: overlay.active
    property alias delegate: pagedView.delegate
    property var messages: []
    // message.content.caption.text
    palette.colorScheme: Theme.LightOnDark
    clip: status !== PageStatus.Active || pageStack.dragInProgress
    navigationStyle: PageNavigation.Vertical
    backgroundColor: 'black'
    allowedOrientations: Orientation.All
    // signal declarations
    // JavaScript functions

    // object (parent) properties
    // large property bindings
    // child objects
    // states
    // transitions


    Component.onCompleted: {
        var messageId = messages[index].id
        var i = chatManager.mediaMessagesModel.getMessageIndex(messageId)
        if (i !== -1) index = i
        else // Required message isn't loaded
            chatManager.initializeMediaMessagesModel(messageId)
    }

    function jumpToMessage(messageId, initialRun) {
        chatManager.mediaMessagesModel.getMessageIndex()
    }

    Connections {
        target: chatManager.mediaMessagesModel
        onMessagesReceived: {
            if (!fromIncrementalUpdate) {
                var i = chatManager.mediaMessagesModel.calculateScrollPosition()
                if (i !== -1)
                    pagedView.currentIndex = i
            }
            console.log(pagedView.currentIndex)
        }
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
            // TODO
        }
    }
    Button {
        text: "Jump to first in album"
        onClicked: {
            var i = chatManager.mediaMessagesModel.getMessageIndex(messages[0].id)
            text = "Jump to first in album " + i
            pagedView.currentIndex = i
        }
    }

    // overlay
    FullscreenOverlay {
        id: overlay
        pageCount: messages.length
        currentIndex: page.index
        message: pagedView.currentItem ? pagedView.currentItem._model : messages[0]//messages[currentIndex]

        Button {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: overlay.message.id + "  " + pagedView.currentIndex
        }
    }
}
