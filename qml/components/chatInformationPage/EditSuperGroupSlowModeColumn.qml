//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0


Column {
    SectionHeader {
        text: qsTr("Slow Mode")
    }

    Slider {
        width: parent.width + Theme.horizontalPageMargin * 2
        x: -Theme.horizontalPageMargin
        property var presetValues: [0, 10, 30, 60, 300, 900, 3600]
        property int realValue: chatInformationPage.groupFullInformation.slow_mode_delay
        property int realValueIndex: presetValues.indexOf(realValue) > -1 ? presetValues.indexOf(realValue) : 0
        value: realValueIndex
        minimumValue: 0
        maximumValue: presetValues.length - 1
        stepSize: 1
        valueText: value === 0 ? qsTr("Off") : Format.formatDuration(presetValues[value], presetValues[value] < 3600 ? Formatter.DurationShort : Formatter.DurationLong);
        onPressedChanged: {
            if(!pressed && value !== realValueIndex) {
                tdLibWrapper.setChatSlowModeDelay(chatInformationPage.chatInformation.id, presetValues[value]);
            }
        }
    }
    Label {
        text: qsTr("Set how long every chat member has to wait between Messages")
        width: parent.width - Theme.horizontalPageMargin * 2
        x: Theme.horizontalPageMargin
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.secondaryHighlightColor
        wrapMode: Text.Wrap
    }
}
