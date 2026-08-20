//@ SPDX-FileCopyrightText: 2026 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../modules/Opal/Tabs"

TabView {
    model: chatFoldersModel

    // TODO: currently, we use some terrible hacks for making header work,
    // and to make pulley menu openable when swiping from it
    // ideally these patches should be improved and upstreamed

    Component.onCompleted: {
        tabBarItem.countRole = Qt.binding(function() { return appSettings.showFolderUnreadCount ? 'count' : '' })
        tabBarItem.iconRole = Qt.binding(function() { return appSettings.chatFoldersTabBarShowIcons ? 'icon' : '' })

        tabBarItem.iconSize = Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
        tabBarItem.iconColor = Qt.binding(function() { return Theme.primaryColor })
    }

    tabBarVisible: count > 1
    tabBarPosition: appSettings.chatFoldersTabBarOnBottom ? Qt.AlignBottom : Qt.AlignTop

    tabComponent: ChatFolderTabBase {}
}
