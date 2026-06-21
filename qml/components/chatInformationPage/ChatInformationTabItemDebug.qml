import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQml.Models 2.3

import "../"
import "../../pages"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

ChatInformationTabItemBase {
    id: tabBase

    SilicaFlickable {
        height: tabBase.height
        width: tabBase.width
        contentHeight: contentColumn.height
        Column {
            id: contentColumn
            width: tabBase.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin

            InformationTextItem {
                headerText: "chatInformation"
                text:chatInformationPage.chatInformation ?  JSON.stringify(chatInformationPage.chatInformation, null, 2) : ""
                isLinkedLabel: true
            }
            InformationTextItem {
                headerText: "groupInformation"
                text: chatInformationPage.groupInformation ? JSON.stringify(chatInformationPage.groupInformation, null, 2) : ""
                isLinkedLabel: true
            }

            InformationTextItem {
                headerText: "groupFullInformation"
                text: chatInformationPage.groupFullInformation ? JSON.stringify(chatInformationPage.groupFullInformation, null, 2) : ""
                isLinkedLabel: true
            }
        }

        VerticalScrollDecorator {}
    }
}
