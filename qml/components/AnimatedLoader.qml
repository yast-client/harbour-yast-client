import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    // this has nothing to do with Silica.private.AnimatedLoader
    // I don't fully understand the purpose of the Silica's version so can't say what that is for,
    // but this was created with no inspiration from that whatsoever

    id: loader

    // using implicitHeight here uses item's implicitHeight
    // using item's height instead won't work (it can become 0 when loader is unloaded)
    property real activeHeight: implicitHeight
    property bool show: true

    height: 0
    opacity: 0

    states: State {
        name: 'active'
        when: active
        PropertyChanges {
            target: loader
            opacity: 1
            height: activeHeight
        }
    }

    transitions: Transition {
        id: transition
        FadeAnimator {}
        NumberAnimation { properties: 'height'; duration: 200 }
    }

    active: show || transition.running
}
