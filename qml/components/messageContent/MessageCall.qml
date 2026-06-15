import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../../js/functions.js' as Functions

MessageContentBase {
    id: message

    property alias text: label.text
    property bool defaultOnClicked: true

    Row {
        width: parent.width
        height: Theme.itemSizeLarge
        spacing: Theme.paddingMedium

        Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            source: rawMessage.is_outgoing ? 'image://theme/icon-m-outgoing-call' : Qt.resolvedUrl('../../../images/icon-m-missed-call.svg')
            color: highlighted ? Theme.primaryColor : Theme.highlightColor
            highlighted: message.highlighted
            width: Theme.iconSizeMedium
            height: width
            sourceSize {
                width: width
                height: height
            }
        }

        Column {
            width: parent.width - icon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingMedium

            Label {
                id: label
                width: parent.width
                text: utilities.getMessageCallText(rawMessage.content, rawMessage.is_outgoing)
                color: highlighted ? Theme.primaryColor : Theme.highlightColor
                highlighted: message.highlighted
                truncationMode: TruncationMode.Fade
            }

            Label {
                width: parent.width
                text: Functions.formatDuration(rawMessage.content.duration)
                visible: !!rawMessage.content.duration
                color: highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor
                highlighted: message.highlighted
                truncationMode: TruncationMode.Fade
            }
        }
    }

    onClicked:
        if (defaultOnClicked)
            callsManager.createCall(rawMessage.chat_id)
}
