//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import org.nemomobile.contacts 1.0

Item {
    signal syncError

    function synchronize() {
        if (peopleModel.count === 0) {
            appNotification.show(qsTr("Could not synchronize your contacts with Telegram."))
            syncError()
        } else {
            contactsModel.startImportingContacts()
            for (var i = 0; i < peopleModel.count; i++)
                contactsModel.importContact(peopleModel.get(i))
            contactsModel.stopImportingContacts()
        }
    }

    PeopleModel {
        id: peopleModel
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

}
