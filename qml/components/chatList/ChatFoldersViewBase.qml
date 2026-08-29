//@ SPDX-FileCopyrightText: 2026 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import Opal.Tabs 1.0

TabView {
    model: chatFoldersModel

    // TODO: currently, we use some terrible hacks
    // to make pulley menu openable when swiping from the header
    // ideally these patches should be improved and upstreamed

    Component.onCompleted: {
        tabBarItem.countRole = Qt.binding(function() { return appSettings.showFolderUnreadCount ? 'count' : '' })
        tabBarItem.iconRole = Qt.binding(function() { return appSettings.chatFoldersTabBarShowIcons ? 'icon' : '' })
    }

    tabIcons {
        sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
        color: Theme.primaryColor
        highlightColor: Theme.highlightColor
    }

    tabBarVisible: count > 1
    tabBarPosition: appSettings.chatFoldersTabBarOnBottom ? Qt.AlignBottom : Qt.AlignTop

    tabComponent: ChatFolderTabBase {}
}
