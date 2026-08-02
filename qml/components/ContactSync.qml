//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import org.nemomobile.contacts 1.0

// NOTE: Contacts permission seems to be broken in Sailjail
// A workaround which seems to work is adding the Privileged permission,
// which is used in non-harbour builds

QtObject {
    readonly property bool canSync: peopleModel.count != 0
    property bool syncInProgress

    property PeopleModel peopleModel: PeopleModel {
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    property Connections __tdConn: Connections {
        target: tdLibWrapper
        onContactsImported: {
            if (extra !== 'contacts') return

            syncInProgress = false
            var count = 0
            for (var i=0; i < userIds.length; i++)
                if (i) count++
            if (count)
                appNotification.show(qsTr("Synced %Ln contacts", "", count))
            else appNotification.show(qsTr("Failed to sync contacts"))
        }
    }

    function sync() {
        if (!canSync) return

        syncInProgress = true
        var contacts = []
        for (var i=0; i < peopleModel.count; i++) {
            var person = peopleModel.get(i)
            for (var j=0; j < person.phoneNumbers.length; j++) {
                var note = ''
                for (var k=0; k < person.noteDetails.length; k++) {
                    var noteData = person.noteDetails[k]
                    if (noteData.type === Person.NoteType) {
                        note = noteData.note
                        break
                    }
                }

                contacts.push(utilities.makeImportedContact(
                    person.firstName, person.lastName, person.phoneNumbers[j], utilities.newFormattedText(note)))
            }
        }
        tdLibWrapper.importContacts(contacts, 'contacts')
    }
}
