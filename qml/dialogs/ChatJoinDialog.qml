import QtQuick 2.6
import Sailfish.Silica 1.0
import '../components'
import '../js/functions.js' as Functions

Dialog {
    property string link
    property var invite
    property bool isChannel: invite.type['@type'] === 'inviteLinkChatTypeChannel'

    onAccepted:
        tdLibWrapper.joinChatByInviteLink(link, isChannel)

    DialogHeader {
        id: header
        //title: invite.title
        acceptText: invite.creates_join_request
                    ? (isChannel ? qsTr("Request to join", "channel") : qsTr("Request to join", "group"))
                    : (isChannel ? qsTr("Join channel", "channel") : qsTr("Join group", "group"))
    }

    SilicaFlickable {
        anchors {
            top: header.bottom
            bottom: parent.bottom
        }
        width: parent.width

        Column {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            spacing: Theme.paddingLarge

            ProfileThumbnail {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeLarge
                height: width
                photoData: utilities.findPhotoSize(invite.photo.sizes, width).photo
                replacementStringHint: invite.title
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                Label {
                    text: invite.title
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: Theme.fontFamilyHeading
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.highlightColor

                    rightPadding: badges.width ? (badges.width + Theme.paddingMedium) : 0
                    ChatBadges {
                        id: badges
                        anchors.right: parent.right
                        verificationStatus: invite.verification_status
                    }
                }

                Label {
                    text: Functions.getGroupStatusText(invite.member_count, isChannel)
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.secondaryHighlightColor
                }
            }

            Flow {
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: invite.member_user_ids.filter(function (userId) {
                        return tdLibWrapper.hasUserInformation(userId)
                    })

                    PhotoTextsGridItem {
                        TDLibUser {
                            id: user
                            userId: modelData
                        }

                        width: Theme.itemSizeLarge
                        contentHeight: content.height + 2*Theme.paddingMedium
                        pictureThumbnail.photoData: user.info.profile_photo.small || {}
                        primaryText.text: utilities.getUserName(user.info)
                    }
                }
            }

            Label {
                text: invite.description
                visible: !!text
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
            }

            Label {
                text: isChannel
                      ? qsTr("This channel accepts new subscribers only after they are approved by its admins.")
                      : qsTr("This group accepts new members only after they are approved by its admins.")
                visible: invite.creates_join_request
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryHighlightColor
            }
        }
    }
}
