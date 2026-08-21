//@ SPDX-FileCopyrightText: 2026 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool fromTitleBar

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        PageHeader {
            id: header
            title: qsTr("Search", "page header for search page")

            MouseArea {
                anchors.fill: parent
                enabled: fromTitleBar
                onClicked: pageStack.pop(undefined, PageStackAction.Immediate)
            }
        }

        SearchChatsView {
            anchors.top: header.bottom
            height: parent.height - header.height

            onResetFocus: page.focus = true
        }
    }
}
