//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import QtMultimedia 5.6
import QtGraphicalEffects 1.0
import '../..'
import '../../tdlib'

TDLibVideo {
    id: video
    messageContent: _model.content
    readonly property bool isCurrent: index === page.index
    onIsCurrentChanged: if(!isCurrent) pause()

    onStatusChanged: {
        if(status === MediaPlayer.EndOfMedia) {
            page.overlayActive = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: page.overlayActive = !page.overlayActive
    }

    Timer {
        id: delayedOverlayHide
        interval: 500
        onTriggered: {
            if(video.isPlaying) {
                page.overlayActive = false
            }
        }
    }
    onPlaying: delayedOverlayHide.start()

    OpaqueButton {
        anchors.centerIn: parent
        enabled: videoUI.active || !downloadingCompleted
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        icon.source: "image://theme/icon-l-"+(video.isPlaying || video.shouldPlay ? 'pause' : 'play')
        onClicked: toggle()
    }

    ProgressCircle {
        opacity: file.isDownloadingActive ? 1 : 0
        Behavior on opacity { FadeAnimator {} }
        anchors.centerIn: parent
        value: file.isDownloadingCompleted ? 1 : (file.downloadedSize / file.size)
    }
    Item {
        id: videoUI
        property bool active: overlay.active// && file.isDownloadingCompleted
        opacity: active ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        height: parent.height

        Row {
            id: controlsRow
            anchors {
                bottom: sliderRow.top
                //bottomMargin: Theme.paddingLarge
            }
            width: parent.width
            visible: false
            spacing: Theme.paddingLarge

            Slider {
                width: parent.width - (muteButton.width) - parent.spacing*1
                leftMargin: 0
                rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                enabled: videoUI.active
                property real previousValue
                Component.onCompleted: previousValue = sliderValue
                onSliderValueChanged: {
                    if (!down) {
                        previousValue = sliderValue
                        parent.visible = false
                    }
                    video.playbackRate = sliderValue
                }
                onDownChanged: {
                    if (!down && previousValue != sliderValue) {
                        previousValue = sliderValue
                        parent.visible = false
                    }
                }

                value: video.playbackRate
                minimumValue: 0.25
                maximumValue: 2.5
                stepSize: 0.25
                valueText: sliderValue+'x'
            }

            IconButton {
                id: muteButton
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-speaker-mute"
                enabled: videoUI.active
                highlighted: down || video.muted
                onClicked: {
                    video.muted = !video.muted
                    parent.visible = false
                }
            }
        }

        Row {
            id: sliderRow
            width: parent.width
            spacing: Theme.paddingLarge
            anchors {
                bottom: parent.bottom
                bottomMargin: page.singleElement ? Theme.itemSizeMedium : Theme.itemSizeExtraLarge
            }

            Slider {
                width: parent.width - (controlsButton.width) - parent.spacing*1
                leftMargin: 0
                rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                value: video.position
                minimumValue: 0
                maximumValue: video.duration || 0.1
                enabled: videoUI.active && video.seekable
                handleVisible: false
                animateValue: true
                stepSize: 500
                valueText: value > 0 || down ? Format.formatDuration(value/1000) : ''
                onDownChanged: {
                    if(!down) {
                        video.seek(value)
                        value = Qt.binding(function() { return video.position })
                    }
                }
                Label {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        bottom: parent.bottom
                        topMargin: Theme.paddingSmall
                    }
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: file.isDownloadingCompleted
                          ? Format.formatDuration((parent.maximumValue - parent.value)/1000)
                          : (video.videoData.duration
                            ? Format.formatDuration(video.videoData.duration, Formatter.Duration) + ', '
                            : '') + Format.formatFileSize(file.size || file.expectedSize)
                    color: Theme.secondaryColor
                }
            }

            IconButton {
                id: controlsButton
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-setting"
                enabled: videoUI.active
                highlighted: controlsRow.visible ? !down : down
                onClicked:
                    controlsRow.visible = !controlsRow.visible
            }
        }
    }
}
