//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

QtObject {
    id: user

    property var userId
    property var info: tdLibWrapper.getUserInformation(userId)
    property alias userInformation: user.info

    onUserIdChanged:
        userInformation = tdLibWrapper.getUserInformation(userId)
    property Connections __tdLibWrapperConnections: Connections {
        target: tdLibWrapper
        onUserUpdated:
            if (user.userId == userId) // explicitly allow type correction here!
                user.userInformation = userInformation
    }
}
