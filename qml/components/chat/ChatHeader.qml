//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'

BackgroundItem {
    id: header
    height: visible ? (row.height
                       + (isPortrait
                          ? (Theme.paddingMedium + (Screen.hasCutouts ? Screen.topCutout.height : Theme.paddingMedium))
                          : Theme.paddingSmall * 2)
                       ) : 0

    readonly property bool isPortrait: pageStack.currentPage.isPortrait

    property bool isSecret
    property alias chatNameText: chatNameText
    property alias chatStatusText: chatStatusText
    property alias chatActionIcon: chatActionIcon
    property alias chatBadges: chatBadges
    property alias pictureThumbnail: pictureThumbnail
    property alias textContainer: textContainer
    property alias container: row

    Row {
        id: row
        width: parent.width - (3 * Theme.horizontalPageMargin)
        height: chatNameRow.height + Math.max(chatActionIcon.height, chatStatusText.height)
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: isPortrait ? Theme.paddingMedium : Theme.paddingSmall
        }
        spacing: Theme.paddingMedium

        ProfileThumbnail {
            id: pictureThumbnail
            height: parent.height
            width: height
            anchors.verticalCenter: parent.verticalCenter

            replacementStringHint: chatNameText.text

            Rectangle {
                color: Theme.rgba(Theme.overlayBackgroundColor, Theme.opacityFaint)
                width: isPortrait ? Theme.fontSizeLarge : Theme.fontSizeMedium
                height: width
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                radius: parent.width / 2
                visible: isSecret

                Image {
                    source: "image://theme/icon-s-secure"
                    width: isPortrait ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall
                    height: width
                    anchors.centerIn: parent
                }
            }

        }

        Item {
            id: textContainer
            opacity: visible ? 1 : 0
            Behavior on opacity { FadeAnimator {} }
            width: parent.width - pictureThumbnail.width - Theme.paddingMedium
            height: chatNameRow.height + chatStatusRow.height
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: chatNameRow
                anchors.right: parent.right
                spacing: Theme.paddingMedium

                Label {
                    id: chatNameText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, textContainer.width - chatBadges.width - parent.spacing)
                    textFormat: Text.StyledText
                    font.pixelSize: isPortrait ? Theme.fontSizeLarge : Theme.fontSizeMedium
                    font.family: Theme.fontFamilyHeading
                    color: palette.highlightColor
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                }

                ChatBadges {
                    id: chatBadges
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                id: chatStatusRow
                width: Math.min(chatStatusText.implicitWidth + (chatActionIcon.active ? (chatActionIcon.width + spacing) : 0), parent.width)
                visible: chatActionIcon.active || !!chatStatusText.text
                spacing: Theme.paddingSmall
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }

                ChatActionIcon { id: chatActionIcon }

                Label {
                    id: chatStatusText

                    property bool isError

                    width: parent.width - (chatActionIcon.active ? (chatActionIcon.width + spacing) : 0)
                    textFormat: Text.StyledText
                    font.pixelSize: isPortrait ? Theme.fontSizeExtraSmall : Theme.fontSizeTiny
                    minimumPixelSize: Theme.fontSizeTiny
                    fontSizeMode: Text.Fit
                    font.family: Theme.fontFamilyHeading
                    color: isError ? Theme.errorColor : highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                }
            }
        }
    }
}
