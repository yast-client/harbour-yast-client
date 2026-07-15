//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    property var userId
    property alias phone: phoneField.text
    property bool userIdAvailable: typeof userId !== 'undefined'

    canAccept: nameField.acceptableInput && lastNameField.acceptableInput && phoneField.acceptableInput
    onAccepted: {
        if (userIdAvailable)
            tdLibWrapper.addContact(phone, nameField.text, lastNameField.text, userId, sharePhoneNumberField.checked)
        else {
            contactsModel.startImportingContacts()
            contactsModel.importContact(nameField.text, lastNameField.text, phone)
            contactsModel.stopImportingContacts(true)
        }
    }

    Column {
        width: parent.width

        DialogHeader {}

        TextField {
            id: nameField
            width: parent.width
            label: qsTr("First name")
            // in TDLib documentation it says 1-255 but it seems to only accept 1-64 (which is also what it says in setName documentation)
            acceptableInput: text.length > 0 && text.length <= 255
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: lastNameField.focus = true
            description: errorHighlight ? qsTr("First name must have 1-255 characters") : ''
        }

        TextField {
            id: lastNameField
            width: parent.width
            label: qsTr("Last name")
            // here it says nothing in the doumentation...
            acceptableInput: text.length <= 255
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: phoneField.focus = true
            description: errorHighlight ? qsTr("Last name length must be less than 256") : ''
        }

        TextSwitch {
            id: sharePhoneNumberField
            visible: userIdAvailable
            text: qsTr("Share my phone number")
            checked: true
        }

        TextField {
            id: phoneField
            visible: !userIdAvailable
            width: parent.width
            label: qsTr("Phone number")
            description: qsTr("Use the international format, e.g. %1").arg("+4912342424242")
            inputMethodHints: Qt.ImhDialableCharactersOnly
            acceptableInput: text.match(/\+[1-9][0-9 ]{4,}/g)
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.enabled: canAccept
            EnterKey.onClicked: accept()
        }
    }
}
