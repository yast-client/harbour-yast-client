//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import App.Logic 1.0
import "../../js/twemoji.js" as Emoji
import "../../js/debug.js" as Debug

Item {
    id: voiceNoteOverlayItem
    anchors.fill: parent

    property int recordingDuration: Math.round(voiceNoteRecorder.voiceNoteDuration / 1000)
    property bool recordingDone: false;

    function getTwoDigitString(numberToBeConverted) {
        var numberString = "00";
        if (numberToBeConverted > 0 && numberToBeConverted < 10) {
            numberString = "0" + String(numberToBeConverted);
        }
        if (numberToBeConverted >= 10) {
            numberString = String(numberToBeConverted);
        }
        return numberString;
    }

    onRecordingDurationChanged: {
        if (voiceNoteRecorder.voiceNoteDuration === -1)
            return

        var minutes = Math.floor(recordingDuration / 60);
        var seconds = recordingDuration % 60;
        recordingDurationLabel.text = getTwoDigitString(minutes) + ":" + getTwoDigitString(seconds);
    }

    Rectangle {
        id: stickerPickerOverlayBackground
        anchors.fill: parent

        color: Theme.overlayBackgroundColor
        opacity: Theme.opacityHigh
    }

    Flickable {
        id: voiceNoteFlickable
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium

        Behavior on opacity { NumberAnimation {} }

        contentHeight: voiceNoteColumn.height
        clip: true

        Column {
            id: voiceNoteColumn
            spacing: Theme.paddingMedium
            width: voiceNoteFlickable.width

            InfoLabel {
                text: qsTr("Record a Voice Note")
            }

            Label {
                wrapMode: Text.Wrap
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Press the button to start recording")
                font.pixelSize: Theme.fontSizeMedium
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Item {
                width: Theme.iconSizeExtraLarge
                height: Theme.iconSizeExtraLarge
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    color: Theme.primaryColor
                    opacity: Theme.opacityOverlay
                    width: Theme.iconSizeExtraLarge
                    height: Theme.iconSizeExtraLarge
                    anchors.centerIn: parent
                    radius: width / 2
                }

                Rectangle {
                    id: recordButton
                    color: "red"
                    width: Theme.iconSizeExtraLarge * 0.6
                    height: Theme.iconSizeExtraLarge * 0.6
                    anchors.centerIn: parent
                    radius: width / 2
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            recordButton.visible = false;
                            recordingDone = false;
                            recordingDurationLabel.text = "00:00"
                            voiceNoteRecorder.startRecordingVoiceNote()
                        }
                    }
                }

                Rectangle {
                    id: stopButton
                    visible: !recordButton.visible
                    color: Theme.overlayBackgroundColor
                    width: Theme.iconSizeExtraLarge * 0.4
                    height: Theme.iconSizeExtraLarge * 0.4
                    anchors.centerIn: parent
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            recordButton.visible = true
                            voiceNoteRecorder.stopRecordingVoiceNote()
                            recordingDone = true
                        }
                    }
                }
            }

            Label {
                id: recordingStateLabel
                wrapMode: Text.Wrap
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
                text: switch (voiceNoteRecorder.voiceNoteRecordingState) {
                case VoiceNoteRecorder.Unavailable: return qsTr("Unavailable")
                case VoiceNoteRecorder.Ready: return qsTr("Ready")
                case VoiceNoteRecorder.Starting: return qsTr("Starting")
                case VoiceNoteRecorder.Recording: return qsTr("Recording")
                case VoiceNoteRecorder.Stopping: return qsTr("Stopping")
                }
            }

            Label {
                id: recordingDurationLabel
                wrapMode: Text.Wrap
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeMedium
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Button {
                visible: recordingDone
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                text: qsTr("Use recording")
                onClicked: {
                    attachmentOptionsFlickable.show = false
                    attachmentPreviewRow.isVoiceNote = true
                    attachmentPreviewRow.attachmentDescription = qsTr("Voice Note (%1)").arg(recordingDurationLabel.text)
                    voiceNoteOverlayLoader.active = false
                }
            }

        }
    }

}
