//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: page
    allowedOrientations: Orientation.All

    Component.onDestruction: contactsModel.setFilterWildcard('*')

    Connections {
        target: contactsModel
        onContactsImported: {
            busyLabel.running = false
            appNotification.show(qsTr("Contacts successfully synchronized with Telegram."))
        }
        onSingleContactAdded: tdLibWrapper.createPrivateChat(userId, 'openDirectly')
        onContactNotFound: appNotification.show(qsTr("contact has not joined telegram yet")) // todo: show contact's name
    }

    ContactSync {
        id: contactSync
        onSyncError: busyLabel.running = false
    }

    SilicaFlickable {
        contentHeight: parent.height
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                onClicked: {
                    busyLabel.running = true
                    contactSync.synchronize()
                    // Success message is not fired before TDLib returned "Contacts imported" (see above)
                }
                text: qsTr("Synchronize Contacts with Telegram")
            }
            MenuItem {
                text: qsTr("Add contact")
                onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AddContactDialog.qml"))
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
            visible: !busyLabel.running
            opacity: visible ? 1 : 0
            Behavior on opacity { FadeAnimator {} }

            SearchField {
                id: search
                width: parent.width
                placeholderText: qsTr("Search a contact")
                active: parent.visible // `visible` doesn't work because changing `active` affects `visible`

                onTextChanged: contactsModel.setFilterWildcard("*" + text + "*")

                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    search.focus = false
                    page.focus = true
                }

            }

            SilicaListView {
                id: listView
                model: contactsModel
                clip: true
                width: parent.width
                anchors {
                    top: search.bottom
                    bottom: parent.bottom
                }

                signal newChatInitiated (int currentIndex)

                ViewPlaceholder {
                    y: Theme.paddingLarge
                    enabled: !listView.count
                    text: search.text ? qsTr("No contacts found.") : qsTr("You don't have any contacts.")
                }

                delegate: PhotoTextsListItem {
                    id: contactListItem

                    opacity: visible ? 1 : 0
                    Behavior on opacity { FadeAnimation {} }

                    pictureThumbnail {
                        photoData: photo_data ? (photo_data.small || {}) : {}
                        minithumbnail: photo_data.minithumbnail
                    }
                    width: parent.width

                    primaryText.text: Emoji.emojify(title, primaryText.font.pixelSize, "../js/emoji/")
                    prologSecondaryText.text: "@" + ( username !== "" ? username : user_id )
                    tertiaryText {
                        maximumLineCount: 1
                        text: Functions.getChatPartnerStatusText(user_status, user_last_online, is_support, display.id);
                    }

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
            id: busyLabel
            anchors.verticalCenter: contentContainer.verticalCenter
            text: qsTr("Loading contacts")
        }
    }
}
