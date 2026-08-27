//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import ".."

AccordionItem {
    name: 'notifications'
    title: qsTr("Notifications and sounds")

    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium

            Component.onCompleted: {
                // Fetch up-to-date values from the server
                tdLibWrapper.getScopeNotificationSettings()
                tdLibWrapper.fetchOption('disable_contact_registered_notifications')
            }

            Column {
                width: parent.columnWidth

                SectionHeader { text: qsTr("Chat notifications") }

                NotificationsSwitch {
                    id: privateSwitch
                    scope: TDLibAPI.NotificationSettingsScopePrivateChats
                    text: qsTr("Private chats")
                    icon.source: 'image://theme/icon-m-contact'
                }
                NotificationsSwitch {
                    id: groupsSwitch
                    scope: TDLibAPI.NotificationSettingsScopeGroupChats
                    text: qsTr("Groups")
                    icon.source: 'image://theme/icon-m-users'
                }
                NotificationsSwitch {
                    id: channelsSwitch
                    scope: TDLibAPI.NotificationSettingsScopeChannelChats
                    text: qsTr("Channels")
                    icon.source: Qt.resolvedUrl('../../../images/folders/icon-m-folder-channels.svg')
                    icon.sourceSize {
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                    }
                }
            }

            Column {
                width: parent.columnWidth

                SectionHeader { text: qsTr("Events") }

                TextSwitch {
                    text: qsTr("Contact joined Telegram")
                    checked: !tdData.options.disable_contact_registered_notifications
                    automaticCheck: false
                    onClicked: {
                        busy = true
                        tdData.options.disable_contact_registered_notifications = checked
                    }
                    onCheckedChanged: busy = false
                }

                TextSwitch {
                    text: qsTr("Pinned Messages")
                    checked: [privateSwitch, groupsSwitch, channelsSwitch].every(function (textSwitch) {
                        return !textSwitch.scopeSettings.disable_pinned_message_notifications
                    })
                    automaticCheck: false
                    onClicked: {
                        busy = true
                        for (var scope = 0; scope <= 2; scope++) {
                            var settings = tdData.scopeNotificationSettings(scope)
                            settings.disable_pinned_message_notifications = checked
                            tdLibWrapper.setScopeNotificationSettings(scope, settings)
                        }
                    }
                    onCheckedChanged: busy = false
                }
            }

            ComboBox {
                id: feedbackComboBox
                width: parent.columnWidth
                label: qsTr("Notification feedback")
                description: qsTr("Use non-graphical feedback (sound, vibration) for notifications")
                menu: ContextMenu {
                    id: feedbackMenu
                    x: 0
                    width: feedbackComboBox.width

                    MenuItem {
                        readonly property int value: YaqtSettings.NotificationFeedbackAll
                        text: qsTr("All events")
                        onClicked: yaqtSettings.notificationFeedback = value
                    }
                    MenuItem {
                        readonly property int value: YaqtSettings.NotificationFeedbackNew
                        text: qsTr("Only new events")
                        onClicked: yaqtSettings.notificationFeedback = value
                    }
                    MenuItem {
                        readonly property int value: YaqtSettings.NotificationFeedbackNone
                        text: qsTr("None")
                        onClicked: yaqtSettings.notificationFeedback = value
                    }
                }

                Component.onCompleted: updateFeedbackSelection()

                function updateFeedbackSelection() {
                    var menuItems = feedbackMenu.children
                    var n = menuItems.length
                    for (var i=0; i<n; i++) {
                        if (menuItems[i].value === yaqtSettings.notificationFeedback) {
                            currentIndex = i
                            return
                        }
                    }
                }

                Connections {
                    target: yaqtSettings
                    onNotificationFeedbackChanged: feedbackComboBox.updateFeedbackSelection()
                }
            }

            Column {
                enabled: yaqtSettings.notificationFeedback !== YaqtSettings.NotificationFeedbackNone
                width: parent.columnWidth
                height: enabled ? implicitHeight: 0
                clip: height < implicitHeight
                visible: height > 0

                Behavior on height { SmoothedAnimation { duration: 200 } }

                TextSwitch {
                    checked: yaqtSettings.notificationTurnsDisplayOn && enabled
                    text: qsTr("Notification turns on the display")
                    enabled: parent.enabled
                    automaticCheck: false
                    onClicked: yaqtSettings.notificationTurnsDisplayOn = !checked
                }

                TextSwitch {
                    checked: yaqtSettings.notificationSoundsEnabled && enabled
                    text: qsTr("Enable notification sounds")
                    description: qsTr("When sounds are enabled, the current Sailfish OS notification sound will be used for chats, which can be configured in the system settings.")
                    enabled: parent.enabled
                    automaticCheck: false
                    onClicked: yaqtSettings.notificationSoundsEnabled = !checked
                }
            }

            TextSwitch {
                text: qsTr("Hide content in notifications")
                automaticCheck: false
                checked: yaqtSettings.notificationSuppressContent
                onClicked: yaqtSettings.notificationSuppressContent = !checked
            }

            TextSwitch {
                text: qsTr("Setting quick reaction from notifications")
                automaticCheck: false
                checked: yaqtSettings.notificationShowDefaultReaction
                onClicked: yaqtSettings.notificationShowDefaultReaction = !checked
            }

            TextSwitch {
                text: qsTr("In-chat sounds")
                description: qsTr("Play sounds for incoming and outgoing messages when a chat is open")
                automaticCheck: false
                checked: yaqtSettings.inChatNgf
                onClicked: yaqtSettings.inChatNgf = !checked
            }

            Column {
                width: parent.columnWidth

                SectionHeader { text: qsTr("Badge counter") }

                TextSwitch {
                    width: parent.columnWidth
                    checked: yaqtSettings.unreadCountIncludeMuted
                    text: qsTr("Include muted chats in unread count")
                    automaticCheck: false
                    onClicked: yaqtSettings.unreadCountIncludeMuted = !checked
                }

                TextSwitch {
                    width: parent.columnWidth
                    checked: appSettings.showFolderUnreadCount
                    text: qsTr("Show unread chat count in folders")
                    automaticCheck: false
                    onClicked: appSettings.showFolderUnreadCount = !checked
                }

                TextSwitch {
                    width: parent.columnWidth
                    enabled: appSettings.showFolderUnreadCount
                    checked: yaqtSettings.foldersUnreadCountIncludeMuted
                    text: qsTr("Include muted chats in folders unread count")
                    automaticCheck: false
                    onClicked: yaqtSettings.foldersUnreadCountIncludeMuted = !checked
                }
            }

            Column {
                width: parent.columnWidth
                visible: NO_HARBOUR_COMPLIANCE

                SectionHeader { text: qsTr("Calls") }

                TextSwitch {
                    text: qsTr("Ringtone for incoming calls in Do not disturb mode")
                    description: qsTr("Allow incoming calls to play ringtones in 'Do not disturb' mode")
                    checked: appSettings.dnbCallRingtone
                }
            }
        }
    }
}
