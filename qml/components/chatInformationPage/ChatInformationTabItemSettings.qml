//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

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
                active: isSupergroup && isGroupCreator && !isChannel && !groupInformation.has_linked_chat
                sourceComponent: Component {
                    Column {
                        width: parent.width
                        SectionHeader {
                            text: qsTr("Topics", "group topics")
                        }
                        ComboBox {
                            id: forumComboBox
                            label: qsTr("Enable Topics", "group topics")
                            description: qsTr("The group chat will be divided into topics created by admins or users.")
                                         + (groupInformation.is_forum ? ' ' + qsTr("Choose how topics appear for all members.") : '')

                            menu: ContextMenu {
                                MenuItem {
                                    text: qsTr("Off", "topics")
                                    onClicked: if (forumComboBox.currentIndex != 0)
                                                   tdLibWrapper.toggleSupergroupIsForum(groupInformation.id, false)
                                }
                                MenuItem {
                                    text: qsTr("List", "topics")
                                    onClicked: if (forumComboBox.currentIndex != 1)
                                                   tdLibWrapper.toggleSupergroupIsForum(groupInformation.id, true, false)
                                }
                                MenuItem {
                                    text: qsTr("Tabs", "topics")
                                    onClicked: if (forumComboBox.currentIndex != 2)
                                                   tdLibWrapper.toggleSupergroupIsForum(groupInformation.id, true, true)
                                }
                            }
                            currentIndex: groupInformation.is_forum ? (groupInformation.has_forum_tabs ? 2 : 1) : 0
                            automaticSelection: false
                        }
                    }
                }
            }

            Loader {
                width: parent.width
                active: chatInformationPage.isSupergroup && chatInformationPage.groupInformation
                        && (chatInformationPage.groupInformation.status.can_restrict_members
                            || chatInformationPage.isGroupCreator)
                asynchronous: true
                source: Qt.resolvedUrl("./EditSuperGroupSlowModeColumn.qml")
            }
        }
    }
}
