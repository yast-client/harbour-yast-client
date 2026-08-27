//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '../pages'
import "../js/functions.js" as Functions

ContextMenu {
    id: menu

    property var chatId
    property int scope
    property var notificationSettings
    property bool muted

    MenuItem {
        visible: !muted
        text: qsTr("Mute forever")
        onClicked:
            if (chatId) Functions.setChatIsMuted(chatId, notificationSettings, true)
            else Functions.setNotificationsScopeIsMuted(scope, notificationSettings, true)
    }

    function muteNotificationsFor(duration) {
        var newNotificationSettings = JSON.parse(JSON.stringify(notificationSettings))
        newNotificationSettings.mute_for = duration
        if (chatId) {
            newNotificationSettings.use_default_mute_for = false
            tdLibWrapper.setChatNotificationSettings(chatId, newNotificationSettings)
        } else
            tdLibWrapper.setScopeNotificationSettings(scope, newNotificationSettings)
    }

    Repeater {
        model: [1, 8, 24]
        MenuItem {
            visible: !muted
            text: qsTr("Mute for %Ln hours", '', modelData)
            onClicked: menu.muteNotificationsFor(modelData * 3600)
        }
    }

    MenuItem {
        visible: !muted
        text: qsTr("Mute for…")
        onClicked: {
            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/DurationPickerDialog.qml"), {
                                            title: qsTr("Mute notifications"),
                                            maxDays: 365
                                        })
            dialog.accepted.connect(function() {
                menu.muteNotificationsFor(Math.min(dialog.allSeconds, 31622400)) // Not more than 366 days
            })
        }
    }

    MenuItem {
        text: qsTr("Customize")
        onClicked: pageStack.push(chatId ? customizeNotificationsPageComponent : customizeScopePageComponent)
        Component {
            id: customizeNotificationsPageComponent
            CustomizeNotificationsPage {
                // Pass as bindings
                chatId: menu.chatId
                notificationSettings: menu.notificationSettings
            }
        }
        Component {
            id: customizeScopePageComponent
            CustomizeNotificationsPage {
                // Pass as bindings
                scope: menu.scope
                scopeSettings: menu.notificationSettings
            }
        }
    }
}
