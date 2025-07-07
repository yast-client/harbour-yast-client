import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property real maxWidth: parent.width
    width: text.width + badgesRow.width + badgesRow.anchors.leftMargin
    height: Math.max(text.height, badgesRow.height)

    property var verificationStatus: ({})
    property alias showBadges: badgesRow.visible

    property alias textItem: text
    property alias text: text.text
    property alias font: text.font
    property alias color: text.color

    property bool verified: !!verificationStatus.is_verified
    property bool scam: !!verificationStatus.is_scam
    property bool fake: !!verificationStatus.is_fake
    property bool muted

    Label {
        id: text
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(maxWidth - badgesRow.width - badgesRow.anchors.leftMargin, implicitWidth)

        textFormat: Text.StyledText
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade

    }

    Row {
        id: badgesRow
        anchors {
            left: text.right
            leftMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
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
