import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    spacing: Theme.paddingMedium

    property var verificationStatus

    property bool verified: !!(verificationStatus && verificationStatus.is_verified)
    property bool scam: !!(verificationStatus && verificationStatus.is_scam)
    property bool fake: !!(verificationStatus && verificationStatus.is_fake)

    property bool muted

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
