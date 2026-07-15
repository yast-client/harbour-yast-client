//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../js/functions.js" as Functions

CoverBackground {
    id: coverPage
    readonly property bool authenticated: tdLibWrapper.authorizationState === TDLibAPI.AuthorizationReady

    CoverBackgroundImage {}

    Column {
        anchors.fill: parent
        anchors.margins: Theme.paddingLarge
        spacing: Theme.paddingMedium
        visible: coverPage.authenticated
        Row {
            width: parent.width
            spacing: Theme.paddingMedium
            Text {
                id: unreadMessagesCountText
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.primaryColor
                text: Functions.getShortenedCount(chatListModel.unreadMessageCount)
            }
            Label {
                text: qsTr("unread messages", "", chatListModel.unreadMessageCount)
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - unreadMessagesCountText.width - Theme.paddingMedium
                wrapMode: Text.Wrap
                anchors.verticalCenter: unreadMessagesCountText.verticalCenter
                maximumLineCount: 2
                truncationMode: TruncationMode.Fade
            }
        }

        Row {
            width: parent.width
            spacing: Theme.paddingMedium
            visible: coverPage.authenticated && chatListModel.unreadMessageCount > 1
            Text {
                id: inText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                text: qsTr("in")
                anchors.verticalCenter: unreadChatsCountText.verticalCenter
            }
            Text {
                id: unreadChatsCountText
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.primaryColor
                text: Functions.getShortenedCount(chatListModel.unreadChatCount)
            }
            Text {
                text: qsTr("chats", "", chatListModel.unreadChatCount)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                width: parent.width - unreadChatsCountText.width - inText.width - ( 2 * Theme.paddingMedium )
                wrapMode: Text.Wrap
                anchors.verticalCenter: unreadChatsCountText.verticalCenter
            }
        }

        Text {
            id: connectionStateText
            text: tdLibWrapper.connectionStateText || qsTr("Connected")
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            visible: coverPage.authenticated
            width: parent.width
            maximumLineCount: 3
            wrapMode: Text.Wrap
        }
    }

}
