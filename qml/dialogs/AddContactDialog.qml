//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property Item rootItem

    property var userId
    property var userInfo: tdData.getUserInformation(userId)
    property bool editing: userInfo && userInfo.is_contact
    property bool requestFullInfo: true
    property alias phone: phoneField.text

    property bool needPhoneNumberPrivacyException

    property alias name: nameField.text
    property alias lastName: lastNameField.text
    property alias note: noteField.text

    canAccept: nameField.acceptableInput && lastNameField.acceptableInput && (!phoneField.visible || phoneField.acceptableInput) && noteField.acceptableInput
    onAccepted: {
        var noteObject = utilities.newFormattedText(note)
        if (userId)
            tdLibWrapper.addContact(userId, name, lastName, phone, noteObject, needPhoneNumberPrivacyException && sharePhoneNumberField.checked)
        else
            tdLibWrapper.importContact(name, lastName, phone, noteObject, '!'+name)
    }

    Component.onCompleted:
        if (userId && requestFullInfo)
            tdLibWrapper.getUserFullInfo(userId)
    Connections {
        target: tdLibWrapper
        onUserFullInfoReceived:
            if (userId === dialog.userId && requestFullInfo) {
                note = utilities.enhanceMessageText(tdLibWrapper.getMarkdownText(userFullInfo.note), true, false)
                needPhoneNumberPrivacyException = userFullInfo.need_phone_number_privacy_exception
                requestFullInfo = false
            }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: editing
            MenuItem {
                text: qsTr("Delete contact")
                onClicked: {
                    var page = pageStack.previousPage()
                    var tdlib = tdLibWrapper, userId = dialog.userId
                    var remorse = Remorse.popupAction(page, qsTr("Contact deleted"), function() { tdlib.removeContact(userId) })
                    if (rootItem) rootItem.remorse = remorse
                    pageStack.pop()
                }
            }
        }

        Column {
            id: column
            width: parent.width

            DialogHeader {}

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("First name")
                text: userInfo.first_name
                acceptableInput: text.length > 0 && text.length <= 64
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: lastNameField.focus = true
                description: errorHighlight ? qsTr("First name must have 1-%Ln characters", '', 64) : ''
            }

            TextField {
                id: lastNameField
                width: parent.width
                label: qsTr("Last name")
                text: userInfo.last_name
                description: errorHighlight ? qsTr("Last name length must be less than %Ln", '', 64) : ''
                acceptableInput: text.length <= 64
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: phoneField.focus = true
            }

            TextSwitch {
                id: sharePhoneNumberField
                visible: !!userId && needPhoneNumberPrivacyException
                text: qsTr("Share my phone number")
                checked: !editing
            }

            TextField {
                id: phoneField
                visible: !userId
                width: parent.width
                label: qsTr("Phone number")
                text: userInfo.phone_number
                description: qsTr("Use the international format, e.g. %1").arg("+4912342424242")
                inputMethodHints: Qt.ImhDialableCharactersOnly
                acceptableInput: text.match(/\+[1-9][0-9 ]{4,}/g)
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: noteField.focus = true
            }

            TextArea {
                id: noteField
                width: parent.width
                label: qsTr("Note")
                property int maxLength: tdData.options.user_note_text_length_max

                property bool acceptableInput: text.length <= maxLength
                onAcceptableInputChanged:
                    if (acceptableInput) errorHighlight = false
                onFocusChanged:
                    if (!focus) errorHighlight = !acceptableInput

                description: errorHighlight ? qsTr("Note length must be less than %Ln", '', maxLength) : qsTr("The note is only visible to you.")
            }
        }
    }
}
