//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

Item {

    id: backgroundProgressIndicator

    property bool withPercentage : false;
    property bool small : false;
    property int progress;

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    width: small ? parent.width / 2 : parent.width
    height: small ? parent.height / 2 : parent.height

    Behavior on opacity { NumberAnimation {} }
    visible: progress < 100
    opacity: progress < 100 ? 1 : 0
    ProgressCircle {
        id: imageProgressCircle
        width: withPercentage ? parent.height / 2 : parent.height
        height: withPercentage ? parent.height / 2 : parent.height
        value: backgroundProgressIndicator.progress / 100
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

    }
    Text {
        id: imageProgressText
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: withPercentage ? qsTr("%1 \%").arg(backgroundProgressIndicator.progress) : qsTr("%1").arg(backgroundProgressIndicator.progress)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        visible: backgroundProgressIndicator.progress < 100 ? true : false
    }

}
