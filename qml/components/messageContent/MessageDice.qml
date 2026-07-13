import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../tdlib'
import '../../js/debug.js' as Debug

// TODO: if needed later, respect appSettings.showStickersAsEmojis
// also, if the current user sends a dice in the current chat from another device, it is considered completed, which is wrong
MessageContentBase {
    id: message

    readonly property var diceSticker: rawMessage.content.final_state || rawMessage.content.initial_state || {}
    readonly property string emoji: rawMessage.content.emoji
    readonly property bool isSlotMachine: diceSticker['@type'] === "diceStickersSlotMachine"
    readonly property var stickerData: (isSlotMachine ? diceSticker.background : diceSticker.sticker) || {}
    readonly property bool isOwnSticker: !!(messageListItem && messageListItem.isOwnMessage)

    // do not play animation when viewing history
    property bool completed
    Component.onCompleted: {
        if (!generatedContentUnread && rawMessage.content.value > 0)
            completed = true
    }

    implicitWidth: Theme.itemSizeExtraLarge
    implicitHeight: width * sticker.aspectRatio

    TDLibStickerBase {
        id: sticker
        width: Math.min(parent.width, parent.implicitWidth)
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

                    onLoopFinished:
                        if (!isSlotMachine)
                            chatManager.model.markGeneratedContentAsRead(messageIndex)

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

                property bool leftReelStopped
                property bool centerReelStopped
                property bool rightReelStopped
                property bool reelsStopped: leftReelStopped && centerReelStopped && rightReelStopped

                onReelsStoppedChanged: {
                    if (reelsStopped)
                        messagesModel.markGeneratedContentAsRead(messageIndex)
                }

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

                        onLoopFinished:
                            switch (index) {
                            case 0:
                                leftReelStopped = true
                                break
                            case 1:
                                centerReelStopped = true
                                break
                            case 2:
                                rightReelStopped = true
                                break
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
                             canSend ? function() { tdLibWrapper.sendDiceMessage(chatId, emojiCopy, 0, topicId) } : null,
                             canSend ? qsTr("Send", 'in-app notification button for "Send a %1 emoji to any chat to try your luck."') : null)
    }
}
