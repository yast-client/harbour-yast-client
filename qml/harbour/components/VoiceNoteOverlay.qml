/*
    Copyright (C) 2020-21 Sebastian J. Wolf and other contributors

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
import App.Logic 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/debug.js" as Debug

Item {
    id: voiceNoteOverlayItem
    anchors.fill: parent

    property int recordingDuration: Math.round(utilities.voiceNoteDuration / 1000)
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
                            utilities.startRecordingVoiceNote();
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
                            recordButton.visible = true;
                            utilities.stopRecordingVoiceNote();
                            recordingDone = true;
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
                text: switch (utilities.voiceNoteRecordingState) {
                case Utilities.Unavailable: return qsTr("Unavailable")
                case Utilities.Ready: return qsTr("Ready")
                case Utilities.Starting: return qsTr("Starting")
                case Utilities.Recording: return qsTr("Recording")
                case Utilities.Stopping: return qsTr("Stopping")
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

