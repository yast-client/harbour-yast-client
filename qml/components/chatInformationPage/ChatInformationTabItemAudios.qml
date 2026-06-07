import QtQuick 2.0
import Sailfish.Silica 1.0
import "../messageContent"
import "../../js/functions.js" as Functions

ChatInformationTabItemMediaList {
    messageDelegate: Component {
        MessageAudio {
            width: parent.width
            messageListItem: parent.listItem
            rawMessage: parent.listItem.message
            tertiaryText: Functions.getDateTimeElapsed(rawMessage.date) + ', ' + durationText
        }
    }
}
