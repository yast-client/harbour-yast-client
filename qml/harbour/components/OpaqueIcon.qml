import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

OpaqueItemBase {
    // white background = invisible button. I can't tell since which SFOS version the opaque button is available, so:
    id: background
    property alias icon: icon
    property alias highlighted: icon.highlighted

    Icon {
        id: icon
        anchors.fill: parent

        asynchronous: true
        sourceSize {
            width: background.width
            height: background.height
        }
    }
}
