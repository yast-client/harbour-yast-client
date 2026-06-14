import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../js/twemoji.js" as Emoji

Page {
    Column {
        width: parent.width

        PageHeader {
            title: userName
            description: callWindow.callStatus
            height: implicitHeight

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

        Label {
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
            text: Emoji.emojify(callsManager.currentCallEmojis.join(' '), Theme.fontSizeSmall)
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        ProfileThumbnail {
            width: Theme.itemSizeHuge
            height: width
            anchors {
                topMargin: Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }
            photoData: user.info.profile_photo.small
            replacementStringHint: userName
        }

        Column {
            width: parent.width
            anchors.topMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Repeater {
                model: [
                    [callsManager.remoteAudioMuted, qsTr("%1's microphone is off"), 'image://theme/icon-m-mic-mute'],
                    [callsManager.remoteBatteryLevelIsLow, qsTr("%1's battery level is low"), 'image://theme/icon-m-battery-saver']
                ]

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: modelData[0] ? 1 : 0
                    Behavior on opacity { FadeAnimator {} }
                    text: modelData[1].arg(userName)
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeExtraSmall

                    leftPadding: Theme.iconSizeSmall + Theme.paddingSmall
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: modelData[2]
                        width: Theme.iconSizeSmall
                        height: width
                        sourceSize {
                            width: width
                            height: height
                        }
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingLarge
            visible: callsManager.currentCallState === CallsManager.Connected || callsManager.currentCallState === CallsManager.Connecting

            Switch {
                id: speakerphoneSwitch
                icon.source: 'image://theme/icon-m-speaker' + (checked ? '-on' : '')
                onCheckedChanged: callsManager.toggleSpeakerphone(checked)
            }

            Switch {
                id: muteSwitch
                icon.source: 'image://theme/icon-m-mic' + (checked ? '-mute' : '')
                onCheckedChanged: callsManager.toggleMicrophoneIsMuted(checked)
            }

            Connections {
                target: callsManager
                onCallDiscarded:
                    speakerphoneSwitch.checked = muteSwitch.checked = false
            }
        }
    }

    Button {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        enabled: callWindow.canHangUp || callWindow.canCallBack
        text: callWindow.canCallBack ? qsTr("Call back") : qsTr("End call")
        onClicked: if (callWindow.canHangUp)
                       callsManager.discardCurrentCall()
                   else callsManager.createCall(callsManager.currentCallUserId)
    }
}
