//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

AnimatedLoader {
    property var chatId
    property var message

    show: !!(message && message.message_id)
    activeHeight: Theme.itemSizeSmall

    onShowChanged:
        if (show)
            tdLibWrapper.viewMessage(chatId, message.message_id)

    sourceComponent: Component {
        PhotoTextsListItem {
            id: backgroundItem
            width: parent.width
            contentHeight: Theme.itemSizeSmall

            pictureThumbnailItem.height: height - 2*Theme.paddingSmall
            pictureThumbnail.photoData: message.content['@type'] === 'messagePhoto'
                                        ? utilities.findPhotoSize(message.photo.sizes, pictureThumbnail.width)
                                        : null

            ad: true
            primaryText.text: message.title ? Emoji.emojify(utilities.fixReservedHtmlCharacters(message.title), Theme.fontSizeSmall) : qsTr("Unknown")
            primaryText.font.pixelSize: Theme.fontSizeSmall
            secondaryText.text: Emoji.emojify(utilities.getMessageContentText(message.content, Utilities.MessageTextDefault), Theme.fontSizeExtraSmall)

            onClicked: {
                tdLibWrapper.clickChatSponsoredMessage(chatId, message.message_id)
                tdLibWrapper.getInternalLinkType(message.sponsor.url)
            }
        }
    }
}
