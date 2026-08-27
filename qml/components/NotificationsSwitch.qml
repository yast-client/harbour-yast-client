//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../js/functions.js" as Functions

ListItem {
    id: listItem
    contentHeight: textSwitch.height

    highlighted: textSwitch.down || menuOpen
    _backgroundColor: 'transparent'
    openMenuOnPressAndHold: false

    property var chatId
    property var settings
    property var scope: tdData.getChatNotificationSettingsScope(chatId)
    property var scopeSettings: tdData.scopeNotificationSettings(scope)
    property int muteFor: (!settings || settings.use_default_mute_for ? scopeSettings : settings).mute_for

    Connections {
        target: tdData
        onScopeNotificationSettingsChanged:
            if (scope === listItem.scope)
                scopeSettings = tdData.scopeNotificationSettings(scope)
    }

    property alias text: textSwitch.text
    property alias icon: textSwitch.icon

    IconTextSwitch {
        id: textSwitch
        text: qsTr("Notifications")
        highlighted: listItem.highlighted

        description: qsTr("%1, press and hold for more options").arg(muteFor > 0
                        ? (muteFor > 31622400
                        ? qsTr("Muted") : qsTr("Muted for %1").arg(Format.formatDuration(muteFor)))
                        : qsTr("Unmuted"))
        icon.source: 'image://theme/icon-m-' + (muteFor ? 'silent' : 'sounds')

        checked: muteFor == 0
        automaticCheck: false

        onClicked: {
            busy = true
            if (chatId) Functions.toggleChatIsMuted(chatId, settings)
            else Functions.toggleNotificationsScopeIsMuted(scope, scopeSettings)
        }
        onCheckedChanged: busy = false
        onPressAndHold: listItem.openMenu()
    }

    menu: Component {
        NotificationsContextMenu {
            chatId: listItem.chatId
            scope: listItem.scope
            notificationSettings: chatId ? listItem.settings : listItem.scopeSettings
            muted: listItem.muteFor > 0
        }
    }
}
