//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property bool keepUnmutedChatsArchivedEnabled

    onAccepted: appConfig.archiveChatListHintCompleted = true

    Item {
        anchors.fill: parent

        DialogHeader {
            id: header
            acceptText: qsTr("Got it")
        }

        SilicaFlickable {
            width: parent.width
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }
            contentHeight: column.height

            Column {
                id: column
                width: parent.width
                spacing: Theme.paddingLarge

                Icon {
                    source: Qt.resolvedUrl("../../images/icon-l-history.svg")
                    width: Theme.iconSizeExtraLarge
                    height: Theme.iconSizeExtraLarge
                    sourceSize: Qt.size(Theme.iconSizeExtraLarge, Theme.iconSizeExtraLarge)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                InfoLabel {
                    text: qsTr("This is your Archive")
                    color: Theme.highlightColor
                }

                Label {
                    text: (keepUnmutedChatsArchivedEnabled
                          ? qsTr("Archived chats will remain in the Archive when you receive a new message. %1Tap to change%2")
                          : qsTr("When you receive a new message, muted chats will remain in the Archive, while unmuted chats will be moved to Chats. %1Tap to change%2"))
                        .arg('<a href="#" style="text-decoration:none;color:%1">'.arg(Theme.highlightColor)).arg('</a>')
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.secondaryHighlightColor
                    textFormat: Text.RichText
                    onLinkActivated: {
                        appConfig.archiveChatListHintCompleted = true
                        pageStack.replace(Qt.resolvedUrl("../pages/SettingsPage.qml"), {initialArea: 'archive'})
                    }
                }

                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    spacing: Theme.paddingLarge

                    Repeater {
                        model: [
                            {icon: 'image://theme/icon-m-history', title: qsTr("Archived Chats"), description: qsTr("Move any chat into your Archive and back using the context menu.")},
                        ]
                        Component.onCompleted: {
                            // unused for now, but reserved for translations
                            [{icon: 'image://theme/icon-m-camera', title: qsTr("Stories"), description: qsTr("Archive Stories from your contacts separately from chats with them.")}]
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.paddingMedium

                            Icon {
                                id: archiveIcon
                                source: modelData.icon
                            }

                            Column {
                                width: parent.width - archiveIcon.width - parent.spacing
                                spacing: Theme.paddingMedium
                                Label {
                                    text: modelData.title
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    font.pixelSize: Theme.fontSizeMedium
                                }
                                Label {
                                    text: modelData.description
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondaryColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
