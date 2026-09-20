import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components/tdlib"

Dialog {
    property string url
    property string domain
    property alias botUserId: botUser.userId
    property bool requestWriteAccess

    property var chatId
    property var messageId
    property var buttonId

    onAccepted:
        if (loginSwitch.checked) {
            var writeAccess = requestWriteAccess && allowWriteAccessSwitch.checked
            if (chatId)
                tdLibWrapper.getLoginUrl(chatId, messageId, buttonId, writeAccess, url)
            else
                tdLibWrapper.getExternalLink(url, writeAccess)
        } else
            tdLibWrapper.getLinkWebBrowserType(url, true)

    TDLibUser { id: botUser }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Open Link")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Are you sure you want to open %1?")
                    .arg('<font color="' + Theme.highlightColor + '">' + url + '</font>')
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
            }

            TextSwitch {
                id: loginSwitch
                text: qsTr("Login to %1 as %2")
                    .arg('<font color="' + Theme.highlightColor + '">' + domain + '</font>')
                    .arg('<b>' + utilities.getUserName(tdData.userInformation) + '</b>')
                checked: true
            }

            TextSwitch {
                id: allowWriteAccessSwitch
                visible: requestWriteAccess
                enabled: requestWriteAccess && loginSwitch.checked
                text: qsTr("Allow %1 to send me messages").arg(utilities.getUserName(botUser.info))
            }
        }
    }
}
