//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

AccordionItem {
    name: "advanced"
    title: qsTr("Advanced")
    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium

            /*Slider {
                width: parent.width
                label: qsTr("Voice note volume")
                minimumValue: 1
                maximumValue: 15.0
                stepSize: 1
                value: appSettings.voiceNoteVolume
                valueText: value
                onValueChanged: appSettings.voiceNoteVolume = sliderValue
            }*/

            TextField {
                width: parent.columnWidth
                label: qsTr("Voice messages volume")
                validator: RegExpValidator { regExp: /^((?:\d|[1-9]\d+)(?:\.\d+)?)$/ }
                text: appSettings.voiceNoteVolume
                onTextChanged: if (acceptableInput) appSettings.voiceNoteVolume = text
                onAcceptableInputChanged: if (acceptableInput) appSettings.voiceNoteVolume = text
            }

            TextSwitch {
                width: parent.columnWidth
                visible: appSettings.showTranslateOption
                checked: appSettings.formattedTranslate
                text: qsTr("Translate formatted text")
                automaticCheck: false
                onClicked: appSettings.formattedTranslate = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.forceQtAudioRecorder
                text: qsTr("Force QtMultimedia-based audio recorder")
                automaticCheck: false
                onClicked: appSettings.forceQtAudioRecorder = !checked
                visible: NO_HARBOUR_COMPLIANCE
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.forceAllowAISummary
                text: qsTr("Forcefully allow AI summary")
                automaticCheck: false
                onClicked: appSettings.forceAllowAISummary = !checked
            }

            Column {
                width: parent.columnWidth
                visible: NO_HARBOUR_COMPLIANCE

                SectionHeader { text: qsTr("Calls") }

                TextSwitch {
                    text: qsTr("Save call logs")
                    description: qsTr("Save logs from tgcalls to Downloads")
                    checked: yaqtSettings.saveCallLogs
                    automaticCheck: false
                    onClicked: yaqtSettings.saveCallLogs = !checked
                }
            }
        }
    }
}
