//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

Column {
    width: parent.width
    property SilicaFlickable flickable
    property bool animate: false
    signal setActiveArea(string activeAreaName)
    function scrollUpFlickable(amount) {
        if(flickable) {
            flickableAnimation.to = Math.max(0, flickable.contentY - amount);
            flickableAnimation.start()
        }
    }

    NumberAnimation {
        id: flickableAnimation
        target: flickable
        property: "contentY"
        duration: 200
    }
}
