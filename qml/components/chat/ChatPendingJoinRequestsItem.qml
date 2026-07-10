import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'
import '../tdlib'

AnimatedLoader {
    property var chatId
    property var pendingJoinRequests

    show: pendingJoinRequests && !!pendingJoinRequests.total_count
    activeHeight: Theme.itemSizeSmall

    sourceComponent: Component {
        BackgroundItem {
            id: backgroundItem
            width: parent.width
            height: Theme.itemSizeSmall

            onClicked: pageStack.push(Qt.resolvedUrl('../../pages/ChatPendingJoinRequestsPage.qml'), {chatId: chatId})

            RecentActorsList {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                height: Theme.iconSizeMedium
                paddingDifference: Theme.iconSizeSmall
                model: pendingJoinRequests.user_ids
                userIds: true
            }

            Label {
                x: Theme.horizontalPageMargin + ((pendingJoinRequests.user_ids.length - 1) * Theme.iconSizeSmall) + Theme.iconSizeMedium + Theme.paddingMedium
                width: parent.width - x - Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                text: singleJoinRequestUserInfoLoader.active ?
                          qsTr("%1 requested to join", "banner indicating that there is one unreviewed group join request from a user")
                                .arg(utilities.getUserName(singleJoinRequestUserInfoLoader.item ? singleJoinRequestUserInfoLoader.item.userInformation : null))
                        : qsTr("%n join requests", "banner indicating that there are unreviewed group join requests, for admins", pendingJoinRequests.total_count)

                Loader {
                    id: singleJoinRequestUserInfoLoader
                    active: pendingJoinRequests.total_count === 1
                    sourceComponent: Component {
                        TDLibUser {
                            userId: pendingJoinRequests.user_ids[0]
                        }
                    }
                }
            }
        }
    }
}
