//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

MessageSticker {
    stickerData: rawMessage.content.animated_emoji.sticker
    // FIXME: fitz modifier doesn't seem to be reported by TDLib for some reason, even if it's shown on other clients
    // (but settng it manually here shows the modified emoji correctly)
    fitzModifier: rawMessage.content.animated_emoji.fitzpatrick_type
    defaultWidth: Theme.itemSizeExtraLarge
}
