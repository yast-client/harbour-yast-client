import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property bool down
    signal clicked

    property real size: 1
    width: parent.itemWidth * size
    implicitHeight: Theme.itemSizeSmall

    property bool _calculateWidth: true
    onVisibleChanged:
        if (parent.calculateItemWidth && _calculateWidth)
            parent.calculateItemWidth()
}
