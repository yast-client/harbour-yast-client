//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property alias header: header
    property url largeIcon
    property string title
    property alias description: descriptionLabel.text
    property alias descriptionLabel: descriptionLabel
    property var cards: []

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
        clip: contentY > 0

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            Icon {
                source: dialog.largeIcon
                width: Theme.iconSizeExtraLarge
                height: Theme.iconSizeExtraLarge
                sourceSize: Qt.size(Theme.iconSizeExtraLarge, Theme.iconSizeExtraLarge)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            InfoLabel {
                text: dialog.title
                color: palette.highlightColor
            }

            Label {
                id: descriptionLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: palette.secondaryHighlightColor
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                spacing: Theme.paddingLarge

                Repeater {
                    model: dialog.cards

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
                                color: palette.secondaryColor
                                linkColor: palette.secondaryHighlightColor
                                onLinkActivated: Qt.openUrlExternally(link)
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
