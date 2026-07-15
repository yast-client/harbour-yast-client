//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '../pages'
import "../js/functions.js" as Functions

ContextMenu {
    id: menu

    property var chatId
    property var notificationSettings

    MenuItem {
        text: qsTr("Mute forever")
        onClicked: Functions.setChatIsMuted(chatId, notificationSettings, true)
    }

    Repeater {
        model: [1, 8, 24]
        MenuItem {
            text: qsTr("Mute for %Ln hours", '', modelData)
            onClicked: {
                var newNotificationSettings = notificationSettings
                newNotificationSettings.use_default_mute_for = false
                newNotificationSettings.mute_for = modelData * 3600
                tdLibWrapper.setChatNotificationSettings(chatId, newNotificationSettings)
            }
        }
    }

    MenuItem {
        text: qsTr("Mute for…")
        onClicked: {
            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/DurationPickerDialog.qml"), {
                                            title: qsTr("Mute notifications"),
                                            maxDays: 365
                                        })
            dialog.accepted.connect(function() {
                var newNotificationSettings = notificationSettings
                newNotificationSettings.use_default_mute_for = false
                newNotificationSettings.mute_for = Math.min(dialog.allSeconds, 31622400) // Not more than 366 days
                tdLibWrapper.setChatNotificationSettings(chatId, newNotificationSettings)
            })
        }
    }

    MenuItem {
        text: qsTr("Customize")
        onClicked: pageStack.push(customizeNotificationsPageComponent)
        Component {
            id: customizeNotificationsPageComponent
            CustomizeNotificationsPage {
                // Pass as bindings
                chatId: menu.chatId
                notificationSettings: menu.notificationSettings
            }
        }
    }
}
