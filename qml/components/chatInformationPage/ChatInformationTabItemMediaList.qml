//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

import ".."
import "../../js/debug.js" as Debug
import "../../js/functions.js" as Functions

ChatInformationTabItemMediaBase {
    id: tabBase
    scrollableView: listView

    property Component messageDelegate

    property alias model: listView.model

    SilicaListView {
        id: listView
        width: tabBase.width
        height: tabBase.height

        delegate: ListItem {
            id: listItem
            contentWidth: parent.width
            contentHeight: messageLoader.height

            property var messageId: model.message_id
            property var message: model.display

            Loader {
                id: messageLoader
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                sourceComponent: messageDelegate

                property alias listItem: listItem
            }

            onClicked:
                if (messageLoader.item && messageLoader.item.clicked)
                    messageLoader.item.clicked()

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Jump to message")
                        onClicked: jumpToMessage(listItem.messageId)
                    }
                }
            }
        }

        Timer {
            id: cooldownTimer
            interval: 2000
            onTriggered: Debug.log("[ChatInformationTabItemMediaList] Cooldown completed...")
        }

        onContentYChanged: {
            if (active && !cooldownTimer.running && listView.indexAt(listView.contentX, listView.contentY) > Math.max(0, listView.count - 10)) {
                Debug.log("[ChatInformationTabItemMediaList] Trying to get older history items...")
                cooldownTimer.restart()
                tabBase.model.loadMoreHistory()
            }
        }

        VerticalScrollDecorator {}
    }
}
