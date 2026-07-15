//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

InlineQueryResultDefaultBase {
    id: queryResultItem
    property string namesSeparator: model.contact.first_name && model.contact.last_name ? " " : ""

    title: Emoji.emojify(model.contact.first_name + namesSeparator + model.contact.last_name || "", titleLable.font.pixelSize)
    description: Emoji.emojify(model.contact.phone_number || "", descriptionLabel.font.pixelSize)

    extraText: model.url || ""
    extraTextLabel.visible: !model.hide_url && extraText.length > 0

    thumbnailFileInformation: model.thumbnail ? model.thumbnail.file : {}

    icon.source: "image://theme/icon-m-contact"
    icon.visible: thumbnail.visible && thumbnail.opacity === 0

}
