//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

Page {
    id: page

    property var chatId
    property var notificationSettings

    readonly property string soundId: (notificationSettings.use_default_sound ? scopeSettings : notificationSettings).sound_id
    property var sound
    readonly property string storySoundId: (notificationSettings.use_default_story_sound ? scopeSettings : notificationSettings).story_sound_id
    property var storySound

    property int scope: tdLibWrapper.getChatNotificationSettingsScope(chatId)
    property var scopeSettings: tdLibWrapper.scopeNotificationSettings(scope)

    function updateSound() {
        if (soundId != '0' && soundId != '-1')
            tdLibWrapper.getSavedNotificationSound(soundId)
        else
            sound = null

        if (storySoundId != '0' && storySoundId != '-1')
            tdLibWrapper.getSavedNotificationSound(storySoundId)
        else
            storySound = null
    }
    Component.onCompleted: updateSound()
    onSoundIdChanged: updateSound()

    Connections {
        target: tdLibWrapper
        onNotificationSoundReceived: {
            if (soundId === page.soundId)
                page.sound = sound
            if (soundId === page.storySoundId)
                page.storySound = sound
        }
        onSavedNotificationSoundErrorReceived: {
            if (soundId === page.soundId)
                page.sound = null
            if (soundId === page.storySoundId)
                page.storySound = null
        }
        onScopeNotificationSettingsChanged:
            if (scope == page.scope)
                page.scopeSettings = tdLibWrapper.scopeNotificationSettings(scope)
    }

    function applySetting(field, defaultField, value) {
        var newSettings = JSON.parse(JSON.stringify(notificationSettings))
        if (scopeSettings[field] === value)
            newSettings[defaultField] = true
        else {
            newSettings[defaultField] = false
            newSettings[field] = value
        }
        tdLibWrapper.setChatNotificationSettings(chatId, newSettings)
    }

    Component {
        id: notificationSwitchComponent
        TextSwitch {
            text: modelData.text
            description: modelData.description || ''
            property string field: modelData.field
            property bool inverted: !!modelData.inverted

            checked: {
                var chosen = (notificationSettings['use_default_'+field] ? scopeSettings : notificationSettings)[field]
                return inverted ? !chosen : chosen
            }
            automaticCheck: false
            onClicked: {
                busy = true
                applySetting(field, 'use_default_'+field, inverted ? checked : !checked)
            }
            onCheckedChanged: busy = false
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Notifications", "Page header") }

            ValueButton {
                label: qsTr("Sound")
                value: sound ? sound.title : (soundId == '0' ? qsTr("Disabled", "No notification sound") : qsTr("Default", "Default notification sound"))
                onClicked: pageStack.push(selectSoundPageComponent)
            }

            Loader {
                width: parent.width
                property var modelData: ({text: qsTr("Message Preview"), field: 'show_preview'})
                sourceComponent: notificationSwitchComponent
            }

            SectionHeader { text: qsTr("Events") }

            Repeater {
                model: [
                    {text: qsTr("Pinned Messages"), field: 'disable_pinned_message_notifications', inverted: true},
                    {text: qsTr("Mentions"), field: 'disable_mention_notifications', inverted: true}
                ]

                delegate: notificationSwitchComponent
            }

            SectionHeader { text: qsTr("Stories") }

            Loader {
                id: storySwitchLoader
                width: parent.width
                property var modelData: ({text: qsTr("Story notifications"), field: 'mute_stories', inverted: true})
                sourceComponent: notificationSwitchComponent
            }

            ValueButton {
                visible: storySwitchLoader.item && storySwitchLoader.item.checked
                label: qsTr("Sound")
                value: storySound ? storySound.title : (storySoundId == '0' ? qsTr("Disabled", "No notification sound") : qsTr("Default", "Default notification sound"))
                onClicked: pageStack.push(selectStorySoundPageComponent)
            }

            Loader {
                width: parent.width
                active: storySwitchLoader.item && storySwitchLoader.item.checked
                property var modelData: ({text: qsTr("Show Sender's Name"), field: 'show_story_poster'})
                sourceComponent: notificationSwitchComponent
            }

            Column {
                width: parent.width
                visible: DebugLog.enabled

                SectionHeader { text: "Debug" }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    text: "Notification settings:\n" + JSON.stringify(notificationSettings, null, 2) + "\n\nScope notification settings:\n" + JSON.stringify(scopeSettings, null, 2)
                }
            }
        }
    }

    Component {
        id: selectSoundPageComponent
        NotificationSoundSelectionPage {
            currentSoundUnavailable: !sound
            currentSoundId: soundId

            onSelected:
                applySetting('sound_id', 'use_default_sound', soundId)
        }
    }


    Component {
        id: selectStorySoundPageComponent
        NotificationSoundSelectionPage {
            currentSoundUnavailable: !storySound
            currentSoundId: storySoundId

            onSelected:
                applySetting('story_sound_id', 'use_default_story_sound', soundId)
        }
    }
}
