//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    // Silica TimePickerDialog doesn't work that well for durations, so we use a custom one

    property alias title: header.title

    property alias maxDays: daysValidator.top
    property int days

    property alias hours: picker.hour
    property alias minutes: picker.minute
    property alias seconds: picker._second
    property alias mode: picker._mode // 0 - HoursAndMinutes, 1 - MinutesAndSeconds

    property bool hoursAndMinutes: mode == 0
    readonly property int allSeconds: hoursAndMinutes //time.getSeconds()
                                      ? minutes*60 + hours*60*60 + days*24*60*60
                                      : seconds + minutes*60

    canAccept: daysField.acceptableInput && allSeconds > 0

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader { id: header }

            TextField {
                id: daysField
                visible: hoursAndMinutes
                label: qsTr("Days", "Duration picker")
                text: days
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { id: daysValidator; bottom: 0 }
                onTextChanged:
                    if (acceptableInput)
                        days = Number(text)
            }

            TimePicker {
                id: picker
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    horizontalCenter: parent.horizontalCenter
                }

                hourMode: DateTime.TwentyFourHours

                Column {
                    anchors.centerIn: parent
                    width: childrenRect.width

                    Row {
                        width: childrenRect.width

                        Label {
                            id: hoursMinutesLabel
                            font.pixelSize: Theme.fontSizeHuge
                            text: (hoursAndMinutes ? hours : minutes).toLocaleString()
                        }
                        Label {
                            anchors.bottom: hoursMinutesLabel.bottom
                            color: Theme.secondaryColor
                            text: hoursAndMinutes ? qsTr("h", "Duration picker hours") : qsTr("min", "Duration picker minutes")
                        }
                    }

                    Row {
                        width: childrenRect.width

                        Label {
                            id: minutesSecondsLabel
                            font.pixelSize: Theme.fontSizeHuge
                            text: (hoursAndMinutes ? minutes : seconds).toLocaleString()
                        }
                        Label {
                            anchors.bottom: minutesSecondsLabel.bottom
                            color: Theme.secondaryColor
                            text: hoursAndMinutes ? qsTr("min", "Duration picker minutes") : qsTr("s", "Duration picker seconds")
                        }
                    }
                }
            }

            ComboBox {
                label: qsTr("Units", "Duration picker units")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Hours and minutes", "Duration picker units")
                    }
                    MenuItem {
                        text: qsTr("Minutes and seconds", "Duration picker units")
                    }
                }
                onCurrentIndexChanged:
                    mode = currentIndex
            }
        }
    }
}
