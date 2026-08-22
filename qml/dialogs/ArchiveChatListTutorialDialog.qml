//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

FullscreenHintDialog {
    property bool keepUnmutedChatsArchivedEnabled

    largeIcon: Qt.resolvedUrl("../../images/icon-l-history.svg")
    title: qsTr("This is your Archive")
    description: (keepUnmutedChatsArchivedEnabled
                          ? qsTr("Archived chats will remain in the Archive when you receive a new message. %1Tap to change%2")
                          : qsTr("When you receive a new message, muted chats will remain in the Archive, while unmuted chats will be moved to Chats. %1Tap to change%2"))
                        .arg('<a href="#" style="text-decoration:none;color:%1">'.arg(palette.highlightColor)).arg('</a>')
    descriptionLabel {
        textFormat: Text.RichText
        onLinkActivated: {
            hintsConfig.archiveChatListHintCompleted = true
            pageStack.replace(Qt.resolvedUrl("../pages/SettingsPage.qml"), {initialArea: 'archive'})
        }
    }
    cards: [
        {icon: 'image://theme/icon-m-history', title: qsTr("Archived Chats"), description: qsTr("Move any chat into your Archive and back using the context menu.")},
    ]
    Component.onCompleted: {
        // unused for now, but reserved for translations
        [{icon: 'image://theme/icon-m-camera', title: qsTr("Stories"), description: qsTr("Archive Stories from your contacts separately from chats with them.")}]
    }

    onAccepted: hintsConfig.archiveChatListHintCompleted = true
}
