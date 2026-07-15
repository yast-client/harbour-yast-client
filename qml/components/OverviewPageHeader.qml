//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

PageHeader {
    id: pageHeader

    property alias statusItem: pageStatus
    property string defaultTitle: qsTr("YAST Client")

    title: tdLibWrapper.connectionStateText || defaultTitle
    leftMargin: Theme.itemSizeMedium

    GlassItem {
        id: pageStatus
        width: Theme.itemSizeMedium
        height: Theme.itemSizeMedium
        color: "red"
        falloffRadius: 0.1
        radius: 0.2
        cache: false
        anchors.bottom: parent.bottom
    }

    states: [
        State {
            name: "WaitingForNetwork"
            when: tdLibWrapper.connectionState == TDLibAPI.WaitingForNetwork
            PropertyChanges { target: pageStatus; color: "red" }
        },
        State {
            name: "Connecting"
            when: tdLibWrapper.connectionState == TDLibAPI.Connecting
            PropertyChanges { target: pageStatus; color: "gold" }
        },
        State {
            name: "ConnectingToProxy"
            when: tdLibWrapper.connectionState == TDLibAPI.ConnectingToProxy
            PropertyChanges { target: pageStatus; color: "gold" }
        },
        State {
            name: "ConnectionReady"
            when: tdLibWrapper.connectionState == TDLibAPI.ConnectionReady
            PropertyChanges { target: pageStatus; color: "green" }
        },
        State {
            name: "Updating"
            when: tdLibWrapper.connectionState == TDLibAPI.Updating
            PropertyChanges { target: pageStatus; color: "lightblue" }
        }
    ]
}
