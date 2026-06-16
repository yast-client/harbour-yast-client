import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../js/twemoji.js" as Emoji

CoverBackground {
    readonly property bool authenticated: tdLibWrapper.authorizationState === TDLibAPI.AuthorizationReady

    CoverBackgroundImage {
        source: Qt.resolvedUrl('../../images/cover-background-call.svg')
    }

    Column {
        id: column
        y: Theme.paddingLarge
        x: Theme.paddingMedium
        width: parent.width - 2*x

        Row {
            id: row
            width: parent.width
            spacing: Theme.paddingMedium

            ProfileThumbnail {
                id: profileThumbnail
                width: Theme.iconSizeMedium
                height: width
                anchors.verticalCenter: parent.verticalCenter
                photoData: typeof user.info.profile_photo.small !== 'undefined' ? user.info.profile_photo.small : null
                replacementStringHint: userName
            }

            Label {
                width: parent.width - profileThumbnail.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                truncationMode: TruncationMode.Fade
                text: userName
            }
        }

        Row {
            property real signalBarsIconAdditionalWidth: signalBarsIcon.visible ? signalBarsIcon.width + spacing : 0

            width: statusLabel.width + signalBarsIconAdditionalWidth
            anchors {
                topMargin: Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }
            spacing: Theme.paddingMedium

            Label {
                id: statusLabel
                width: Math.min(column.width - parent.signalBarsIconAdditionalWidth, implicitWidth)
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                text: callsManager.currentCallState === CallsManager.Connected
                      ? qsTr("Connected")
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

        Label {
            anchors {
                topMargin: Theme.paddingMedium
                horizontalCenter: parent.horizontalCenter
            }
            text: Emoji.emojify(callsManager.currentCallEmojis.join(' '), Theme.fontSizeSmall)
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    CoverActionList {
        enabled: callWindow.canHangUp
        CoverAction {
            iconSource: "image://theme/icon-cover-hangup"
            onTriggered: callsManager.discardCurrentCall()
        }
    }

    CoverActionList {
        enabled: callWindow.canCallBack
        CoverAction {
            iconSource: "image://theme/icon-cover-answer"
            onTriggered: callsManager.createCall(callsManager.currentCallUserId)
        }
    }
}
