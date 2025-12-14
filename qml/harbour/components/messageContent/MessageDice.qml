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

MessageContentBase {
    id: stickerMessage

    readonly property var diceSticker: rawMessage.content.final_state || rawMessage.content.initial_state || {}
    readonly property string emoji: rawMessage.content.emoji
    readonly property var pureStickerData: (diceSticker['@type'] === "diceStickersSlotMachine" ? diceSticker.lever : diceSticker.sticker) || {}
    readonly property var stickerData: (appSettings.showStickersAsEmojis
                                        ? {emoji: emoji, width: pureStickerData.width, height: pureStickerData.height}
                                        : pureStickerData) || {}
    readonly property bool isOwnSticker: typeof messageListItem !== 'undefined' ? messageListItem.isOwnMessage : overlayFlickable.isOwnMessage

    width: stickerData.width
    height: stickerData.height

    Loader {
        anchors.fill: sticker
        active: !appSettings.showStickersAsEmojis && diceSticker['@type'] === "diceStickersSlotMachine"
        sourceComponent: Component {
            Item {
                anchors.fill: parent
                Repeater {
                    model: [diceSticker.background, diceSticker.left_reel, diceSticker.center_reel, diceSticker.right_reel]
                    TDLibSticker {
                        anchors.fill: parent
                        loop: false
                        stickerData: modelData
                    }
                }
            }
        }
    }

    TDLibSticker {
        id: sticker
        width: Math.min(implicitWidth, parent.width)
        // (centered in image mode, text-like in sticker mode)
        anchors {
            horizontalCenter: appSettings.showStickersAsImages ? parent.horizontalCenter : undefined
            right: !appSettings.showStickersAsImages && isOwnSticker ? parent.right : undefined
            verticalCenter: parent.verticalCenter
        }

        stickerData: stickerMessage.stickerData

        loop: false

        // TODO: do not play animation when viewing history
        /*property bool needSeekToEnd: false
        visible: !needSeekToEnd
        Component.onCompleted: needSeekToEnd = rawMessage.content.value > 0
        onLoadedChanged: if (loaded && needSeekToEnd) {
                             needSeekToEnd = false
                             seekToFrame(getFrameCount() - 3)
                             // pausing is done by loop=false
                         }*/
    }

    onClicked: {
        var canSend = hasSendPrivilege('can_send_other_messages')
        appNotification.show(qsTr("Send a %1 emoji to any chat to try your luck.", "in-app notification text").arg(emoji),
                             canSend ? function() { tdLibWrapper.sendDiceMessage(chatInformation.id, emoji) } : null,
                             canSend ? qsTr("Send", 'in-app notification button for "Send a %1 emoji to any chat to try your luck."') : null)
    }
}
