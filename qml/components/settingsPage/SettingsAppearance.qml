//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

AccordionItem {
    name: "appearance"
    title: qsTr("Appearance")
    clip: heightBehavior.enabled || heightAnimation.running

    // One-shot behavior
    Behavior on height {
        id: heightBehavior
        enabled: false
        SequentialAnimation {
            id: heightAnimation
            SmoothedAnimation { duration: 200 }
            ScriptAction { script: heightBehavior.enabled = false }
        }
    }

    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.compactChatList
                text: qsTr("Compact chat list")
                description: qsTr("Make chats in the list smaller")
                automaticCheck: false
                onClicked: appSettings.compactChatList = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.chatFoldersTabBarOnBottom
                text: qsTr("Move chat folders panel to bottom")
                automaticCheck: false
                onClicked: appSettings.chatFoldersTabBarOnBottom = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.chatFoldersTabBarShowIcons
                text: qsTr("Show chat folders icons")
                automaticCheck: false
                onClicked: appSettings.chatFoldersTabBarShowIcons = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.showStickersAsEmojis
                text: qsTr("Show stickers as emojis")
                description: qsTr("Only display emojis instead of the actual stickers")
                automaticCheck: false
                onClicked: {
                    heightBehavior.enabled = true
                    appSettings.showStickersAsEmojis = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.showStickersAsImages
                text: qsTr("Show stickers as images")
                description: qsTr("Show background for stickers and align them centrally like images")
                automaticCheck: false
                onClicked: {
                    appSettings.showStickersAsImages = !checked
                }
                visible: !appSettings.showStickersAsEmojis
                opacity: visible ? 1 : 0
                Behavior on opacity { FadeAnimation  { } }
            }

            Item {
                // Placeholder to move the next switch to the second column
                visible: parent.columns === 2
                width: 1
                height: 1
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.animateStickers
                text: qsTr("Animate stickers")
                automaticCheck: false
                onClicked: {
                    appSettings.animateStickers = !checked
                }
                visible: !appSettings.showStickersAsEmojis
                opacity: visible ? 1 : 0
                Behavior on opacity { FadeAnimation {} }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.videoStickers
                visible: !appSettings.showStickersAsEmojis
                opacity: visible ? 1 : 0
                Behavior on opacity { FadeAnimation {} }
                text: qsTr("Video stickers")
                //description: qsTr("Animated stickers option doesn't affect this")
                automaticCheck: false
                onClicked: appSettings.videoStickers = !checked
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.downscaleAnimatedStickers
                visible: !appSettings.showStickersAsEmojis && appSettings.animateStickers
                opacity: visible ? 1 : 0
                Behavior on opacity { FadeAnimation {} }
                text: qsTr("Downscale animated stickers")
                description: qsTr("May improve performance on low-end devices")
                automaticCheck: false
                onClicked: appSettings.downscaleAnimatedStickers = !checked
            }
        }
    }
}
