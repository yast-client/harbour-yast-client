//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/chatList"
import Opal.MenuSwitch 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Dialog {
    id: page
    allowedOrientations: Orientation.All
    acceptDestinationAction: PageStackAction.Replace
    canAccept: false
    property alias headerTitle: header.title
    property alias headerDescription: header.description

    property var currentDepth: pageStack.depth

    /*
        payload dependent on page.state
         - forwardMessages: {fromChatId, messageIds, neededPermissions, canForward, canCopy, canCopyToSecretChat}
           (canForward, canCopy and canCopyToSecretChat cannot all be false)
         - fillTextArea: {text}
    */
    property var payload: ({})

    // forwardMessages
    property int forwardAdditionalFilter:
        if (state == 'forwardMessages' && forwardCopySwitch.checked) {
            if (payload.canCopy && payload.canCopyToSecretChat)
                return ChatPermissionFilterModel.AdditionalFilterNone
            return payload.canCopyToSecretChat ? ChatPermissionFilterModel.AdditionalFilterSecretOnly
                                               : ChatPermissionFilterModel.AdditionalFilterNonSecret
        } else return ChatPermissionFilterModel.AdditionalFilterNone

    property bool search

    function selectChat(chatId) {
        switch (page.state) {
        case "forwardMessages":
        case "fillTextArea":
            acceptDestinationProperties = {chatId: chatId}
            acceptDestination = Qt.resolvedUrl("ChatPage.qml")
            break
        }
        canAccept = true
        accept()
    }

    onAccepted:
        switch (page.state) {
        case "forwardMessages":
            acceptDestinationInstance.forwardMessages(payload.fromChatId, payload.messageIds, forwardCopySwitch.checked, forwardRemoveCaptionSwitch.checked)
            break
        case "fillTextArea": // ReplyMarkupButtons: inlineKeyboardButtonTypeSwitchInline
            acceptDestinationInstance.setMessageText(payload.text)
            break
        // future uses of chat selection can be processed here
        }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: pulley
            // can't use forwardCopySwitch.visible (binding loop since visible depends on parent's visible value)
            visible: forwardCopySwitch.active || !search

            MenuSwitch {
                id: forwardCopySwitch

                property bool active: page.state == 'forwardMessages' && (payload.canCopy || payload.canCopyToSecretChat)
                visible: active

                enabled: payload.canForward
                text: qsTr("Hide Sender Name")
                checked: !payload.canForward
                onCheckedChanged:
                    if (!checked) forwardRemoveCaptionSwitch.checked = false
            }
            MenuSwitch {
                // TODO: for returning this we need to hide it when no caption is available
                id: forwardRemoveCaptionSwitch
                visible: false//forwardCopySwitch.active
                enabled: forwardCopySwitch.enabled
                text: qsTr("Hide Caption")
                onCheckedChanged:
                    if (checked) forwardCopySwitch.checked = true
            }

            MenuItem {
                id: searchMenuItem
                visible: !search
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("ChatSelectionPage.qml"), {
                                                             headerTitle: headerTitle, headerDescription: headerDescription,
                                                             state: page.state, payload: payload,
                                                             search: true,
                                                             acceptDestinationReplaceTarget: pageStack.previousPage(page)
                                                         })
            }
        }

        PageHeader {
            id: header
            title: qsTr("Select Chat")
        }

        Loader {
            id: loader
            width: parent.width
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }
            sourceComponent: search ? searchComponent : chatsComponent
        }
    }

    Component {
        id: chatsComponent
        ChatFoldersViewBase {
            id: tabView
            anchors.fill: parent
            interactive: !canAccept
            wrapMode: PagedView.NoWrap

            tabComponent: Component {
                ChatFolderTabBase {
                    fillFlickable: false

                    chatsModel: ChatPermissionFilterModel {
                        tdlib: tdLibWrapper
                        sourceModel: tabModel.chat_list_model
                        requirePermissions: page.payload.neededPermissions
                        additionalFilter: forwardAdditionalFilter
                    }
                    chatsSourceModel: tabModel.chat_list_model

                    delegate: ChatListViewItem {
                        // TODO: selecting multiple chats
                        menuComponent: null
                        onClicked: selectChat(chat_id)
                    }
                }
            }
        }
    }

    Component {
        id: searchComponent
        SearchChatsView {
            remorseParent: page

            requirePermissions: page.payload.neededPermissions
            additionalFilter: forwardAdditionalFilter

            openOnSelected: false
            onChatSelected: selectChat(chatId)
        }
    }
}
