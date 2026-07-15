//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property alias text: label.text

    onAccepted: tdLibWrapper.destroyInstance()

    Column {
        width: parent.width

        DialogHeader {
            acceptText: qsTr("Log out")
        }

        Label {
            id: label
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            color: Theme.highlightColor
            wrapMode: Text.Wrap
        }
    }
}
