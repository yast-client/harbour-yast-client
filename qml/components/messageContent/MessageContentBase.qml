import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import "../chat"
import "../../js/debug.js" as Debug

Item {
    property ListItem messageListItem
    property var rawMessage: messageListItem ? messageListItem.myMessage : null
    property bool isOwnMessage: !!messageListItem && !!messageListItem.isOwnMessage
    property bool isSponsored: !!messageListItem && !!messageListItem.isSponsored
    property bool isUnread: !!messageListItem && !!messageListItem.isUnread
    property bool generatedContentUnread: !!messageListItem && !!messageListItem.generatedContentUnread
    property int messageIndex: messageListItem ? messageListItem.messageIndex : -1
    property bool highlighted
    signal clicked()
}
