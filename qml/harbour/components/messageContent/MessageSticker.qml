/*
    Copyright (C) 2020-21 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../"
import "../../js/twemoji.js" as Emoji

MessageContentBase {
    id: stickerMessage

    property var stickerData: rawMessage.content.sticker
    readonly property bool isOwnSticker: typeof messageListItem !== 'undefined' ? messageListItem.isOwnMessage : overlayFlickable.isOwnMessage

    implicitWidth: stickerData.width
    implicitHeight: stickerData.height

    TDLibSticker {
        width: Math.min(implicitWidth, parent.width)
        // (centered in image mode, text-like in sticker mode)
        anchors {
            horizontalCenter: appSettings.showStickersAsImages ? parent.horizontalCenter : undefined
            right: !appSettings.showStickersAsImages && isOwnSticker ? parent.right : undefined
            verticalCenter: parent.verticalCenter
        }

        stickerData: stickerMessage.stickerData
    }

    onClicked: {
        stickerSetOverlayLoader.stickerSetId = stickerData.set_id
        stickerSetOverlayLoader.active = true
    }
}
