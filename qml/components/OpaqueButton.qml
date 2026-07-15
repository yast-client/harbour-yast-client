//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

OpaqueItemBase {
    // white background = invisible button. I can't tell since which SFOS version the opaque button is available, so:
    id: background

    property alias button: button
    property alias down: button.down
    property alias icon: button.icon
    property alias highlighted: button.highlighted
    signal clicked

    IconButton {
        id: button
        anchors.fill: parent
        onClicked: background.clicked()

        icon {
            asynchronous: true
            sourceSize {
                width: background.width
                height: background.height
            }
        }
    }
}
