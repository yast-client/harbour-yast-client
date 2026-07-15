//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components/chatList"

import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Dialog {
    id: chatSelectionPage
    allowedOrientations: Orientation.All
    canAccept: false
    acceptDestinationAction: PageStackAction.Replace
    acceptDestinationReplaceTarget: pageStack.find( function(page){
        // This crazy workaround is presented to you by a bug introduced with SFOS 4.0.1
        // See https://forum.sailfishos.org/t/4-0-1-45-pagestack-find-not-working-properly-anymore-in-a-dialog/4723 for details.
        chatSelectionPage.currentDepth = chatSelectionPage.currentDepth - 1;
        return(chatSelectionPage.currentDepth === 0);
    } )
    property alias headerTitle: pageHeader.title
    property alias headerDescription: pageHeader.description

    property var currentDepth: pageStack.depth

    /*
        payload dependent on chatSelectionPage.state
         - forwardMessages: {fromChatId, messageIds, neededPermissions}
    */
    property var payload: ({})

    onAccepted: {
        switch(chatSelectionPage.state) {
        case "forwardMessages":
            acceptDestinationInstance.forwardMessages(payload.fromChatId, payload.messageIds)
            break;
        case "fillTextArea": // ReplyMarkupButtons: inlineKeyboardButtonTypeSwitchInline
            acceptDestinationInstance.setMessageText(payload.text)
            break;
        // future uses of chat selection can be processed here
        }
    }

    PageHeader {
        id: pageHeader
        title: qsTr("Select Chat")
        width: parent.width
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

        model: ChatPermissionFilterModel {
            tdlib: tdLibWrapper
            sourceModel: chatListModel
            requirePermissions: chatSelectionPage.payload.neededPermissions
        }

        delegate: ChatListViewItem {
            onClicked: {
                var chat = tdLibWrapper.getChat(display.id);
                switch(chatSelectionPage.state) {
                case "forwardMessages":
                case "fillTextArea":
                    chatSelectionPage.acceptDestinationProperties = { "chatInformation" :  chat};
                    chatSelectionPage.acceptDestination = Qt.resolvedUrl("../pages/ChatPage.qml");
                    break;
                }
                chatSelectionPage.canAccept = true;
                chatSelectionPage.accept();
            }
        }

        ViewPlaceholder {
            enabled: chatListView.count === 0
            text: qsTr("You don't have any chats yet.")
        }

        VerticalScrollDecorator {}
    }
}
