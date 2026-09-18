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

            AnimatedLoader {
                width: parent.width
                show: (chatInformationPage.isBasicGroup || chatInformationPage.isSupergroup)
                        && !chatInformationPage.isChannel && chatInformationPage.groupInformation
                        && (chatInformationPage.groupInformation.status.can_restrict_members || chatInformationPage.isGroupCreator)
                asynchronous: true
                source: Qt.resolvedUrl("EditGroupChatPermissionsColumn.qml")
            }

            AnimatedLoader {
                width: parent.width
                show: chatInformationPage.isSupergroup && !chatInformation.hasActiveUsername && !isChannel && !groupInformation.has_linked_chat
                        && (groupInformation.status.can_change_info || isGroupCreator)
                sourceComponent: Component {
                    Column {
                        width: parent.width
                        SectionHeader {
                            text: qsTr("New Members", "what can new group members do")
                        }
                        TextSwitch {
                            text: qsTr("New members can see older messages", "member permission")
                            checked: groupFullInformation.is_all_history_available
                            automaticCheck: false
                            onClicked: {
                                busy = true
                                tdLibWrapper.toggleSupergroupIsAllHistoryAvailable(chatUserOrGroupId, !checked)
                            }
                            onCheckedChanged: busy = false
                        }
                    }
                }
            }

            AnimatedLoader {
                id: convertToBroadcastGroupLoader
                width: parent.width
                show: chatManager.conversionToBroadcastGroupSuggested
                sourceComponent: Component {
                    Column {
                        width: parent.width
                        spacing: Theme.paddingMedium

                        SectionHeader { text: qsTr("Broadcast Group") }
                        Button {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Convert to Broadcast Group")
                            onClicked: {
                                var remorse = Remorse.popupAction(chatInformationPage,
                                    qsTr("Converted to Broadcast Group", "Remorse"), 
                                    function() { tdLibWrapper.toggleSupergroupIsBroadcastGroup(groupInformation.id) },
                                    20000 // Give the user some additional time to think
                                )
                                convertToBroadcastGroupLoader.hidden = Qt.binding(function() { return remorse && remorse.active })
                            }
                        }

                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2*x
                            text: qsTr("Broadcast groups can have over %Ln member(s), but only admins can send messages in them. Members who are not admins will %1permanently%2 lose their right to send messages in the group. %3This action cannot be undone.%4", '',
                                            tdData.options.supergroup_size_max).arg('<b>').arg('</b>').arg('<b>').arg('</b>')
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryHighlightColor
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            Loader {
                width: parent.width
                active: isSupergroup && isGroupCreator && !isChannel && !groupInformation.has_linked_chat && !groupInformation.is_broadcast_group
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

                            // FIXME?
                            property int comboBoxIndex: groupInformation.is_forum ? (groupInformation.has_forum_tabs ? 2 : 1) : 0
                            currentIndex: comboBoxIndex
                            onComboBoxIndexChanged: currentIndex = comboBoxIndex
                            automaticSelection: false
                        }
                    }
                }
            }

            AnimatedLoader {
                width: parent.width
                show: chatInformationPage.isSupergroup && chatInformationPage.groupInformation
                        && (chatInformationPage.groupInformation.status.can_restrict_members
                            || chatInformationPage.isGroupCreator)
                asynchronous: true
                source: Qt.resolvedUrl("EditSuperGroupSlowModeColumn.qml")
            }
        }
    }
}
