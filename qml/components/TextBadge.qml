import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: rectangle
    width: text.width + border.width*2 + Theme.paddingSmall*2
    height: text.height + border.width*2 + Theme.paddingSmall*2
    radius: Theme.paddingSmall
    color: 'transparent'
    border {
        width: Theme.paddingSmall
        color: rectangle.badgeColor
    }

    property color badgeColor: Theme.errorColor
    property alias text: text.text

    Text {
        id: text
        anchors.centerIn: parent
        color: rectangle.badgeColor
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        font.capitalization: Font.AllUppercase
    }
}
