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
import App.Logic 1.0
import "../../modules/Opal/Tabs"

TabView {
    id: tabView
    width: parent.width
    height: Screen.width

    opacity: count > 0 ? 1.0 : 0.0
    Behavior on height { PropertyAnimation { duration: 300 } }
    Behavior on opacity { PropertyAnimation { duration: 300 } }

    wrapMode: PagedView.NoWrap

    // Use a custom model to make it easy to add tabs dynamically
    model: ListModel {}

    tabComponent: Component {
        Loader {
            id: tabLoader

            // FIXME: this could probably be done in a better way by patching Opal.Tabs
            property real _yOffset: item && item._yOffset || 0
            opacity: 0

            sourceComponent:
                switch (tabModel.tabData.filter) {
                case TDLibAPI.SearchMessagesFilterDocument:
                    return filesComponent
                default:
                    return mediaGridComponent
                }

            Component {
                id: mediaGridComponent
                ChatInformationTabItemMediaGrid {
                    model:
                        switch (tabModel.tabData.filter) {
                        case TDLibAPI.SearchMessagesFilterPhotoAndVideo:
                            return photoAndVideoModel
                        case TDLibAPI.SearchMessagesFilterAnimation:
                            return animationModel
                        case TDLibAPI.SearchMessagesFilterVideoNote:
                            return videoNoteModel
                        }

                    focus: tabLoader.focus
                    opacity: tabLoader.opacity
                }
            }
            Component {
                id: filesComponent
                ChatInformationTabItemFiles {
                    model: filesModel
                    focus: tabLoader.focus
                    opacity: tabLoader.opacity
                }
            }
        }
    }

    Binding {
        target: tabView.tabBarItem
        property: 'iconColor'
        value: Theme.primaryColor
    }

    function insertTab(name, title, icon, data) {
        var insertIndex = 0
        var tabOrder = [
                    'MembersGroups',
                    'Media',
                    'Files',
                    'Gifs',
                    'VideoNotes',
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

        var tab = {
            name: name,
            title: title,
            icon: icon,
            source: '',
            tabData: {filter: -1}
        }
        if (data)
            tab.tabData = data
        else
            tab.source = Qt.resolvedUrl('ChatInformationTabItem' + name + '.qml')

        model.insert(insertIndex, tab)

        return insertIndex
    }

    function removeTab(name) {
        for (var i=0; i < model.count; i++)
            if (model.get(i).name == name)
                model.remove(i)
    }

    InvertedMediaMessagesModel {
        id: photoAndVideoModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterPhotoAndVideo
        onNotEmptyDetected: {
            var i = insertTab('Media', qsTr("Media", "Button: Chat media (photos and videos)"), 'image://theme/icon-m-image', {filter: TDLibAPI.SearchMessagesFilterPhotoAndVideo})
            //if (i > -1) tabView.currentIndex = i
        }
    }

    InvertedMediaMessagesModel {
        id: animationModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterAnimation
        onNotEmptyDetected: insertTab('Gifs', qsTr("GIFs", "Button: Chat GIFs"), 'image://theme/icon-m-image', {filter: TDLibAPI.SearchMessagesFilterAnimation})
    }

    InvertedMediaMessagesModel {
        id: videoNoteModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterVideoNote
        onNotEmptyDetected: insertTab('VideoNotes', qsTr("Video Messages", "Button: Chat video messages"), 'image://theme/icon-m-file-video', {filter: TDLibAPI.SearchMessagesFilterVideoNote})
    }

    InvertedMediaMessagesModel {
        id: filesModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterDocument
        onNotEmptyDetected: insertTab('Files', qsTr("Files", "Button: Chat files"), 'image://theme/icon-m-file-document', {filter: TDLibAPI.SearchMessagesFilterDocument})
    }

    // FIXME: this works for now (required because groupFullInformation is not yet initialized when Component.onCompleted is called), but this is too clunky
    function insertMembersGroupsTab() {
        var i = insertTab('MembersGroups',
                  chatInformationPage.isPrivateOrSecretChat ? qsTr("Groups", "Button: groups in common (short)") : qsTr("Members", "Button: Group Members"),
                  'image://theme/icon-m-people')
        if (i > -1)
            currentIndex = i
    }
    property bool showMembersGroupsTab: !isSavedMessages && (isPrivateOrSecretChat || groupFullInformation.can_get_members)
    onShowMembersGroupsTabChanged:
        if (showMembersGroupsTab)
            insertMembersGroupsTab()
        else removeTab('MembersGroups')


    Component.onCompleted: {
        if(showMembersGroupsTab)
            insertMembersGroupsTab()

        if(isGroup && (groupInformation.status.can_restrict_members || isGroupCreator))
            insertTab('Settings', qsTr("Settings", "Button: Chat Settings"), 'image://theme/icon-m-developer-mode')

        if (DebugLog.enabled)
            insertTab('Debug', "Debug", 'image://theme/icon-m-diagnostic')

        photoAndVideoModel.init(chatManager.chatId)
        animationModel.init(chatManager.chatId)
        videoNoteModel.init(chatManager.chatId)
        filesModel.init(chatManager.chatId)
    }
}
