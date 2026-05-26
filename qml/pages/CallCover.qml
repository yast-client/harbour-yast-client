import QtQuick 2.6
import Sailfish.Silica 1.0
import io.libfernie 1.0
import "../components"
import "../js/twemoji.js" as Emoji

CoverBackground {
    id: coverPage
    readonly property bool authenticated: tdLibWrapper.authorizationState === TDLibAPI.AuthorizationReady

    BackgroundImage {
        id: backgroundImage
        width: parent.height - Theme.paddingLarge
        height: width
        sourceDimension: width
        anchors {
            verticalCenter: parent.verticalCenter
            centerIn: undefined
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
    }

    Icon {
        source: "image://theme/icon-l-dialer"
        opacity: 0.3
        width: Theme.iconSizeExtraLarge*1.5
        height: width
        sourceSize: {
            width: width
            height: height
        }
        anchors.centerIn: parent
    }

    Column {
        id: column
        y: Theme.paddingLarge
        x: Theme.paddingMedium
        width: parent.width - 2*x
        spacing: Theme.paddingLarge

        Row {
            id: row
            width: parent.width
            spacing: Theme.paddingMedium

            ProfileThumbnail {
                id: profileThumbnail
                width: Theme.iconSizeMedium
                height: width
                anchors.verticalCenter: parent.verticalCenter
                photoData: user.info.profile_photo.small
                replacementStringHint: utilities.getUserName(user.info)
            }

            Label {
                width: parent.width - profileThumbnail.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                truncationMode: TruncationMode.Fade
                text: utilities.getUserName(user.info)
            }
        }

        Row {
            property real signalBarsIconAdditionalWidth: signalBarsIcon.visible ? signalBarsIcon.width + spacing : 0

            width: statusLabel.width + signalBarsIconAdditionalWidth
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium

            Label {
                id: statusLabel
                width: Math.min(column.width - signalBarsIconAdditionalWidth, implicitWidth)
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                textFormat: Text.StyledText
                text: callsManager.currentCallState === CallsManager.Connected
                      ? Emoji.emojify(callsManager.currentCallEmojis.join(' '), Theme.fontSizeSmall)
                      : callWindow.callStatus
            }
            Icon {
                id: signalBarsIcon
                visible: callsManager.signalBars > 0
                width: visible ? implicitWidth : 0
                color: Theme.highlightColor
                source: "image://theme/icon-m-wlan-" + callsManager.signalBars
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    CoverActionList {
        enabled: callWindow.canHangUp

        CoverAction {
            iconSource: "image://theme/icon-cover-hangup"
            onTriggered: callsManager.discardCurrentCall()
        }
    }
}
