//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../.."

InlineQueryResult {
    id: queryResultItem

    property alias title: titleLabel.text
    property alias titleLable: titleLabel

    property alias description: descriptionLabel.text
    property alias descriptionLabel: descriptionLabel

    property alias extraText: extraTextLabel.text
    property alias extraTextLabel: extraTextLabel

    property alias thumbnailFileInformation: thumbnailFile.fileInformation
    property alias thumbnail: thumbnail

    property alias icon: icon


    Image {
        id: thumbnail
        source: thumbnailFile.isDownloadingCompleted ? thumbnailFile.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        width: visible ? Theme.itemSizeLarge : 0
        height: width
        opacity: status === Image.Ready ? 1.0 : 0.0

        Behavior on opacity { FadeAnimation {} }
        layer.enabled: queryResultItem.pressed
        layer.effect: PressEffect { source: thumbnail }

        TDLibFile {
            id: thumbnailFile
            tdlib: tdLibWrapper
            autoLoad: true
        }
    }
    Icon {
        id: icon
        asynchronous: true
        anchors.centerIn: thumbnail
        Behavior on opacity { FadeAnimation {} }
    }

    Column {
        anchors {
            left: thumbnail.right
            leftMargin: thumbnail.visible ? Theme.paddingLarge : Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: titleLabel
            width: parent.width
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted || !queryResultItem.enabled ? Theme.highlightColor : Theme.primaryColor
            visible: text.length > 0
            truncationMode: TruncationMode.Fade
        }
        Label {
            id: descriptionLabel
            width: parent.width
            font.pixelSize: Theme.fontSizeTiny
            color: highlighted || !queryResultItem.enabled ? Theme.secondaryColor : Theme.secondaryHighlightColor
            visible: text.length > 0
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: extraTextLabel
            width: parent.width
            font.pixelSize: Theme.fontSizeTiny
            color: highlighted || !queryResultItem.enabled ? Theme.secondaryHighlightColor : Theme.secondaryColor
            visible: text.length > 0
            truncationMode: TruncationMode.Fade
        }
    }
}
