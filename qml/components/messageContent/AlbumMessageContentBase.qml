import QtQuick 2.6
import Sailfish.Silica 1.0
import "../"

MessageContentBase {
    id: messageContent
    property string chatId
    readonly property var albumId: rawMessage.media_album_id
    property var albumMessages: messageListItem ? messageListItem.messageAlbumMessages : []

    height: defaultExtraContentHeight
}
