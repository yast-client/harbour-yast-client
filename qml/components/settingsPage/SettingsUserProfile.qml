/*
    Copyright (C) 2021 Sebastian J. Wolf and other contributors

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
import Sailfish.Pickers 1.0
import io.yaqtlib 1.0
import "../"
import "../../pages/"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

AccordionItem {
    name: "profile"
    title: qsTr("User Profile")
    Component {
        Column {
            id: accordionContent
            bottomPadding: Theme.paddingMedium

            readonly property var userInformation: tdLibWrapper.userInformation
            property var fullUserInformation: ({})
            property bool contactSyncEnabled: false
            property bool uploadingPhoto

            Component.onCompleted:
                tdLibWrapper.getUserFullInfo(userInformation.id)

            Connections {
                target: tdLibWrapper
                onUserFullInfoReceived:
                    accordionContent.fullUserInformation = userFullInfo
                onUserFullInfoUpdated:
                    accordionContent.fullUserInformation = userFullInfo
                onOkReceived:
                    if (extra === "setProfilePhoto")
                        uploadingPhoto = false
            }

            ResponsiveGrid {
                x: Theme.horizontalPageMargin

                InformationEditArea {
                    id: firstNameEditArea
                    canEdit: true
                    headerText: qsTr("First Name", "first name of the logged-in profile - header")
                    text: userInformation.first_name
                    width: parent.columnWidth
                    headerLeftAligned: true

                    onSaveButtonClicked: {
                        if(!editItem.errorHighlight) {
                            tdLibWrapper.setName(textValue, lastNameEditArea.text)
                        } else {
                            isEditing = true
                        }
                    }

                    onTextEdited: {
                        if(textValue.length > 0 && textValue.length < 65) {
                            editItem.errorHighlight = false
                            editItem.label = ""
                            editItem.placeholderText = ""
                        } else {
                            editItem.label = qsTr("Enter 1-64 characters")
                            editItem.placeholderText = editItem.label
                            editItem.errorHighlight = true
                        }
                    }
                }

                InformationEditArea {
                    id: lastNameEditArea
                    visible: true
                    canEdit: true
                    headerText: qsTr("Last Name", "last name of the logged-in profile - header")
                    text: userInformation.last_name
                    width: parent.columnWidth
                    headerLeftAligned: true

                    onSaveButtonClicked: {
                        if(!editItem.errorHighlight) {
                            tdLibWrapper.setName(firstNameEditArea.text, textValue);
                        } else {
                            isEditing = true;
                        }
                    }

                    onTextEdited: {
                        if(textValue.length >= 0 && textValue.length < 65) {
                            editItem.errorHighlight = false;
                            editItem.label = "";
                            editItem.placeholderText = "";
                        } else {
                            editItem.label = qsTr("Enter 0-64 characters");
                            editItem.placeholderText = editItem.label;
                            editItem.errorHighlight = true;
                        }
                    }
                }

                InformationEditArea {
                    id: userNameEditArea
                    visible: true
                    canEdit: true
                    headerText: qsTr("Username", "user name of the logged-in profile - header")
                    text: userInformation.usernames.editable_username
                    width: parent.columnWidth
                    headerLeftAligned: true

                    onSaveButtonClicked:
                        tdLibWrapper.setUsername(textValue)
                }

                Item {
                    width: parent.columnWidth
                    height: birthdayButton.height + Theme.paddingMedium

                    ValueButton {
                        id: birthdayButton
                        x: -Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        label: qsTr("Birthday")
                        property var birthdate: fullUserInformation.birthdate ? new Date(
                                                                                    fullUserInformation.birthdate.year || 1800,
                                                                                    fullUserInformation.birthdate.month - 1,
                                                                                    fullUserInformation.birthdate.day) : null
                        value: fullUserInformation.birthdate ?
                                   Format.formatDate(birthdate, fullUserInformation.birthdate.year ? Formatter.DateMedium : Formatter.DateMediumWithoutYear)
                                 : qsTr("Add", "Add the birthday to your profile")
                        function getDefaultDate() {
                            var date = new Date()
                            date.setYear(1800)
                            return date
                        }
                        onClicked:
                            pageStack.push(Qt.resolvedUrl("../../dialogs/SetBirthdateDialog.qml"), {date: birthdate || getDefaultDate(), canRemove: !!birthdate})
                    }
                }

                Column {
                    id: contactSyncItem
                    width: parent.columnWidth
                    height: syncInProgress ? ( syncContactsBusyIndicator.height + Theme.paddingMedium ) : ( syncContactsButton.height + Theme.paddingMedium )
                    visible: accordionContent.contactSyncEnabled

                    property bool syncInProgress: false

                    Connections {
                        target: contactSyncLoader.item
                        onSyncError:
                            contactSyncItem.syncInProgress = false
                    }

                    Connections {
                        target: tdLibWrapper
                        onContactsImported:
                            appNotification.show(qsTr("Contacts successfully synchronized with Telegram."))
                    }

                    Button {
                        id: syncContactsButton
                        text: qsTr("Sync contacts")
                        visible: !contactSyncItem.syncInProgress
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: contactSyncLoader.item.synchronize()
                    }

                    BusyIndicator {
                        id: syncContactsBusyIndicator
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: contactSyncItem.syncInProgress
                        size: BusyIndicatorSize.Small
                        visible: running
                    }
                }

            }

            SectionHeader {
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Profile Pictures")
            }

            Row {
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                spacing: Theme.paddingMedium

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width / 2
                    height: Theme.itemSizeExtraLarge

                    ProfileThumbnail {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.itemSizeExtraLarge
                        height: Theme.itemSizeExtraLarge
                        photoData: userInformation.profile_photo.small
                        replacementStringHint: utilities.getUserName(userInformation)
                        radius: parent.width / 2
                        highlighted: profileThumbnailMouseArea.containsPress

                        MouseArea {
                            id: profileThumbnailMouseArea
                            anchors.fill: parent
                            onClicked:
                                pageStack.push(Qt.resolvedUrl("../../pages/ProfilePicturesPage.qml"), {userId: tdLibWrapper.myUserId})
                        }
                    }
                }

                Column {
                    width: parent.width / 2
                    visible: !uploadingPhoto

                    // TODO: avoid size errors by cropping the picture before applying it
                    Button {
                        text: qsTr("Add Picture")
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: {
                            var page = pageStack.push('Sailfish.Pickers.ImagePickerPage')
                            page.selectedContentPropertiesChanged.connect(function () {
                                uploadingPhoto = true
                                tdLibWrapper.setProfilePhoto(page.selectedContentProperties.filePath)
                            })
                        }
                    }
                }

                Column {
                    visible: uploadingPhoto
                    spacing: Theme.paddingMedium
                    width: parent.width / 2

                    Text {
                        id: uploadingText
                        font.pixelSize: Theme.fontSizeSmall
                        text: qsTr("Uploading…")
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.secondaryColor
                        width: parent.width
                    }

                    BusyIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: uploadingPhoto
                        size: BusyIndicatorSize.Medium
                    }
                }

            }

            Loader {
                id: contactSyncLoader
                source: Qt.resolvedUrl('../ContactSync.qml')
                active: true
                onLoaded:
                    accordionContent.contactSyncEnabled = true
            }

            Column {

                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    height: Theme.fontSizeExtraLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    text: qsTr("Phone number: +%1").arg(userInformation.phone_number)
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Button {
                    id: logOutButton
                    text: qsTr("Log Out")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: Remorse.popupAction(settingsPage, qsTr("Logged out"), function() {
                        tdLibWrapper.logout();
                        pageStack.pop();
                    });
                }

            }
        }
    }
}
