//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

InlineQueryResultDefaultBase {
    id: queryResultItem
    property string locationId
    property var resultData: model.venue

    title: Emoji.emojify(queryResultItem.resultData.title || (queryResultItem.resultData.location.latitude + ":" + queryResultItem.resultData.location.longitude), titleLable.font.pixelSize)
    description: Emoji.emojify(queryResultItem.resultData.address || "", descriptionLabel.font.pixelSize)
    extraText: Emoji.emojify(queryResultItem.resultData.type || "", extraTextLabel.font.pixelSize)


    Connections {
        target: tdLibWrapper
        onFileUpdated: {
            if(fileInformation["@extra"] === queryResultItem.locationId) {
                thumbnailFileInformation = fileInformation
            }

        }
    }

    Component.onCompleted: {
        var dimensions = [ Math.round(thumbnail.width), Math.round(thumbnail.height)];

        locationId = "location:" + resultData.location.latitude + ":" + resultData.location.longitude + ":" + dimensions[0] + ":" + dimensions[1];

        tdLibWrapper.getMapThumbnailFile(chatId, resultData.location.latitude, resultData.location.longitude, dimensions[0], dimensions[1], locationId);
    }
}
