import QtQuick 2.6
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import QtMultimedia 5.6
import QtGraphicalEffects 1.0
import "../.."

TDLibVideo {
    id: videoComponent
    messageContent: model.modelData.content
    readonly property bool isCurrent: index === page.index
    onIsCurrentChanged: if(!isCurrent) video.pause()

    onStatusChanged: {
        if(status === MediaPlayer.EndOfMedia) {
            page.overlayActive = true
        }
    }

    Binding {
        target: overlay
        property: "videoSpeed"
        value: playbackRate
    }

    Binding {
        target: overlay
        property: "videoControlsVisible"
        value: controlsRow.visible
    }

    Connections {
        target: overlay
        onSpeedButtonClicked: controlsRow.visible = !controlsRow.visible
    }

    MouseArea {
        anchors.fill: parent
        onClicked: page.overlayActive = !page.overlayActive
    }

    Timer {
        id: delayedOverlayHide
        interval: 500
        onTriggered: {
            if(videoComponent.isPlaying) {
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

        icon.source: "image://theme/icon-l-"+(videoComponent.isPlaying || videoComponent.shouldPlay ? 'pause' : 'play')
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
        anchors.fill: parent
        opacity: active ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        Row {
            id: controlsRow
            anchors {
                bottom: slider.top
                //bottomMargin: Theme.paddingLarge
            }
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            visible: false
            spacing: Theme.paddingLarge

            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - (muteButton.width) - parent.spacing*1
                leftMargin: 0
                rightMargin: 0

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

        Slider {
            id: slider
            value: video.position
            minimumValue: 0
            maximumValue: video.duration || 0.1
            enabled: parent.active && video.seekable
            width: parent.width
            handleVisible: false
            animateValue: true
            stepSize: 500
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.itemSizeMedium
            }
            valueText: value > 0 || down ? Format.formatDuration(value/1000) : ''
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
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
                      : (videoComponent.videoData.duration
                        ? Format.formatDuration(videoComponent.videoData.duration, Formatter.Duration) + ', '
                        : '') + Format.formatFileSize(file.size || file.expectedSize)
                color: Theme.secondaryColor
            }
        }
    }
}
