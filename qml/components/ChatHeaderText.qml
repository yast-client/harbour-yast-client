import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: primaryTextRow
    implicitWidth: primaryText.width + primaryText.anchors.rightMargin + badgesRow.width
    height: Math.max(primaryText.height, badgesRow.height)

    property alias textItem: primaryText
    property alias text: primaryText.text
    property alias font: primaryText.font
    property alias color: primaryText.color

    property bool verified
    property bool muted
    property bool scam
    property bool fake

    Label {
        id: primaryText
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(contentColumn.width - badgesRow.width - badgesRow.anchors.leftMargin, implicitWidth)

        textFormat: Text.StyledText
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade

    }

    Row {
        id: badgesRow
        anchors {
            left: primaryText.right
            leftMargin: Theme.paddingSmall
        }
        spacing: Theme.paddingMedium

        Image {
            id: verifiedImage
            anchors.verticalCenter: parent.verticalCenter
            source: verified ? "../../images/icon-verified.svg" : ''
            sourceSize: Qt.size(Theme.iconSizeExtraSmall, Theme.iconSizeExtraSmall)
            width: Theme.iconSizeSmall
            height: Theme.iconSizeSmall
            visible: status === Image.Ready
        }

        Image {
            id: mutedImage
            anchors.verticalCenter: parent.verticalCenter
            source: muted ? "../js/emoji/1f507.svg" : ''
            sourceSize: Qt.size(Theme.iconSizeExtraSmall, Theme.iconSizeExtraSmall)
            width: Theme.iconSizeSmall
            height: Theme.iconSizeSmall
            visible: status === Image.Ready
        }

        TextBadge {
            anchors.verticalCenter: parent.verticalCenter
            visible: scam
            text: qsTr("SCAM")
        }

        TextBadge {
            anchors.verticalCenter: parent.verticalCenter
            visible: fake
            text: qsTr("FAKE")
        }
    }
}
