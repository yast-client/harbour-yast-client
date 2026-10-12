//@ SPDX-FileCopyrightText: 2025-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import ".."
import "../tdlib"
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

            readonly property bool isPhoto: message.content['@type'] === 'messagePhoto'
            pictureThumbnailItem.height: height - 2*Theme.paddingSmall
            pictureThumbnail {
                accentColorId: message.accent_color_id
                minithumbnail: isPhoto ? message.photo.minithumbnail : null
                photoData: isPhoto ? utilities.findPhotoSize(message.photo.sizes, pictureThumbnail.width) : null
            }

            ad: true
            primaryText.text: message.title ? Emoji.emojify(utilities.escapeHtml(message.title), Theme.fontSizeSmall) : qsTr("Unknown")
            primaryText.font.pixelSize: Theme.fontSizeSmall

            TDLibFormattedText {
                id: contentText
                formattedText: utilities.getMessageContentFormattedText(message.content)
                emojiSize: Theme.fontSizeExtraSmall
                needsRichText: false
            }
            secondaryText.text: contentText.text

            onClicked: {
                tdLibWrapper.clickChatSponsoredMessage(chatId, message.message_id)
                tdLibWrapper.getInternalLinkType(message.sponsor.url)
            }
        }
    }
}
