import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../../js/functions.js' as Functions

MessageContentBase {
    id: message

    property alias text: label.text
    property bool defaultOnClicked: true

    property bool isOutgoing: rawMessage.is_outgoing

    Row {
        width: parent.width
        height: Theme.itemSizeMedium
        spacing: Theme.paddingMedium
        layoutDirection: isOutgoing ? Qt.RightToLeft : Qt.LeftToRight

        Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            source: 'image://theme/icon-m-' + (rawMessage.content.is_video ? 'video' : 'call')
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
                text: utilities.getMessageCallText(rawMessage.content, isOutgoing)
                font.pixelSize: Theme.fontSizeSmall
                color: highlighted ? Theme.primaryColor : Theme.highlightColor
                highlighted: message.highlighted
                truncationMode: TruncationMode.Fade
                horizontalAlignment: isOutgoing ? Text.AlignRight : Text.AlignLeft
            }

            Row {
                width: parent.width
                layoutDirection: isOutgoing ? Qt.RightToLeft : Qt.LeftToRight
                spacing: Theme.paddingSmall

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: 'image://theme/icon-s-' + (isOutgoing ? 'outgoing-call' : 'incoming-call')
                    color: highlighted ? Theme.primaryColor : Theme.highlightColor
                }

                Label {
                    width: parent.width - Theme.iconSizeSmall - parent.spacing
                    text: Format.formatDuration(rawMessage.content.duration)
                    //visible: !!rawMessage.content.duration // FIXME?
                    color: highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    highlighted: message.highlighted
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: isOutgoing ? Text.AlignRight : Text.AlignLeft
                }
            }
        }
    }

    onClicked:
        if (defaultOnClicked)
            callsManager.createCall(rawMessage.chat_id)
}
