import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../js/functions.js" as Functions
import "../../js/twemoji.js" as Emoji

Row {
    id: inReplyToRow
    spacing: Theme.paddingSmall
    width: parent.width
    height: inReplyToMessageColumn.height

    property var inReplyToMessage;
    property bool editable: false;
    property bool inReplyToMessageDeleted: false;

    signal clearRequested()

    onInReplyToMessageChanged: {
        if (inReplyToMessage) {
            inReplyToUserText.text = (inReplyToMessage.sender_id["@type"] === "messageSenderChat" ? page.chatInformation.title : (inReplyToRow.inReplyToMessage.sender_id.user_id !== tdLibWrapper.myUserId) ? Emoji.emojify(utilities.getUserName(tdLibWrapper.getUserInformation(inReplyToRow.inReplyToMessage.sender_id.user_id)), inReplyToUserText.font.pixelSize) : qsTr("You"));
            inReplyToMessageText.text = Emoji.emojify(utilities.getMessageText(inReplyToRow.inReplyToMessage, Utilities.MessageTextSimple), inReplyToMessageText.font.pixelSize);
        }
    }

    onInReplyToMessageDeletedChanged: {
        if (inReplyToMessageDeleted) {
            inReplyToUserText.text = qsTr("Unknown")
            inReplyToMessageText.text = "<i>" + qsTr("This message was deleted") + "</i>";
        }
    }

    Rectangle {
        id: inReplyToMessageRectangle
        height: inReplyToMessageColumn.height
        width: Theme.paddingSmall
        color: Theme.secondaryHighlightColor
        border.width: 0
    }

    Row {
        width: parent.width - Theme.paddingSmall - inReplyToMessageRectangle.width
        spacing: Theme.paddingSmall

        Column {
            id: inReplyToMessageColumn
            spacing: Theme.paddingSmall
            width: parent.width - ( inReplyToRow.editable ? ( Theme.paddingSmall + removeInReplyToIconButton.width ) : 0 )

            Label {
                id: inReplyToUserText

                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                font.weight: Font.ExtraBold
                maximumLineCount: 1
                truncationMode: TruncationMode.Fade
                textFormat: Text.StyledText
                horizontalAlignment: Text.AlignLeft
            }

            Label {
                id: inReplyToMessageText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width
                textFormat: Text.StyledText
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
                linkColor: Theme.highlightColor
                onLinkActivated: utilities.handleLink(link)
            }
        }

        IconButton {
            id: removeInReplyToIconButton
            icon.source: "image://theme/icon-m-clear"
            visible: inReplyToRow.editable
            onClicked: {
                inReplyToRow.clearRequested();
            }
        }
    }

}
