//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components/tdlib'
import '../js/functions.js' as Functions
import '../js/debug.js' as Debug

Page {
    id: page

    property var chatId
    property bool isChannel: tdLibWrapper.getChat(chatId).type.is_channel

    property bool loading: true

    BusyLabel {
        id: busyLabel
        running: loading && view.count == 0
    }

    SilicaListView {
        id: view
        anchors.fill: parent
        opacity: loading ? 0 : 1
        Behavior on opacity { FadeAnimator {} }

        property string searchQuery: headerItem ? headerItem.searchField.text : ''
        property bool inCooldown

        Timer {
            id: resetCooldownTimer
            interval: 2000
            onTriggered: {
                Debug.log("[ChatPendingJoinRequestsPage] Cooldown completed")
                view.inCooldown = false
            }
        }

        function load(from) {
            if (inCooldown) return
            tdLibWrapper.getChatJoinRequests(chatId, from, searchQuery)
        }

        Component.onCompleted: load()

        PullDownMenu {
            MenuItem {
                text: qsTr("Decline all", "decline all join requests")
                onClicked: Remorse.popupAction(page, qsTr("Declined all join requests", "remorse"), function() {
                    tdLibWrapper.processChatJoinRequests(chatId, false)
                    pageStack.pop()
                })
            }

            MenuItem {
                text: qsTr("Accept all", "accept all join requests")
                onClicked: Remorse.popupAction(page, qsTr("Accepted all join requests", "remorse"), function() {
                    tdLibWrapper.processChatJoinRequests(chatId, true)
                    pageStack.pop()
                })
            }
        }

        currentIndex: -1 // don't stel focus from search field

        header: Column {
            width: parent.width

            property alias searchField: searchField

            PageHeader {
                title: qsTr("Join Requests")
            }

            SearchField {
                id: searchField
                width: parent.width

                Timer {
                    id: searchTimer
                    interval: 250
                    onTriggered: {
                        listModel.clear()
                        page.loading = true
                        view.load()
                    }
                }

                onTextChanged: searchTimer.restart()
            }
        }

        ViewPlaceholder {
            enabled: view.count == 0
            text: qsTr("No join requests")
            hintText: qsTr("Wait for someone to send a join request")
            // should be very rare (only if the user opens the page when there are no join requests somehow)
        }

        model: ListModel {
            id: listModel

            function doRemove(i) {
                remove(i)
                if (count == 0)
                    pageStack.pop()
            }
        }

        Connections {
            target: tdLibWrapper
            onChatJoinRequestsReceived: {
                Debug.log("[ChatPendingJoinRequestsPage] Received", totalCount)

                if (chatId !== page.chatId) return

                loading = false
                if (requests.length == 0) {
                    // enable cooldown and don't disable it
                    Debug.log("[ChatPendingJoinRequestsPage] End reached")
                    view.inCooldown = true
                    resetCooldownTimer.stop()
                    return
                }

                for (var i=0; i < requests.length; i++)
                    listModel.append(requests[i])

                resetCooldownTimer.restart()
            }
        }

        delegate: PhotoTextsListItem {
            compact: true
            pictureThumbnail.photoData: user.info.profile_photo.small
            primaryText.text: utilities.getUserName(user.info)
            // FIXME: should we use Timepoint instead of TimepointRelative here?
            secondaryText.text: qsTr("requested to join %1", "Indicates when a user sent the join request").arg(Functions.getDateTimeTimepointRelative(date))

            TDLibUser {
                id: user
                userId: user_id
            }

            function process(approve) {
                tdLibWrapper.processChatJoinRequest(chatId, user_id, approve)
                listModel.doRemove(index)
            }

            onClicked: openMenu()
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: isChannel ? qsTr("Add to Channel", "button: accept a chat join request") : qsTr("Add to Group", "button: accept a chat join request")
                        onClicked: process(true)
                    }
                    MenuItem {
                        text: qsTr("Decline", "decline a chat join request")
                        onClicked: process(false)
                    }
                }
            }
        }

        onContentYChanged: {
            if (view.inCooldown || view.count == 0) return

            var i = view.indexAt(view.contentX, view.contentY + view.height)
            if (i === -1 || i > Math.max(0, view.count - 10)) {
                Debug.log("[ChatPendingJoinRequestsPage] Loading more")

                var request = listModel.get(listModel.count - 1)
                var requestObject = {user_id: request.user_id, date: request.date}
                if (request.bio) requestObject.bio = request.bio
                load(userObject)
            }
        }
    }
}
