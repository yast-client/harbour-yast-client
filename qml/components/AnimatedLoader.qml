import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    // this has nothing to do with Silica.private.AnimatedLoader
    // I don't fully understand the purpose of the Silica's version so can't say what that is for,
    // but this was created with no inspiration from that whatsoever

    // using implicitHeight here uses item's implicitHeight
    // using item's height instead won't work (it can become 0 when loader is unloaded)
    property real activeHeight: implicitHeight
    property bool show: true

    height: show ? activeHeight : 0
    opacity: show ? 1 : 0

    Behavior on opacity { FadeAnimator { id: fadeAnimator } }
    Behavior on height { NumberAnimation { id: heightAnimation; duration: 200 } }

    active: show || fadeAnimator.running || heightAnimation.running
}
