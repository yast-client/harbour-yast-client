//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../tdlib"
import "../../js/twemoji.js" as Emoji

MessageContentBase {
    id: content
    height: item.height

    property var contact: rawMessage.content.contact

    TDLibUser {
        id: user
        userId: contact.user_id
    }

    PhotoTextsListItem {
        id: item
        compact: true
        leftMargin: 0
        rightMargin: 0
        contentHeight: Theme.itemSizeMedium
        pictureThumbnailItem.height: Theme.itemSizeSmall
        primaryText.font.pixelSize: Theme.fontSizeSmall
        contentLeftMargin: Theme.paddingMedium

        // TBD: should we not use a ListItem (or any MouseArea) here at all?
        // (and instead extract actual UI from PhotoTextsListItem or write something new here?)
        enabled: false
        opacity: 1
        highlighted: content.highlighted
        contentItem.color: 'transparent'

        primaryText.text:
            // works for a contact object too
            Emoji.emojify(utilities.getUserName(contact), primaryText.font.pixelSize)
        secondaryText.text: contact.phone_number

        pictureThumbnail {
            accentColorId: user.info.accent_color_id
            minithumbnail: user.info.profile_photo.minithumbnail
            photoData: user.info.profile_photo.small
        }
    }

    onClicked:
        if (user.info.id)
            tdLibWrapper.createPrivateChat(user.userId, 'openDirectly')
        else
            pageStack.push(Qt.resolvedUrl("../../dialogs/AddContactDialog.qml"), {
                phone: contact.phone_number,
                name: contact.first_name,
                lastName: contact.last_name
            })
}
