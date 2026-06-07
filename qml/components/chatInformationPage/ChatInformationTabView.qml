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
import io.libfernie 1.0
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
                case TDLibAPI.SearchMessagesFilterAudio:
                    return audiosComponent
                case TDLibAPI.SearchMessagesFilterVoiceNote:
                    return voiceNotesComponent
                case TDLibAPI.SearchMessagesFilterUrl:
                    return linksComponent
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
            Component {
                id: audiosComponent
                ChatInformationTabItemAudios {
                    model: audiosModel
                    focus: tabLoader.focus
                    opacity: tabLoader.opacity
                }
            }
            Component {
                id: voiceNotesComponent
                ChatInformationTabItemVoiceNotes {
                    model: voiceNotesModel
                    focus: tabLoader.focus
                    opacity: tabLoader.opacity
                }
            }
            Component {
                id: linksComponent
                ChatInformationTabItemLinks {
                    model: linksModel
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
                    'Members',
                    'Media',
                    'Files',
                    'Audios',
                    'Links',
                    'VoiceNotes',
                    'Gifs',
                    'VideoNotes',
                    'GroupsInCommon',
                    'Settings',
                    'SimilarBots',
                    'SimilarChats',
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
            if (model.get(i).name === name)
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

    InvertedMediaMessagesModel {
        id: audiosModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterAudio
        onNotEmptyDetected: insertTab('Audios', qsTr("Audio", "Button: Chat audio files"), 'image://theme/icon-m-file-audio', {filter: TDLibAPI.SearchMessagesFilterAudio})
    }

    InvertedMediaMessagesModel {
        id: voiceNotesModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterVoiceNote
        onNotEmptyDetected: insertTab('VoiceNotes', qsTr("Voice messages", "Button: Chat voice messages"), 'image://theme/icon-m-browser-microphone', {filter: TDLibAPI.SearchMessagesFilterVoiceNote})
    }

    InvertedMediaMessagesModel {
        id: linksModel
        tdlib: tdLibWrapper
        filter: TDLibAPI.SearchMessagesFilterUrl
        onNotEmptyDetected: insertTab('Links', qsTr("Links", "Button: Chat shared links"), 'image://theme/icon-m-link', {filter: TDLibAPI.SearchMessagesFilterUrl})
    }

    // FIXME: this works for now (required because groupFullInformation is not yet initialized when Component.onCompleted is called), but this is too clunky
    function insertMembersTab() {
        var i = insertTab('Members',
                          (chatInformationPage.isChannel ? qsTr("Subscribers", "Button: channel subscribers") : qsTr("Members", "Button: Group Members")),
                          'image://theme/icon-m-people')
        if (i > -1)
            currentIndex = i
    }
    // if is a basic group and has no members (same for supergroups), still show the tab
    property bool showMembersTab: isBasicGroup ? groupFullInformation.members : canGetMembers
    onShowMembersTabChanged:
        if (showMembersTab)
            insertMembersTab()
        else removeTab('Members')

    Connections {
        id: groupsInCommonConnections
        target: tdLibWrapper
        ignoreUnknownSignals: true
        onChatsReceived:
            if (extra === "getGroupsInCommon:"+chatUserOrGroupId) {
                handleGroupsInCommon(chatIds, totalCount)
                if (groupsInCommonList.count > 0) {
                    insertTab('GroupsInCommon', qsTr("Groups", "Button: groups in common (short)"), 'image://theme/icon-m-people')
                    groupsInCommonConnections.target = null
                }
            }
    }


    property var chatSimilarChats
    property int chatSimilarChatsCount
    property var botSimilarBots
    property var botSimilarBotsCount

    Connections {
        target: tdLibWrapper
        onChatsReceived:
            if (isChannel && extra === "getChatSimilarChats:"+chatInformation.id && totalCount > 0) {
                chatSimilarChats = chatIds
                chatSimilarChatsCount = totalCount
                // TODO: once we'll have a proper channel icon, put it here
                insertTab('SimilarChats', qsTr("Similar channels", "Profile tab"), 'image://theme/icon-m-speaker')
            }
        onUsersReceived:
            if (isPrivateOrSecretChat && extra === "getBotSimilarBots:"+chatUserOrGroupId && totalCount > 0) {
                botSimilarBots = userIds
                botSimilarBotsCount = totalCount
                // TODO: once we'll have a proper bot icon, put it here
                insertTab('SimilarBots', qsTr("Similar bots", "Profile tab"), 'image://theme/icon-m-contact')
            }
    }

    Component.onCompleted: {
        if (showMembersTab)
            insertMembersTab()

        if (!isSavedMessages && isPrivateOrSecretChat)
            // check if the tab needs to be added
            tdLibWrapper.getGroupsInCommon(chatUserOrGroupId, 50)

        if (isGroup && (groupInformation.status.can_restrict_members || isGroupCreator))
            insertTab('Settings', qsTr("Settings", "Button: Chat Settings"), 'image://theme/icon-m-developer-mode')

        if (DebugLog.enabled)
            insertTab('Debug', "Debug", 'image://theme/icon-m-diagnostic')

        if (isChannel)
            tdLibWrapper.getChatSimilarChats(chatInformation.id)
        if (isPrivateOrSecretChat && privateChatUserInformation.type['@type'] === 'userTypeBot')
            tdLibWrapper.getBotSimilarBots(chatUserOrGroupId)

        photoAndVideoModel.init(chatManager.chatId)
        filesModel.init(chatManager.chatId)
        audiosModel.init(chatManager.chatId)
        linksModel.init(chatManager.chatId)
        voiceNotesModel.init(chatManager.chatId)
        animationModel.init(chatManager.chatId)
        videoNoteModel.init(chatManager.chatId)
    }
}
