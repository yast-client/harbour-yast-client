import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    implicitWidth: count ? height + paddingDifference * (count - 1) : 0

    property real paddingDifference: Theme.paddingMedium
    property bool inverted
    property alias model: repeater.model
    property alias count: repeater.count
    property bool userIds // specifies if the model contains user ids instead of messageSender objects

    property bool highlighted

    Repeater {
        id: repeater
        ProfileThumbnail {
            id: profileThumbnail
            height: parent.height
            width: height
            x: paddingDifference * (inverted ? repeater.count - index - 1 : index)

            highlighted: parent.highlighted

            photoData: isChat
                       ? tdLibWrapper.getChat(modelData.chat_id).photo.small
                       : userInfoLoader.info.profile_photo.small
            replacementStringHint: isChat
                                   ? tdLibWrapper.getChat(modelData.chat_id).title
                                   : utilities.getUserName(userInfoLoader.info)

            property bool isChat: !userIds && modelData['@type'] === 'messageSenderChat'

            TDLibUser {
                id: userInfoLoader
                userId: isChat ? 0 : (userIds ? modelData : modelData.user_id)
            }

            Connections {
                // FIXME: this can be improved (maybe use QQmlPropertyMaps for storing chat info?):
                target: isChat ? tdLibWrapper : null
                onChatTitleUpdated:
                    if (chatId === modelData.chat_id)
                        profileThumbnail.replacementStringHint = title
                onChatPhotoUpdated:
                    if (chatId === modelData.chat_id)
                        profileThumbnail.photoData = photo.small
            }
        }
    }
}
