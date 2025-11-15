/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

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
import "./"
import "../"
import "../../pages"
import WerkWolf.Fernschreiber 1.0
import "../../modules/Opal/Tabs"

TabView {
    id: tabView
    width: parent.width
    height: Screen.width

    opacity: count > 0 ? 1.0 : 0.0
    Behavior on height { PropertyAnimation { duration: 300 } }
    Behavior on opacity { PropertyAnimation { duration: 300 } }

    wrapMode: PagedView.NoWrap

    // Use a custom model to make it easy to add tabs dynamically with model.append()
    model: ListModel {}

    function insertTab(name, title, icon) {
        var insertIndex = 0
        var tabOrder = [
                    'MembersGroups',
                    'Settings',
                    'Debug'
                ]
        var targetOrderIndex = tabOrder.indexOf(name)
        for (var j = model.count - 1; j >= 0; j--) {
            var n = model.get(j).name
            if (n === name) return -1

            if (tabOrder.indexOf(n) < targetOrderIndex) {
                insertIndex = j + 1
                break
            }
        }

        model.insert(insertIndex, {
            name: name,
            source: Qt.resolvedUrl('ChatInformationTabItem' + name + '.qml'),
            title: title,
            icon: icon
        })

        return insertIndex
    }

    Component.onCompleted: {
        //tabView.tabBarItem.iconColor = Qt.binding(function() { return Theme.primaryColor })

        if(!isSavedMessages && (isPrivateOrSecretChat || groupFullInformation.can_get_members))
            insertTab('MembersGroups',
                      chatInformationPage.isPrivateOrSecretChat ? qsTr("Groups", "Button: groups in common (short)") : qsTr("Members", "Button: Group Members"),
                      'image://theme/icon-m-people')

        if(isGroup && (groupInformation.status.can_restrict_members || isGroupCreator))
            insertTab('Settings', qsTr("Settings", "Button: Chat Settings"), 'image://theme/icon-m-developer-mode')

        if (DebugLog.enabled)
            insertTab('Debug', "Debug", 'image://theme/icon-m-diagnostic')
        
        // TODO: bring back media tabs
    }
}
