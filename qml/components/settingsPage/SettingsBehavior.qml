//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

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
                checked: yaqtSettings.sendMarkdown
                text: qsTr("Parse markdown when sending messages")
                automaticCheck: false
                onClicked: yaqtSettings.sendMarkdown = !checked
            }
        }
    }
}
