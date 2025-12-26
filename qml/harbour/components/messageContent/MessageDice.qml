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
import QtQml 2.2
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../"
import '../../js/debug.js' as Debug

// ignore appSettings.showStickersAsEmojis here (if really needed can be re-added later)
MessageContentBase {
    id: message

    readonly property var diceSticker: rawMessage.content.final_state || rawMessage.content.initial_state || {}
    readonly property string emoji: rawMessage.content.emoji
    readonly property var stickerData: (diceSticker['@type'] === "diceStickersSlotMachine" ? diceSticker.background : diceSticker.sticker) || {}
    readonly property bool isOwnSticker: typeof messageListItem !== 'undefined' ? messageListItem.isOwnMessage : overlayFlickable.isOwnMessage

    // do not play animation when viewing history
    property bool completed
    Component.onCompleted: {
        if (!generatedContentUnread && rawMessage.content.value > 0)
            completed = true
    }

    width: stickerData.width
    height: stickerData.height

    TDLibStickerBase {
        id: sticker

        width: Math.min(implicitWidth, parent.width)
        height: width * aspectRatio
        // (centered in image mode, text-like in sticker mode)
        anchors {
            horizontalCenter: appSettings.showStickersAsImages ? parent.horizontalCenter : undefined
            right: !appSettings.showStickersAsImages && isOwnSticker ? parent.right : undefined
            verticalCenter: parent.verticalCenter
        }

        stickerVisible: file.isDownloadingCompleted && loader.status == Loader.Ready
        stickerData: message.stickerData

        property size scaledSize: appSettings.downscaleAnimatedStickers
                                  ? Qt.size(Theme.itemSizeSmall, Theme.itemSizeSmall * aspectRatio)
                                  : Qt.size(width, height)

        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: Component {
                LottieItem {
                    id: animatedSticker
                    width: parent.width
                    height: parent.height

                    autoLoad: false
                    source: sticker.file.path
                    scaledSize: sticker.scaledSize // FIXME: for some reason the quality is still not ideal with dices

                    paused: !Qt.application.active
                    loop: false

                    Component.onCompleted:
                        if (completed) {
                            paused = true
                            currentFrame = frameCount - 2
                            if (!sticker.file.isDownloadingCompleted)
                                autoLoad = true
                        } else
                            begin()

                    layer.enabled: message.highlighted
                    layer.effect: PressEffect { source: animatedSticker }
                }
            }
        }
    }

    Loader {
        anchors.fill: sticker
        anchors.centerIn: sticker
        active: diceSticker['@type'] === "diceStickersSlotMachine"
        sourceComponent: Component {
            Item {
                width: parent.width
                height: parent.height

                // For some reason, when doing this first and second reel stop at around the same time, which isn't correct
                /*Instantiator {
                    id: reelsFilesInstantiator
                    model: [diceSticker.left_reel, diceSticker.center_reel, diceSticker.right_reel]
                    asynchronous: true
                    delegate: TDLibFile {
                        tdlib: tdLibWrapper
                        fileInformation: modelData.sticker
                        autoLoad: true
                        onIsDownloadingCompletedChanged: {
                            if (isDownloadingCompleted) {
                                reelsPaths[index] = path
                                reelsPathsChanged()
                            }
                        }
                    }
                }

                property var reelsPaths: [undefined,undefined,undefined]
                onReelsPathsChanged:
                    if (reelsPaths.every(function(x) { return !!x })) {
                        // IMPORTANT: don't use QJsonDocument here, as it doesn't preserve order and rlottie doesn't work like that!
                        Debug.log("Merging reels")
                        reelsFilesInstantiator.active = false

                        var merged = JSON.parse(utilities.uncompressLocalFile(reelsPaths[0]))
                        reelsPaths.slice(1).forEach(function (path) {
                            var reel = JSON.parse(utilities.uncompressLocalFile(path))
                            var name = reel.nm
                            reel.assets.forEach(function (asset) {
                                asset.id = name + '_' + asset.id
                                merged.assets.push(asset)
                            })
                            reel.layers.forEach(function (layer) {
                                if ('refId' in layer)
                                    layer.refId = name + '_' + layer.refId
                                merged.layers.push(layer)
                            })
                        })

                        merged = JSON.stringify(merged)
                        reelsLottieItem.source = "data:,"+merged
                    }

                LottieItem {
                    id: reelsLottieItem
                    width: parent.width
                    height: parent.height
                    scaledSize: sticker.scaledSize
                    loop: false
                }*/

                Repeater {
                    model: [diceSticker.left_reel, diceSticker.center_reel, diceSticker.right_reel]
                    LottieItem {
                        anchors.fill: parent
                        autoLoad: false
                        source: reelFile.path
                        scaledSize: sticker.scaledSize

                        loop: false
                        paused: !Qt.application.active

                        Component.onCompleted:
                            if (completed) {
                                paused = true
                                currentFrame = frameCount - 2
                                if (!reelFile.isDownloadingCompleted)
                                    autoLoad = true
                            } else
                                begin()

                        TDLibFile {
                            id: reelFile
                            tdlib: tdLibWrapper
                            fileInformation: modelData.sticker
                            autoLoad: true
                        }

                        layer.enabled: message.highlighted
                        layer.effect: PressEffect { source: animatedSticker }
                    }
                }

                LottieItem {
                    anchors.fill: parent
                    autoLoad: false
                    source: slotLeverFile.path
                    scaledSize: sticker.scaledSize

                    loop: false
                    paused: !Qt.application.active

                    Component.onCompleted:
                        if (completed) {
                            paused = true
                            currentFrame = frameCount - 2
                            if (!slotLeverFile.isDownloadingCompleted)
                                autoLoad = true
                        } else
                            begin()

                    TDLibFile {
                        id: slotLeverFile
                        tdlib: tdLibWrapper
                        fileInformation: diceSticker.lever.sticker
                        autoLoad: true
                    }

                    layer.enabled: message.highlighted
                    layer.effect: PressEffect { source: animatedSticker }
                }
            }
        }
    }

    onClicked: {
        var canSend = hasSendPrivilege('can_send_other_messages')
        var chatId = chatInformation.id, emojiCopy = emoji // So if the message item is deleted, notification would still work
        appNotification.show(qsTr("Send a %1 emoji to any chat to try your luck.", "in-app notification text").arg(emoji),
                             canSend ? function() { tdLibWrapper.sendDiceMessage(chatId, emojiCopy) } : null,
                             canSend ? qsTr("Send", 'in-app notification button for "Send a %1 emoji to any chat to try your luck."') : null)
    }
}
