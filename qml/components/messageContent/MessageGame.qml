//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../"
import "../../js/functions.js" as Functions
import "../../js/twemoji.js" as Emoji


MessageContentBase {
    id: messageContent
    height: gamePreviewItem.height

    Column {
        id: gamePreviewItem
        width: parent.width
        height: childrenRect.height


        Label {
            width: parent.width
            font.bold: true
            font.pixelSize: Theme.fontSizeSmall
            text: Emoji.emojify(rawMessage.content.game.title || "", font.pixelSize)
            truncationMode: TruncationMode.Fade
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
        }
        Label {
            width: parent.width
            font.pixelSize: Theme.fontSizeExtraSmall
            text: Emoji.emojify(rawMessage.content.game.description || "", font.pixelSize)
            truncationMode: TruncationMode.Fade
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
        }
        Label {
            width: parent.width
            font.pixelSize: Theme.fontSizeExtraSmall
            text: Emoji.emojify(Functions.enhanceMessageText(rawMessage.content.game.text) || "", font.pixelSize)
            truncationMode: TruncationMode.Fade
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            onLinkActivated:
                utilities.handleLink(link, chatInformation.id)
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }

        Image {
            id: thumbnail
            source: thumbnailFile.isDownloadingCompleted ? thumbnailFile.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: opacity > 0
            opacity: status === Image.Ready ? 1.0 : 0.0
            width: parent.width

            Behavior on opacity { FadeAnimation {} }
            layer.enabled: messageContent.highlighted
            layer.effect: PressEffect { source: thumbnail }

            TDLibFile {
                id: thumbnailFile
                tdlib: tdLibWrapper
                autoLoad: true
            }
            Rectangle {
                width: Theme.iconSizeMedium
                height: width
                anchors {
                    top: parent.top
                    topMargin: Theme.paddingSmall
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                }

                color: Theme.rgba(Theme.overlayBackgroundColor, 0.2)
                radius: Theme.paddingSmall
                Icon {
                    id: icon
                    source: "image://theme/icon-m-game-controller"
                    asynchronous: true
                }
            }
        }

        Component.onCompleted: {
            if (rawMessage.content.game.photo) {
                // Check first which size fits best...
                var photo = utilities.findPhotoSize(rawMessage.content.game.photo.sizes, gamePreviewItem.width).photo
                if (photo)
                    thumbnailFile.fileInformation = photo
            }
        }
    }
}
