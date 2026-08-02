//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    property var userId
    property alias phone: phoneField.text

    canAccept: nameField.acceptableInput && lastNameField.acceptableInput && phoneField.acceptableInput && noteField.acceptableInput
    onAccepted: {
        var noteObject = utilities.newFormattedText(noteField.text)
        if (userId)
            tdLibWrapper.addContact(userId, nameField.text, lastNameField.text, phone, noteObject, sharePhoneNumberField.checked)
        else
            tdLibWrapper.importContact(nameField.text, lastNameField.text, phone, noteObject, '!'+nameField.text)
    }

    Column {
        width: parent.width

        DialogHeader {}

        TextField {
            id: nameField
            width: parent.width
            label: qsTr("First name")
            acceptableInput: text.length > 0 && text.length <= 64
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: lastNameField.focus = true
            description: errorHighlight ? qsTr("First name must have 1-%Ln characters", '', 64) : ''
        }

        TextField {
            id: lastNameField
            width: parent.width
            label: qsTr("Last name")
            description: errorHighlight ? qsTr("Last name length must be less than %Ln", '', 64) : ''
            acceptableInput: text.length <= 64
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: phoneField.focus = true
        }

        TextSwitch {
            id: sharePhoneNumberField
            visible: !!userId
            text: qsTr("Share my phone number")
            checked: true
        }

        TextField {
            id: phoneField
            visible: !!!userId
            width: parent.width
            label: qsTr("Phone number")
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

            description: errorHighlight ? qsTr("Note length must be less than %Ln", '', maxLength) : ''
            // TODO: somehow both note wrapping + accept key
            /*EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.enabled: canAccept
            EnterKey.onClicked: accept()*/
        }
    }
}
