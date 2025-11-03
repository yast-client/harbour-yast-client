/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

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
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.KeepAlive 1.2
import WerkWolf.Fernschreiber 1.0
import QtMultimedia 5.6
import ".."
import "../../js/functions.js" as Functions

MessageContentBase {
    id: videoMessageComponent

    property bool loop

    height: Functions.getVideoHeight(width, video.videoData)

    DisplayBlanking {
        // will automatically reset on destruction
        id: displayBlanking
    }

    Timer {
        id: screensaverTimer
        interval: 30000
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: displayBlanking.preventBlanking = true
    }

    function preventBlanking() {
        screensaverTimer.start()
    }

    function disablePreventBlanking() {
        screensaverTimer.stop()
        displayBlanking.preventBlanking = false
    }

    TDLibVideo {
        id: video
        anchors.fill: parent
        messageContent: rawMessage.content

        onPlaying: {
            preventBlanking()
            timeLeftItem.visible = true
            timeLeftTimer.restart()
        }

        function handlePause() {
            disablePreventBlanking()
            timeLeftTimer.stop()
            timeLeftItem.visible = true
        }
        onPaused: handlePause()
        onStopped: {
            if (loop && status == MediaPlayer.EndOfMedia) play()
            else handlePause()
        }
    }

    Rectangle {
        width: parent.width
        height: parent.height
        color: "lightgrey"
        visible: video.thumbnail.status === Image.Error
        opacity: 0.3
    }

    Rectangle {
        id: errorTextOverlay
        color: "black"
        opacity: 0.8
        width: parent.width
        height: parent.height
        visible: errorText.visible
    }

    Text {
        id: errorText
        visible: !!text
        width: parent.width
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.Wrap
        text: video.error === MediaPlayer.NoError ? '' : qsTr("Error loading video! %1").arg(video.errorString)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: video.toggle()
    }

    Timer {
        id: timeLeftTimer
        interval: 2000
        onTriggered: timeLeftItem.visible = false
    }

    Item {
        id: timeLeftItem
        anchors {
            fill: parent
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation {} }

        Rectangle {
            id: positionTextOverlay
            color: "black"
            opacity: 0.3
            width: parent.width
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            visible: pausedRow.visible
        }

        Row {
            id: pausedRow
            width: parent.width
            height: parent.height - (messageVideoSlider.visible ? messageVideoSlider.height : 0)

            visible: video.playbackState !== MediaPlayer.PlayingState
            Item {
                width: parent.width / 2
                height: parent.height
                OpaqueButton {
                    id: playButton
                    anchors.centerIn: parent
                    icon.source: "image://theme/icon-l-" + (video.file.isDownloadingActive ? "clear" : "play") + "?white"
                    highlighted: videoMessageComponent.highlighted || down
                    onClicked: video.toggle()
                }

                BusyIndicator {
                    running: video.file.isDownloadingActive
                    visible: running
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Large
                }
            }
            Item {
                id: fullscreenItem
                width: parent.width / 2
                height: parent.height
                OpaqueButton {
                    anchors.centerIn: parent
                    highlighted: videoMessageComponent.highlighted || down
                    icon.source: "../../../images/icon-l-fullscreen.svg"
                    onClicked: pageStack.push(Qt.resolvedUrl("../../pages/MediaAlbumPage.qml"), {
                        message: rawMessage,
                        singleElement: rawMessage.content['@type'] !== 'messageVideo' // GIFs and video messages models are not yet supported...
                    })
                }
            }
        }

        Slider {
            id: messageVideoSlider
            width: parent.width
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
            }
            highlighted: videoMessageComponent.highlighted || down

            minimumValue: 0
            stepSize: 1
            enabled: video.seekable

            states: [
                State {
                    when: video.file.isDownloadingActive
                    PropertyChanges {
                        target: messageVideoSlider
                        handleVisible: false
                        visible: true
                        maximumValue: video.file.size > 0 ? video.file.size : 0.1
                        value: video.file.downloadedSize
                    }
                },
                State {
                    when: !video.file.isDownloadingActive
                    PropertyChanges {
                        target: messageVideoSlider
                        valueText: Format.formatDuration(Math.round((video.duration - messageVideoSlider.value) / 1000))
                        visible: video.duration > 0
                        maximumValue: video.duration > 0 ? video.duration : 0.1
                        value: video.position
                    }
                }
            ]

            onReleased: {
                video.seek(Math.floor(value))
                video.play()
                timeLeftTimer.start()
            }
        }
    }
}
