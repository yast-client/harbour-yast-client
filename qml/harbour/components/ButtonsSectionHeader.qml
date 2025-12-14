import QtQuick 2.0
import Sailfish.Silica 1.0

// A section header with buttons.

Item {
    x: Theme.horizontalPageMargin
    y: Theme.paddingMedium
    height: Theme.itemSizeSmall
    width: (parent ? parent.width : Screen.width) - x*2

    property alias label: label
    property alias text: label.text

    property alias buttonsContainer: buttonsContainer
    default property alias items: buttonsContainer.children

    Row {
        id: buttonsContainer
        height: parent.height
        spacing: Theme.paddingSmall
        width: Math.max(implicitWidth, parent.width - label.implicitWidth - Theme.paddingMedium)
    }

    Label {
        id: label
        width: parent.width - (items.length > 0 ? (buttonsContainer.width - Theme.paddingMedium) : 0)
        anchors.right: parent.right
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        font.pixelSize: Theme.fontSizeSmall
        truncationMode: TruncationMode.Fade
        color: palette.highlightColor
    }
}
