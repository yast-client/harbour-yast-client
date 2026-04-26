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
import App.Logic 1.0

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
                description: qsTr("Ferniegram will wait a bit before messages are marked as read")
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

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.goToQuotedMessage
                text: qsTr("Go to quoted message")
                description: qsTr("When tapping a quoted message, open it in chat instead of showing it in an overlay.")
                automaticCheck: false
                onClicked: {
                    appSettings.goToQuotedMessage = !checked
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

            Item {
                // Occupies one grid cell so that the column ends up under the combo box
                // in the landscape layout
                visible: parent.columns === 2
                width: 1
                height: 1
            }

            Column {
                enabled: fernieSettings.notificationFeedback !== FernieSettings.NotificationFeedbackNone
                width: parent.columnWidth
                height: enabled ? implicitHeight: 0
                clip: height < implicitHeight
                visible: height > 0

                Behavior on height { SmoothedAnimation { duration: 200 } }

                TextSwitch {
                    checked: fernieSettings.notificationSuppressContent && enabled
                    text: qsTr("Hide content in notifications")
                    enabled: parent.enabled
                    automaticCheck: false
                    onClicked: {
                        fernieSettings.notificationSuppressContent = !checked
                    }
                }

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
                    description: qsTr("When sounds are enabled, Ferniegram will use the current Sailfish OS notification sound for chats, which can be configured in the system settings.")
                    enabled: parent.enabled
                    automaticCheck: false
                    onClicked: {
                        fernieSettings.notificationSoundsEnabled = !checked
                    }
                }
            }

            TextSwitch {
                checked: fernieSettings.unreadCountIncludeMuted
                text: qsTr("Include muted chats in unread count")
                automaticCheck: false
                onClicked: fernieSettings.unreadCountIncludeMuted = !checked
            }

            TextSwitch {
                checked: fernieSettings.showFolderUnreadCount
                text: qsTr("Show unread chat count in folders")
                automaticCheck: false
                onClicked: fernieSettings.showFolderUnreadCount = !checked
            }

            TextSwitch {
                enabled: fernieSettings.showFolderUnreadCount
                checked: fernieSettings.foldersUnreadCountIncludeMuted
                text: qsTr("Include muted chats in folders unread count")
                automaticCheck: false
                onClicked: fernieSettings.foldersUnreadCountIncludeMuted = !checked
            }

            /*Slider {
                width: parent.width
                label: qsTr("Voice note volume")
                minimumValue: 1
                maximumValue: 15.0
                stepSize: 1
                value: appSettings.voiceNoteVolume
                valueText: value
                onValueChanged: appSettings.voiceNoteVolume = sliderValue
            }*/

            TextField {
                width: parent.columnWidth
                label: qsTr("Voice messages volume")
                validator: RegExpValidator { regExp: /^((?:\d|[1-9]\d+)(?:\.\d+)?)$/ }
                text: appSettings.voiceNoteVolume
                onTextChanged: if (acceptableInput) appSettings.voiceNoteVolume = text
                onAcceptableInputChanged: if (acceptableInput) appSettings.voiceNoteVolume = text
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
                checked: appSettings.formattedTranslate
                text: qsTr("Translate formatted text")
                description: qsTr("Without Telegram Premium")
                automaticCheck: false
                onClicked: appSettings.formattedTranslate = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: fernieSettings.sendMarkdown
                text: qsTr("Parse markdown in messages")
                automaticCheck: false
                onClicked: fernieSettings.sendMarkdown = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.forceQtAudioRecorder
                text: qsTr("Force QtMultimedia-based audio recorder")
                automaticCheck: false
                onClicked: appSettings.forceQtAudioRecorder = !checked
                visible: NO_HARBOUR_COMPLIANCE
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.forceAllowAISummary
                text: qsTr("Forcefully allow AI summary")
                automaticCheck: false
                onClicked: appSettings.forceAllowAISummary = !checked
            }
        }
    }
}
