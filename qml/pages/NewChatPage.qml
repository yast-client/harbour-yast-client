//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import Sailfish.Share 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: page
    allowedOrientations: Orientation.All

    property string appDownloadLink
    property bool loading: true

    ShareAction {
        id: inviteShareAction
        title: qsTr("Invite to Telegram")
        mimeType: 'text/plain'
        resources: [{data: qsTr("Hey! I'm using Telegram to chat. Join me! Download it here: %1").arg(appDownloadLink)}]
    }

    Connections {
        target: tdLibWrapper
        onHttpUrlReceived:
            if (extra === 'applicationDownloadLink') appDownloadLink = url

        onContactsImported:
            if (extra.indexOf('!') === 0) {
                if (userIds[0])
                    tdLibWrapper.createPrivateChat(userIds[0], 'openDirectly')
                else
                    appNotification.show(qsTr("Unfortunately %1 has not joined Telegram yet, but you can send them an invitation. We will notify you when any of your contacts join Telegram.")
                                            .arg(extra.slice(1)),
                        inviteShareAction.trigger, qsTr("Invite", "In-app notification button for inviting a user to Telegram"))
            }
    }

    Component.onCompleted: tdLibWrapper.getApplicationDownloadLink()

    ContactSync {
        id: contactSync
    }

    ContactsModel {
        id: contactsModel
        tdlib: tdLibWrapper
        onLoaded: loading = false
    }

    SilicaFlickable {
        contentHeight: parent.height
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                visible: contactSync.canSync
                onClicked: contactSync.sync()
                text: qsTr("Sync contacts")
            }
            MenuItem {
                text: qsTr("Add contact")
                onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AddContactDialog.qml"))
            }
            MenuItem {
                text: contactsModel.sortByStatus ? qsTr("Sort by Name") : qsTr("Sort by Last Seen")
            }
        }

        PageHeader { id: header; title: qsTr("Your Contacts") }

        Item {
            id: contentContainer
            width: parent.width
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }
            opacity: contactSync.syncInProgress ? 0 : 1
            Behavior on opacity { FadeAnimator {} }

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Search contacts")
                active: parent.opacity > 0

                Timer {
                    id: searchTimer
                    interval: 250
                    onTriggered: contactsModel.query = searchField.text
                }

                onTextChanged: {
                    loading = true

                    if (text) searchTimer.restart()
                    else {
                        searchTimer.stop()
                        contactsModel.query = ''
                    }
                }

                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    searchField.focus = false
                    page.focus = true
                }

            }

            SilicaListView {
                id: listView
                model: contactsModel
                clip: true
                width: parent.width
                anchors {
                    top: searchField.bottom
                    bottom: parent.bottom
                }
                opacity: loading ? 0 : 1
                Behavior on opacity { FadeAnimator {} }

                ViewPlaceholder {
                    y: Theme.paddingLarge
                    enabled: !listView.count
                    text: searchField.text ? qsTr("No Results") : qsTr("You don't have any contacts yet")
                    hintText: searchField.text ? qsTr("Try a new search.")
                                               : (contactSync.canSync ? qsTr("Pull down to add a new contact or synchronize existing contacts from your address book.")
                                                                      : qsTr("Pull down to add a new contact"))
                }

                delegate: PhotoTextsListItem {
                    id: contactListItem
                    opacity: visible ? 1 : 0
                    Behavior on opacity { FadeAnimation {} }

                    compact: true

                    pictureThumbnail {
                        photoData: photo_data ? (photo_data.small || {}) : {}
                        minithumbnail: photo_data.minithumbnail
                    }
                    width: parent.width

                    primaryText.text: Emoji.emojify(title, primaryText.font.pixelSize, "../js/emoji/")
                    prologSecondaryText.text: Functions.getChatPartnerStatusText(user_status, user_last_online, is_support, display.id)

                    onClicked: tdLibWrapper.createPrivateChat(display.id, "openDirectly")
                    function remove() {
                        remorseAction(qsTr("Contact removed"), function() { tdLibWrapper.removeContact(user_id) })
                    }
                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                text: qsTr("Secret Chat")
                                onClicked: tdLibWrapper.createNewSecretChat(display.id, "openDirectly")
                            }
                            MenuItem {
                                text: qsTr("Edit")
                                onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AddContactDialog.qml"), {userId: user_id})
                            }
                            MenuItem {
                                text: qsTr("Remove")
                                onClicked: remove()
                            }
                        }
                    }
                }
                property bool __translations: qsTr("Private Chat") + qsTr("Transport-encrypted, uses Telegram Cloud, sharable across devices") + qsTr("End-to-end-encrypted, accessible on this device only")

                VerticalScrollDecorator {}
            }
        }

        BusyLabel {
            anchors.verticalCenter: contentContainer.verticalCenter
            running: contactSync.syncInProgress || loading
            text: qsTr("Loading contacts")
        }
    }
}
