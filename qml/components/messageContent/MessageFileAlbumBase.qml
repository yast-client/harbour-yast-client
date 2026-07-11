import QtQuick 2.0
import Sailfish.Silica 1.0

AlbumMessageContentBase {
    id: messageContent
    width: parent.width
    height: column.height

    property Component sourceComponent

    Column {
        id: column
        width: parent.width
        Repeater {
            model: albumMessages
            BackgroundItem {
                id: messageBackgroundItem
                width: parent.width
                height: loader.height

                readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting && page.selectedMessages.some(function(existingMessage) {
                    return existingMessage.id === albumMessages[index].id
                })
                highlighted: isSelected || down || messageContent.highlighted
                onPressAndHold: messagesView.toggleMessageSelection(albumMessages[index])
                onClicked:
                    if(messageListItem.precalculatedValues.pageIsSelecting)
                        messagesView.toggleMessageSelection(albumMessages[index])

                Loader {
                    id: loader
                    property var message: albumMessages[index]
                    width: parent.width
                    sourceComponent: messageContent.sourceComponent
                    asynchronous: true
                }
            }
        }
    }
}
