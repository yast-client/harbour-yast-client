//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    // NOTE: this is not related to Silica.private.AnimatedLoader
    id: loader

    // using implicitHeight here uses item's implicitHeight
    // using item's height instead won't work (it can become 0 when loader is unloaded)
    property real activeHeight: implicitHeight
    property bool show: true
    property bool hidden
    property int animationDuration: 200

    height: 0
    opacity: 0
    clip: true

    states: State {
        name: 'active'
        when: show && !hidden
        PropertyChanges {
            target: loader
            opacity: 1
            height: activeHeight
            clip: false
        }
    }

    transitions: Transition {
        id: transition
        FadeAnimator {}
        NumberAnimation { properties: 'height'; duration: animationDuration }
    }

    active: show || transition.running
}
