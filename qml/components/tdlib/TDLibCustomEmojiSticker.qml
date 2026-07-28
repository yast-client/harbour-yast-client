//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0

TDLibSticker {
    stickerData: loader.stickerData
    TDLibCustomEmojiStickerDataLoader { id: loader }
}
