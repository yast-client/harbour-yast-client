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
import QtQml.Models 2.3

import "../"
import "../../pages"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

ChatInformationTabItemBase {
    id: tabBase
    scrollableView: flickable

    SilicaFlickable {
        id: flickable
        height: tabBase.height
        width: tabBase.width
        contentHeight: contentColumn.height
        Column {
            id: contentColumn
            width: tabBase.width

            //permissions

            // if chatManager.permissions.can_change_info
            //  - upload/change chat photo/VIDEO (hahaha)
            //  - description change
            //  - toggleSupergroupIsAllHistoryAvailable
            // if ?????? can_promote_members ???? can_restrict_members
            // - setChatMemberStatus
            // if creator (BasicGroup)
            // - upgradeBasicGroupChatToSupergroupChat
            // if creator (supergroup/channel)
            // - canTransferOwnership?
            //   - transferChatOwnership

            Loader {
                active: (chatInformationPage.isBasicGroup || chatInformationPage.isSupergroup)
                        && !chatInformationPage.isChannel && chatInformationPage.groupInformation

                        && (chatInformationPage.groupInformation.status.can_restrict_members || chatInformationPage.isGroupCreator)
                asynchronous: true
                source: "./EditGroupChatPermissionsColumn.qml"
                width: parent.width
            }

            Loader {
                width: parent.width
                active: chatInformationPage.isSupergroup
                        && (chatInformationPage.groupInformation.status.can_change_info || chatInformationPage.isGroupCreator)
                // todo: only show this for private groups
                sourceComponent: Component {
                    Column {
                        width: parent.width
                        SectionHeader {
                            text: qsTr("New Members", "what can new group members do")
                        }
                        TextSwitch {
                            automaticCheck: false
                            onCheckedChanged: busy = false
                            text: qsTr("New members can see older messages", "member permission")
                            checked: chatInformationPage.groupFullInformation.is_all_history_available
                            onClicked: {
                                busy = true
                                tdLibWrapper.toggleSupergroupIsAllHistoryAvailable(chatInformationPage.chatUserOrGroupId, !checked)
                            }
                        }
                    }
                }
            }

            Loader {
                width: parent.width
                active: chatInformationPage.isSupergroup && chatInformationPage.isGroupCreator
                // todo: only show this for private groups
                sourceComponent: Component {
                    Column {
                        width: parent.width
                        SectionHeader {
                            text: qsTr("Topics", "group topics")
                        }
                        TextSwitch {
                            automaticCheck: false
                            onCheckedChanged: busy = false
                            text: qsTr("Enable Topics", "switch to toggle topics for a group")
                            description: qsTr("The group chat will be divided into topics created by admins or users.")
                            checked: chatInformationPage.groupInformation.is_forum
                            onClicked: {
                                busy = true
                                tdLibWrapper.toggleSupergroupIsForum(chatInformationPage.chatInformation.id, !checked)
                            }
                        }
                    }
                }
            }

            Loader {
                active: chatInformationPage.isSupergroup && chatInformationPage.groupInformation
                        && (chatInformationPage.groupInformation.status.can_restrict_members
                            || chatInformationPage.isGroupCreator)
                asynchronous: true
                source: "./EditSuperGroupSlowModeColumn.qml"
                width: parent.width
            }

        }
    }
}
