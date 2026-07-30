//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

QtObject {
    id: user

    property var userId
    property var info: tdData.getUserInformation(userId)
    property alias userInformation: user.info

    onUserIdChanged:
        userInformation = tdData.getUserInformation(userId)
    property Connections __conn: Connections {
        target: tdData
        onUserUpdated:
            if (user.userId == userId) // explicitly allow type correction here!
                user.userInformation = userInformation
    }
}
