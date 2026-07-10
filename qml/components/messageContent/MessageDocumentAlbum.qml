import QtQuick 2.0
import Sailfish.Silica 1.0

AlbumMessageContentBase {
    id: messageContent
    width: parent.width
    height: column.height
    Column {
        id: column
        width: parent.width
        Repeater {
            model: albumMessages
            BackgroundItem {
                id: messageBackgroundItem
                width: parent.width
                height: documentMessage.height

                readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting && page.selectedMessages.some(function(existingMessage) {
                    return existingMessage.id === albumMessages[index].id
                })
                highlighted: isSelected || down || messageContent.highlighted
                onPressAndHold: page.toggleMessageSelection(albumMessages[index])
                onClicked:
                    if(messageListItem.precalculatedValues.pageIsSelecting)
                        page.toggleMessageSelection(albumMessages[index])

                MessageDocument {
                    id: documentMessage
                    width: parent.width
                    messageListItem: messageContent.messageListItem
                    rawMessage: albumMessages[index]
                    highlighted: messageContent.highlighted
                }
            }
        }
    }
}
