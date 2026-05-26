import QtQuick 2.0
import Sailfish.Silica 1.0
import io.libfernie 1.0
import "../components"
import "../js/twemoji.js" as Emoji

Page {
    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        PageHeader {
            title: utilities.getUserName(user.info)
            description: callsManager.currentCallState === CallsManager.Connected
                         ? Emoji.emojify(callsManager.currentCallEmojis.join(''), Theme.fontSizeSmall)
                         : callWindow.callStatus

            Item {
                width: Theme.iconSizeMedium + 2*Theme.paddingMedium
                height: width

                Icon {
                    anchors.centerIn: parent
                    visible: callsManager.signalBars > 0
                    width: visible ? implicitWidth : 0
                    source: "image://theme/icon-m-wlan-" + callsManager.signalBars
                }
            }
        }

        ProfileThumbnail {
            width: Theme.itemSizeHuge
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            photoData: user.info.profile_photo.small
            replacementStringHint: utilities.getUserName(user.info)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingLarge
            visible: callsManager.currentCallState === CallsManager.Connected

            Switch {
                icon.source: 'image://theme/icon-m-speaker' + (checked ? '-on' : '')
                onCheckedChanged: callsManager.toggleSpeakerphone(checked)
            }
        }
    }

    Button {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        enabled: callWindow.canHangUp
        text: qsTr("End call")
        onClicked: callsManager.discardCurrentCall()
    }
}
