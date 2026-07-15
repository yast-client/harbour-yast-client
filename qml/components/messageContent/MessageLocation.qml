//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import '../tdlib'

MessageContentBase {
    id: contentItem
    height: width * 0.66666666;

    property var locationData : rawMessage.content.location
    property string fileExtra;

    onClicked: {
        Qt.openUrlExternally("geo:" + locationData.latitude + "," + locationData.longitude);
    }
    onLocationDataChanged: updatePicture()
    onWidthChanged: updatePicture()

    function updatePicture() {
        if (locationData) {
            fileExtra = "location:" + locationData.latitude + ":" + locationData.longitude + ":" + Math.round(contentItem.width) + ":" + Math.round(contentItem.height);
            tdLibWrapper.getMapThumbnailFile(rawMessage.chat_id, locationData.latitude, locationData.longitude, Math.round(contentItem.width), Math.round(contentItem.height), fileExtra);
        }
    }

    Connections {
        target: tdLibWrapper
        onFileUpdated: {
            if(fileInformation["@extra"] === contentItem.fileExtra) {
                if(fileInformation.id !== image.file.fileId) {
                    image.fileInformation = fileInformation
                }
            }
        }
    }

    TDLibImage {
        id: image
        anchors.fill: parent
        cache: false
        highlighted: contentItem.highlighted
        Item {
            anchors.centerIn: parent
            width: markerImage.width
            height: markerImage.height * 1.75 // 0.875 (vertical pin point) * 2
            Icon {
                id: markerImage
                source: 'image://theme/icon-m-location'
            }

            DropShadow {
                anchors.fill: markerImage
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8.0
                samples: 17
                color: Theme.colorScheme ? Theme.lightPrimaryColor : Theme.darkPrimaryColor
                source: markerImage
            }
        }
    }

    BackgroundImage {
        visible: image.status !== Image.Ready
    }

    Component.onCompleted: {
        updatePicture();
    }
}
