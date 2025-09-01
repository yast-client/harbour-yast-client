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
import WerkWolf.Fernschreiber 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

SilicaFlickable {
    id: overviewContainer
    contentHeight: parent.height
    contentWidth: parent.width
    anchors.fill: parent
    visible: !overviewPage.loading

    property string headerText: qsTr("Ferniegram")
    property var model
    //property bool replacePage
    property bool inArchive

    TextFilterModel {
        id: chatListProxyModel
        sourceModel: (chatSearchField.opacity > 0) ? overviewContainer.model : null
        filterRoleName: "filter"
        filterText: chatSearchField.text
    }

    function resetFocus() {
        if (chatSearchField.text === "") {
            chatSearchField.opacity = 0.0;
            pageHeader.opacity = 1.0;
        }
        chatSearchField.focus = false;
        overviewPage.focus = true;
    }

    Connections {
        target: overviewPage
        onScrollToTopRequired: chatListView.scrollToTop()
    }

    PageHeader {
        id: pageHeader
        title: headerText
        leftMargin: Theme.itemSizeMedium
        visible: opacity > 0
        Behavior on opacity { FadeAnimation {} }

        GlassItem {
            id: pageStatus
            width: Theme.itemSizeMedium
            height: Theme.itemSizeMedium
            color: "red"
            falloffRadius: 0.1
            radius: 0.2
            cache: false
            anchors.bottom: parent.bottom
        }

        states: [
            State {
                name: "WaitingForNetwork"
                when: tdLibWrapper.connectionState == TDLibWrapper.WaitingForNetwork
                PropertyChanges { target: pageStatus; color: "red" }
                PropertyChanges { target: pageHeader; title: qsTr("Waiting for network...") }
            },
            State {
                name: "Connecting"
                when: tdLibWrapper.connectionState == TDLibWrapper.Connecting
                PropertyChanges { target: pageStatus; color: "gold" }
                PropertyChanges { target: pageHeader; title: qsTr("Connecting to network...") }
            },
            State {
                name: "ConnectingToProxy"
                when: tdLibWrapper.connectionState == TDLibWrapper.ConnectingToProxy
                PropertyChanges { target: pageStatus; color: "gold" }
                PropertyChanges { target: pageHeader; title: qsTr("Connecting to proxy...") }
            },
            State {
                name: "ConnectionReady"
                when: tdLibWrapper.connectionState == TDLibWrapper.ConnectionReady
                PropertyChanges { target: pageStatus; color: "green" }
                PropertyChanges { target: pageHeader; title: overviewContainer.headerText }
            },
            State {
                name: "Updating"
                when: tdLibWrapper.connectionState == TDLibWrapper.Updating
                PropertyChanges { target: pageStatus; color: "lightblue" }
                PropertyChanges { target: pageHeader; title: qsTr("Updating content...") }
            }
        ]

        MouseArea {
            anchors.fill: parent
            onClicked: {
                chatSearchField.focus = true;
                chatSearchField.opacity = 1.0;
                pageHeader.opacity = 0.0;
            }
        }

    }

    SearchField {
        id: chatSearchField
        visible: opacity > 0
        opacity: 0
        Behavior on opacity { FadeAnimation {} }
        width: parent.width
        height: pageHeader.height
        placeholderText: qsTr("Filter your chats...")
        canHide: text === ""

        onHideClicked: {
            resetFocus();
        }

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            resetFocus();
        }
    }

    SilicaListView {
        id: chatListView
        anchors {
            top: pageHeader.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        clip: true
        opacity: (overviewPage.chatListCreated && !overviewPage.logoutLoading) ? 1 : 0
        Behavior on opacity { FadeAnimation {} }
        model: chatListProxyModel.sourceModel ? chatListProxyModel : overviewContainer.model
        delegate: ChatListViewItem {
            ownUserId: overviewPage.ownUserId
            verificationStatus: verification_status
            inArchive: overviewContainer.inArchive
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../pages/ChatPage.qml"), {
                    chatInformation : display,
                    chatPicture: photo_small
                })
            }
        }

        ViewPlaceholder {
            enabled: chatListView.count === 0
            text: overviewContainer.model.count === 0 ? qsTr("You don't have any chats yet.") : qsTr("No matching chats found.")
            hintText: qsTr("You can search public chats or create a new chat via the pull-down menu.")
        }

        VerticalScrollDecorator {}
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium
        anchors.verticalCenter: chatListView.verticalCenter

        opacity: overviewPage.chatListCreated && !overviewPage.logoutLoading ? 0 : 1
        Behavior on opacity { FadeAnimation {} }
        visible: !overviewPage.chatListCreated || overviewPage.logoutLoading

        BusyLabel {
            id: loadingBusyIndicator
            running: true
            text: overviewPage.loadingText
        }
    }

    InteractionHintLabel {
        id: titleInteractionHint
        text: qsTr("Tap on the title bar to filter your chats")
        visible: opacity > 0
        invert: true
        anchors.fill: parent
        Behavior on opacity { FadeAnimation {} }
        opacity: overviewPage.titleInteractionHintActive ? 1 : 0
    }
}
