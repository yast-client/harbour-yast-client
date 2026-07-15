//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import QtMultimedia 5.6
import QtGraphicalEffects 1.0

Video {
    property var messageContent: ({})
    property var videoData: {
        switch (messageContent['@type']) {
        case "messageVideo":
            return messageContent.video
        case "messageAnimation":
            return messageContent.animation
        case "messageVideoNote":
            return messageContent.video_note

        default:
            return messageContent.video
        }
    }

    property bool shouldPlay

    property alias file: file
    property alias thumbnail: thumbnail
    property alias downloadingCompleted: file.isDownloadingCompleted

    readonly property string videoType: videoData['@type'] === "videoNote" ? "video" : videoData['@type']
    readonly property bool isPlaying: video.playbackState === MediaPlayer.PlayingState

    source: downloadingCompleted ? file.path : ''
    onShouldPlayChanged: if (shouldPlay) file.load()
                         else file.cancel()
    function toggle() {
        if (!downloadingCompleted) {
            // see onShouldPlayChanged
            shouldPlay = !shouldPlay
            return
        }

        if (isPlaying) video.pause()
        else video.play()
    }

    TDLibThumbnail {
        id: thumbnail
        width: parent.width //don't use anchors here for easier custom scaling
        height: parent.height

        property bool active: !downloadingCompleted || (!video.isPlaying && (video.position === 0 || video.status === MediaPlayer.EndOfMedia))
        opacity: active ? 1 : 0
        visible: active || opacity > 0

        thumbnail: videoData.thumbnail
        minithumbnail: videoData.minithumbnail
        fillMode: Image.PreserveAspectFit
    }

    TDLibFile {
        id: file
        autoLoad: false
        tdlib: tdLibWrapper
        fileInformation: videoData[videoType]
        onDownloadingCompletedChanged: {
            if(isDownloadingCompleted) {
                video.source = file.path
                if(video.shouldPlay) {
                    video.play()
                    video.shouldPlay = false
                }
            }
        }
    }
}
