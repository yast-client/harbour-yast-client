//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

ComboBox {
    label: qsTr("Main profile tab")
    description: qsTr("Choose the tab to appear first in the profile.")

    property string currentType
    property bool isUser
    signal setProfileTab(string type)

    readonly property var tabTypes: ['Posts', 'Gifts', 'Media', 'Files', 'Music', 'Links', 'Voice', 'Gifs']
    property string currentTypeSuffix: currentType.slice(10)

    menu: ContextMenu {
        MenuItem { text: qsTr("Posts") }
        MenuItem { text: qsTr("Gifts") }
        MenuItem { visible: !isUser; text: qsTr("Media") }
        MenuItem { visible: !isUser; text: qsTr("Files") }
        MenuItem { visible: !isUser; text: qsTr("Music") }
        MenuItem { visible: !isUser; text: qsTr("Links") }
        MenuItem { visible: !isUser; text: qsTr("Voice") }
        MenuItem { visible: !isUser; text: qsTr("GIFs") }
    }

    currentIndex: tabTypes.indexOf(currentTypeSuffix)
    onCurrentTypeSuffixChanged: currentIndex = tabTypes.indexOf(currentTypeSuffix)
    onCurrentIndexChanged: {
        if (currentIndex == -1) return
        var type = tabTypes[currentIndex]
        if (type !== currentTypeSuffix) setProfileTab('profileTab' + type)
    }
}
