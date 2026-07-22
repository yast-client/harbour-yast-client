//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Sailfish.WebView 1.0
import io.yaqtlib 1.0
import "../.."
import "../../tdlib"
import "../../../js/twemoji.js" as Emoji
import "../../../js/debug.js" as Debug

InlineQueryResult {
    id: queryResultItem
    property bool loopPreview: true
    property bool mutePreview: true
    sendOnClick: false
    layer.enabled: mouseArea.pressed
    layer.effect: PressEffect { source: queryResultItem }

    property var animation: model.animation // video or animation

    TDLibThumbnail {
        width: parent.width
        height: parent.height

        thumbnail: animation.thumbnail
        minithumbnail: animation.minithumbnail
        fillMode: Image.PreserveAspectCrop
    }

    Column {
        id: textColumn
        anchors {
            left: parent.left
            margins: Theme.paddingSmall
            right: parent.right
            bottom: parent.bottom
        }

        Label {
            id: titleLabel
            width: parent.width
            text: Emoji.emojify(model.title || "", font.pixelSize)
            font.pixelSize: Theme.fontSizeTiny
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: !!text
        }
        Label {
            id: descriptionLabel
            width: parent.width
            text: Emoji.emojify(model.description || "", font.pixelSize)
            font.pixelSize: Theme.fontSizeTiny
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: !!text
        }
    }

    Loader {
        anchors.fill: textColumn
        asynchronous: true
        active: titleLabel.visible || descriptionLabel.visible
        sourceComponent: Component {
            DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: Theme.paddingSmall
                spread: 0.5
                samples: 17
                color: Theme.overlayBackgroundColor
                source: textColumn
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            var dialog = pageStack.push(dialogComponent)
            dialog.accepted.connect(queryResultItem.sendInlineQueryResultMessage)
        }
    }

    Component {
        id: dialogComponent
        Dialog {
            DialogHeader { id: header }

            Loader {
                width: parent.width
                anchors {
                    top: header.bottom
                    bottom: parent.bottom
                }
                asynchronous: true
                sourceComponent: animation.mime_type == 'text/html'
                                ? htmlComponent : videoComponent
            }

            Component {
                id: videoComponent
                TDLibVideo {
                    id: video
                    anchors.fill: parent

                    videoData: animation
                    muted: queryResultItem.mutePreview
                    onStopped:
                        if (loopPreview && status == MediaPlayer.EndOfMedia) play()

                    ProgressCircle {
                        opacity: file.isDownloadingActive ? 1 : 0
                        Behavior on opacity { FadeAnimator {} }
                        anchors.centerIn: parent
                        value: file.isDownloadingCompleted ? 1 : (file.downloadedSize / file.size)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: video.toggle()
                    }
                }
            }

            Component {
                id: htmlComponent
                Column {
                    anchors.fill: parent
                    spacing: Theme.paddingLarge

                    TDLibFile {
                        id: file
                        tdlib: tdLibWrapper
                        autoLoad: false
                        fileInformation: queryResultItem.isAnimation ? animation.animation : animation.video
                    }

                    property url link: file.fileInformation.remote.id

                    Label {
                        id: linkLabel
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        text: '<a href="%1">%1</a>'.arg(link)
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                        linkColor: Theme.highlightColor
                        wrapMode: Text.Wrap
                        onLinkActivated: Qt.openUrlExternally(link)
                    }

                    WebView {
                        id: webView
                        width: parent.width
                        height: parent.height - linkLabel.height - parent.spacing
                        url: link
                    }
                }
            }
        }
    }
}
