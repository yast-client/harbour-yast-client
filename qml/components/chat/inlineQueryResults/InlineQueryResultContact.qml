//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

InlineQueryResultDefaultBase {
    title: Emoji.emojify(utilities.getUserName(model.contact), titleLable.font.pixelSize)
    description: Emoji.emojify(model.contact.phone_number || '', descriptionLabel.font.pixelSize)

    thumbnailFileInformation: model.thumbnail ? model.thumbnail.file : {}

    icon.source: "image://theme/icon-m-contact"
    icon.visible: thumbnail.visible && thumbnail.opacity === 0
}
