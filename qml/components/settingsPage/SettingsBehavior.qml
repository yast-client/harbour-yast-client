/*
    Copyright (C) 2021 Sebastian J. Wolf and other contributors

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
import io.yaqtlib 1.0

AccordionItem {
    name: "behavior"
    title: qsTr("Behavior")
    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium
            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.sendByEnter
                text: qsTr("Send message by enter")
                description: qsTr("Send your message by pressing the enter key")
                automaticCheck: false
                onClicked: appSettings.sendByEnter = !checked
            }

            TextSwitch {
                enabled: appSettings.sendByEnter
                width: parent.columnWidth
                checked: appSettings.sendAttachmentByEnter
                text: qsTr("Send attachments by enter")
                automaticCheck: false
                onClicked: appSettings.sendAttachmentByEnter = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.focusTextAreaOnChatOpen
                text: qsTr("Focus text input on chat open")
                description: qsTr("Focus the text input area when entering a chat")
                automaticCheck: false
                onClicked: {
                    appSettings.focusTextAreaOnChatOpen = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.focusTextAreaAfterSend
                text: qsTr("Focus text input area after send")
                description: qsTr("Focus the text input area after sending a message")
                automaticCheck: false
                onClicked: {
                    appSettings.focusTextAreaAfterSend = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.delayMessageRead
                text: qsTr("Delay before marking messages as read")
                description: qsTr("There will be a slight delay before the messages will be read")
                automaticCheck: false
                onClicked: {
                    appSettings.delayMessageRead = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.highlightUnreadConversations
                text: qsTr("Highlight unread messages")
                description: qsTr("Highlight Conversations with unread messages")
                automaticCheck: false
                onClicked: {
                    appSettings.highlightUnreadConversations = !checked
                }
            }

            Column {
                width: parent.columnWidth

                ComboBox {
                    id: feedbackComboBox
                    label: qsTr("Notification feedback")
                    description: qsTr("Use non-graphical feedback (sound, vibration) for notifications")
                    menu: ContextMenu {
                        id: feedbackMenu
                        x: 0
                        width: feedbackComboBox.width

                        MenuItem {
                            readonly property int value: FernieSettings.NotificationFeedbackAll
                            text: qsTr("All events")
                            onClicked: {
                                fernieSettings.notificationFeedback = value
                            }
                        }
                        MenuItem {
                            readonly property int value: FernieSettings.NotificationFeedbackNew
                            text: qsTr("Only new events")
                            onClicked: {
                                fernieSettings.notificationFeedback = value
                            }
                        }
                        MenuItem {
                            readonly property int value: FernieSettings.NotificationFeedbackNone
                            text: qsTr("None")
                            onClicked: {
                                fernieSettings.notificationFeedback = value
                            }
                        }
                    }

                    Component.onCompleted: updateFeedbackSelection()

                    function updateFeedbackSelection() {
                        var menuItems = feedbackMenu.children
                        var n = menuItems.length
                        for (var i=0; i<n; i++) {
                            if (menuItems[i].value === fernieSettings.notificationFeedback) {
                                currentIndex = i
                                return
                            }
                        }
                    }

                    Connections {
                        target: fernieSettings
                        onNotificationFeedbackChanged: {
                            feedbackComboBox.updateFeedbackSelection()
                        }
                    }
                }

                Column {
                    enabled: fernieSettings.notificationFeedback !== FernieSettings.NotificationFeedbackNone
                    width: parent.width
                    height: enabled ? implicitHeight: 0
                    clip: height < implicitHeight
                    visible: height > 0

                    Behavior on height { SmoothedAnimation { duration: 200 } }

                    TextSwitch {
                        checked: fernieSettings.notificationTurnsDisplayOn && enabled
                        text: qsTr("Notification turns on the display")
                        enabled: parent.enabled
                        automaticCheck: false
                        onClicked: {
                            fernieSettings.notificationTurnsDisplayOn = !checked
                        }
                    }

                    TextSwitch {
                        checked: fernieSettings.notificationSoundsEnabled && enabled
                        text: qsTr("Enable notification sounds")
                        description: qsTr("When sounds are enabled, the current Sailfish OS notification sound will be used for chats, which can be configured in the system settings.")
                        enabled: parent.enabled
                        automaticCheck: false
                        onClicked: {
                            fernieSettings.notificationSoundsEnabled = !checked
                        }
                    }
                }

                TextSwitch {
                    checked: fernieSettings.notificationSuppressContent && enabled
                    text: qsTr("Hide content in notifications")
                    automaticCheck: false
                    onClicked: fernieSettings.notificationSuppressContent = !checked
                }

                TextSwitch {
                    checked: fernieSettings.notificationShowDefaultReaction && enabled
                    text: qsTr("Setting quick reaction from notifications")
                    automaticCheck: false
                    onClicked: fernieSettings.notificationShowDefaultReaction = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: fernieSettings.unreadCountIncludeMuted
                text: qsTr("Include muted chats in unread count")
                automaticCheck: false
                onClicked: fernieSettings.unreadCountIncludeMuted = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: fernieSettings.showFolderUnreadCount
                text: qsTr("Show unread chat count in folders")
                automaticCheck: false
                onClicked: fernieSettings.showFolderUnreadCount = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                enabled: fernieSettings.showFolderUnreadCount
                checked: fernieSettings.foldersUnreadCountIncludeMuted
                text: qsTr("Include muted chats in folders unread count")
                automaticCheck: false
                onClicked: fernieSettings.foldersUnreadCountIncludeMuted = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.showTranslateOption
                text: qsTr("Show translate option for messages")
                //description: qsTr("For messages and ...")
                automaticCheck: false
                onClicked: appSettings.showTranslateOption = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: fernieSettings.sendMarkdown
                text: qsTr("Parse markdown when sending messages")
                automaticCheck: false
                onClicked: fernieSettings.sendMarkdown = !checked
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
