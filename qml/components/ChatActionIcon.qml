//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

Loader {
    active: !!sourceComponent // FIXME: binding loop here
    visible: active
    width: active ? (item ? item.width : Theme.iconSizeSmall) : 0
    height: Theme.iconSizeExtraSmall
    anchors.verticalCenter: parent.verticalCenter

    property int type
    property real actionProgress

    sourceComponent:
        switch (type) {
        case TDLibAPI.Typing:
            return typingComponent
        case TDLibAPI.RecordingVoiceNote:
            return voiceNoteComponent
        case TDLibAPI.RecordingVideo:
        case TDLibAPI.RecordingVideoNote:
            return videoComponent
        case TDLibAPI.UploadingDocument:
        case TDLibAPI.UploadingPhoto:
        case TDLibAPI.UploadingVideo:
        case TDLibAPI.UploadingVideoNote:
        case TDLibAPI.UploadingVoiceNote:
            return uploadingComponent
        default: // TODO
            return null
        }

    Component {
        id: typingComponent
        Row {
            width: Theme.paddingMedium*3 + spacing*2
            height: parent.height
            spacing: Theme.paddingSmall/2

            Repeater {
                model: 3
                Rectangle {
                    color: Theme.highlightColor
                    height: Theme.paddingMedium
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    radius: width
                    scale: 0.5

                    SequentialAnimation on scale {
                        loops: Animation.Infinite

                        PauseAnimation { duration: index * 150 }
                        NumberAnimation {
                            to: 1.0
                            duration: 200
                            easing.type: Easing.OutCirc
                        }
                        NumberAnimation {
                            to: 0.5
                            duration: 200
                            easing.type: Easing.InCirc
                        }
                        PauseAnimation { duration: (2 - index) * 150 }
                    }
                }
            }
        }
    }

    Component {
        id: voiceNoteComponent
        Row {
            width: Theme.paddingMedium*3 + spacing*2
            height: parent.height
            spacing: Theme.paddingSmall/2

            Repeater {
                model: 3
                Rectangle {
                    color: Theme.highlightColor
                    width: Theme.paddingMedium
                    height: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.paddingSmall/2

                    SequentialAnimation on height {
                        loops: Animation.Infinite

                        PauseAnimation { duration: index * 150 }
                        NumberAnimation {
                            to: parent.height - Theme.paddingSmall
                            duration: 200
                            easing.type: Easing.OutCirc
                        }
                        NumberAnimation {
                            to: Theme.paddingSmall
                            duration: 200
                            easing.type: Easing.InCirc
                        }
                        PauseAnimation { duration: (2 - index) * 150 }
                    }
                }
            }
        }
    }

    Component {
        id: videoComponent
        BusyIndicator {
            width: Theme.iconSizeSmall
            height: width
            running: true
            size: BusyIndicatorSize.Small

            Icon {
                // FIXME: this is not fully centered
                source: "image://theme/icon-m-file-video"
                width: Theme.iconSizeExtraSmall
                height: width
                anchors.centerIn: parent
                sourceSize {
                    width: width
                    height: height
                }
            }
        }
    }

    Component {
        id: uploadingComponent
        ProgressBar {
            width: Theme.iconSizeSmall
            anchors.bottom: parent.bottom
            leftMargin: 0
            rightMargin: Theme.paddingMedium
            //y: -Theme.paddingMedium // not working
            indeterminate: progress <= 0
            value: progress
            highlighted: true

            property var contentColumn: children[0]
            property var backgroundItem: {
                var items = contentColumn.children
                for (var i=0; i < items.length; i++)
                    if (items[i].dimmed)
                        return items[i]
                return null
            }
            property var highlightItem: {
                var items = backgroundItem.children
                for (var i=0; i < items.length; i++)
                    if (items[i].dimmed === false)
                        return items[i]
                return null
            }
            Component.onCompleted: {
                contentColumn.y = 0
                highlightItem.dashLength = Theme.paddingSmall
                highlightItem.dashMargin = Theme.paddingSmall*2
            }

            Icon {
                width: Theme.iconSizeExtraSmall
                height: width
                sourceSize {
                    width: width
                    height: height
                }
                x: (parent.width - parent.rightMargin - width) / 2 // FIXME: this is not fully accurate

                source:
                    switch (type) {
                    case TDLibAPI.UploadingDocument:
                        return "image://theme/icon-m-file-document"
                    case TDLibAPI.UploadingPhoto:
                        return "image://theme/icon-m-file-image"
                    case TDLibAPI.UploadingVideo:
                    case TDLibAPI.UploadingVideoNote:
                        return "image://theme/icon-m-file-video"
                    case TDLibAPI.UploadingVoiceNote:
                        return "image://theme/icon-m-call-recording-on"
                    }
            }
        }
    }
}
