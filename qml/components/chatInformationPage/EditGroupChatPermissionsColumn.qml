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


Column {
    id: chatPermissionsColumn

    property var mediaPermissions: [
        'can_send_photos',
        'can_send_videos',
        'can_send_video_notes',
        'can_send_audios',
        'can_send_voice_notes',
        'can_send_documents',
        'can_send_other_messages',
        'can_send_polls',
        'can_add_link_previews',
    ]

    Component {
        id: permissionSwitch
        TextSwitch {
            automaticCheck: false
            readonly property string permission: modelData[0]
            text: modelData[1]
            checked: chatInformationPage.chatInformation.permissions[permission]
            onCheckedChanged: busy = false
            onClicked: {
                if(busy) return
                var value = !checked
                busy = true
                var newPermissions = JSON.parse(JSON.stringify(chatInformationPage.chatInformation.permissions))
                if (permission in newPermissions) {
                    newPermissions[permission] = value
                    // some permissions infer can_send_messages:
                    if(permission === "can_send_messages" && !value) {
                        for(var i in mediaPermissions)
                            newPermissions[mediaPermissions[i]] = false
                    } else if(mediaPermissions.indexOf(permission) > -1 && value)
                        newPermissions.can_send_messages = true
                }
                tdLibWrapper.setChatPermissions(chatInformationPage.chatInformation.id, newPermissions)
            }
        }
    }

    Column {
        visible: chatInformationPage.groupInformation.status.can_restrict_members || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator"
        width: parent.width

        SectionHeader {
            text: qsTr("Permissions", "What can members of this group do")
        }

        Loader {
            width: parent.width
            readonly property var modelData: ['can_send_basic_messages', qsTr("Send messages", "member permission")]
            sourceComponent: permissionSwitch
        }

        TextSwitch {
            text: qsTr("Send media", "member permission")
            automaticCheck: false
            checked: mediaPermissions.some(function(permission) { return chatInformationPage.chatInformation.permissions[permission] })
            onCheckedChanged: busy = false
            onClicked: {
                if (busy) return
                busy = true

                var permissions = JSON.parse(JSON.stringify(chatInformationPage.chatInformation.permissions))

                if (checked)
                    mediaPermissions.forEach(function(permission) { permissions[permission] = false })
                else {
                    mediaPermissions.forEach(function(permission) { permissions[permission] = true })
                    permissions.can_send_messages = true
                }

                tdLibWrapper.setChatPermissions(chatInformationPage.chatInformation.id, permissions)
            }
        }

        Column {
            x: Theme.horizontalPageMargin // TextSwitch.rightMargin is still there (equal to same Theme.horizontalPageMargin)
            width: parent.width - x
            Repeater {
                model: [
                    ['can_send_photos', qsTr("Photos", "member permission")],
                    ['can_send_videos', qsTr("Videos", "member permission")],
                    ['can_send_video_notes', qsTr("Video messages", "member permission")],
                    ['can_send_audios', qsTr("Music", "member permission")],
                    ['can_send_voice_notes', qsTr("Voice messages", "member permission")],
                    ['can_send_documents', qsTr("Files", "member permission")],
                    ['can_send_other_messages', qsTr("Stickers & GIFs", "member permission")],
                    ['can_add_link_previews', qsTr("Embed links", "member permission")],
                    ['can_send_polls', qsTr("Polls", "member permission")],
                ]
                delegate: permissionSwitch
            }
        }

        Repeater {
            width: parent.width
            model: [
                ['can_invite_users', qsTr("Add members", "member permission")],
                ['can_pin_messages', qsTr("Pin messages", "member permission")],
                ['can_change_info', qsTr("Change group info", "member permission")],
            ]
            delegate: permissionSwitch
        }

        Loader {
            width: parent.width
            height: active ? implicitHeight : 0
            Behavior on height { NumberAnimation { duration: 200 } }
            active: chatInformationPage.isSuperGroup && !!chatInformationPage.groupInformation.is_forum
            readonly property var modelData: ['can_create_topics', qsTr("Create topics", "member permission")]
            sourceComponent: permissionSwitch
        }
    }

    SectionHeader {
        visible: historyAvailableSwitch.visible
        text: qsTr("New Members", "what can new group members do")
    }


    TextSwitch {
        id: historyAvailableSwitch
        visible: chatInformationPage.isSuperGroup && chatInformationPage.groupInformation.status && chatInformationPage.groupInformation.status.can_change_info
        automaticCheck: false
        text: qsTr("New members can see older messages", "member permission")
        onCheckedChanged: {busy = false;}
        checked: chatInformationPage.groupFullInformation.is_all_history_available
        onClicked: {
            tdLibWrapper.toggleSupergroupIsAllHistoryAvailable(chatInformationPage.chatPartnerGroupId, !checked);
        }
    }
}
