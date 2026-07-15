//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

MessageContentFileInfoBase {
    id: contentItem
    fileInformation: rawMessage.content.document.document

    primaryText: Emoji.emojify(rawMessage.content.document.file_name || "", primaryLabel.font.pixelSize)

    minithumbnail: rawMessage.content.document.minithumbnail
    thumbnail: rawMessage.content.document.thumbnail

    leftButton {
        icon.source: Theme.iconForMimeType(rawMessage.content.document.mime_type)
        onClicked: {
            if (!file.isDownloadingActive)
                file.load()
            else
                file.cancel()
        }
    }

    property alias openMouseArea: openMouseArea

    function download() {
        if (file.isDownloadingCompleted)
            tdLibWrapper.copyFileToDownloads(file.fileId, file.path, true)
    }

    states: [
        State {
            when: file.isDownloadingCompleted
            //PropertyChanges { target: openMouseArea; enabled: true }
            PropertyChanges {
                target: primaryLabel
                color: (contentItem.highlighted || openMouseArea.pressed) ? Theme.highlightColor : Theme.primaryColor
            }
            PropertyChanges {
                target: secondaryLabel
                color: (contentItem.highlighted || openMouseArea.pressed) ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
            PropertyChanges {
                target: tertiaryLabel
                color: (contentItem.highlighted || openMouseArea.pressed) ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
            PropertyChanges {
                target: leftButton
                highlighted: contentItem.highlighted || openMouseArea.pressed
            }
        }

    ]
    MouseArea {
        id: openMouseArea
        enabled: file.isDownloadingCompleted
        visible: enabled
        anchors {
            fill: primaryItem // fill the whole
            rightMargin: copyButton.width
        }
        onClicked: download()
    }
}
