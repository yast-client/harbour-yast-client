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
    property alias headerTitle: header.title
    property alias headerDescription: header.description

    property var currentDepth: pageStack.depth

    /*
        payload dependent on chatSelectionPage.state
         - forwardMessages: {fromChatId, messageIds, neededPermissions}
    */
    property var payload: ({})

    property bool search

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
        id: header
        y: Math.max(0, -tabView.pulleyYOffset)
        title: qsTr("Select Chat")
    }

    ChatFoldersViewBase {
        id: tabView
        anchors.fill: parent
        extraTopMargin: header.height
        interactive: !canAccept

        tabComponent: Component {
            ChatFolderTabBase {
                id: tabItem
                /*MouseArea {
                    parent: flickable
                    y: header.y
                    width: header.width
                    height: header.height
                    onClicked: clickTitleBar()
                }
                MouseArea {
                    parent: flickable
                    x: proxySettingsButton.x
                    y: proxySettingsButton.y
                    width: proxySettingsButton.width
                    height: proxySettingsButton.height
                    enabled: proxySettingsButton.enabled
                    onClicked: openProxySettings()

                    // not sure why but Binding didn't work
                    onContainsPressChanged:
                        if (isCurrentItem)
                            proxySettingsButton.externalMouseAreaDown = containsPress
                }*/

                PullDownMenu {
                    parent: tabItem.flickable
                    MenuItem {
                        text: qsTr("Search")
                        onClicked: pageStack.push("") // todo
                    }
                }

                chatsModel: ChatPermissionFilterModel {
                    tdlib: tdLibWrapper
                    sourceModel: tabModel.chat_list_model
                    requirePermissions: chatSelectionPage.payload.neededPermissions
                }
                chatsSourceModel: tabModel.chat_list_model

                delegate: ChatListViewItem {
                    menuComponent: null
                    onClicked: {
                        switch (chatSelectionPage.state) {
                        case "forwardMessages":
                        case "fillTextArea":
                            chatSelectionPage.acceptDestinationProperties = {chatId: display.id}
                            chatSelectionPage.acceptDestination = Qt.resolvedUrl("../pages/ChatPage.qml")
                            break
                        }
                        chatSelectionPage.canAccept = true
                        chatSelectionPage.accept()
                    }
                }
            }
        }
    }
}
