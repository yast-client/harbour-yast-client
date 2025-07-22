import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    spacing: Theme.paddingMedium

    property var verificationStatus

    property bool verified: !!(verificationStatus && verificationStatus.is_verified)
    property bool scam: !!(verificationStatus && verificationStatus.is_scam)
    property bool fake: !!(verificationStatus && verificationStatus.is_fake)

    property bool muted
    property bool ad

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
        text: qsTr("SCAM", "string for a user text badge, should not be too long. Badge shows that this user was reported by many users as a fake or scam user: you should careful when interacting with them.")
    }

    TextBadge {
        anchors.verticalCenter: parent.verticalCenter
        visible: fake
        text: qsTr("FAKE", "string for a user text badge, should not be too long. Badge shows that this may be a scam user.")
    }

    TextBadge {
        error: false
        visible: ad
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Ad", "chat badge, indicates that the search result is sponsored")
    }
}
