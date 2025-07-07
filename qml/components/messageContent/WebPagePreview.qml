/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import ".."
import "../../js/functions.js" as Functions

Item {
    id: webPagePreviewItem

    property var linkPreviewData
    property bool largerFontSize
    property bool highlighted
    readonly property int fontSize: largerFontSize ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall

    implicitHeight: linkPreviewData.show_large_media
            ? infoColumn.height + mediaItem.height + mediaItem.anchors.topMargin + mediaItem.anchors.bottomMargin
            : Math.max(infoColumn.height, mediaItem.height + mediaItem.anchors.topMargin + mediaItem.anchors.bottomMargin)

    function clicked() {
        descriptionText.toggleMaxLineCount()
    }

    Column {
        id: infoColumn
        spacing: Theme.paddingSmall
        width: linkPreviewData.show_large_media ? parent.width : parent.width - (mediaItem.width + mediaItem.anchors.leftMargin + mediaItem.anchors.rightMargin)
        visible: !!visibleChildren.length

        MultilineEmojiLabel {
            id: siteNameText

            width: parent.width
            rawText: linkPreviewData.site_name || ""
            font.pixelSize: webPagePreviewItem.fontSize
            font.bold: true
            color: Theme.secondaryHighlightColor
            visible: !!rawText
            maxLineCount: 1
        }

        MultilineEmojiLabel {
            id: titleText

            width: parent.width
            rawText: linkPreviewData.title || ""
            font.pixelSize: webPagePreviewItem.fontSize
            font.bold: true
            maxLineCount: 2
        }

        MultilineEmojiLabel {
            id: descriptionText

            width: parent.width
            rawText: linkPreviewData.description ? Functions.enhanceMessageText(linkPreviewData.description) : ""
            font.pixelSize: webPagePreviewItem.fontSize
            readonly property int defaultMaxLineCount: 3
            maxLineCount: defaultMaxLineCount
            linkColor: Theme.highlightColor
            onLinkActivated: Functions.handleLink(link)
            function toggleMaxLineCount() {
                maxLineCount = maxLineCount > 0 ? 0 : defaultMaxLineCount
            }
        }
    }

    MouseArea {
        anchors.fill: infoColumn
        onClicked: Functions.handleLink(linkPreviewData.url)
    }

    Loader {
        id: mediaItem
        width: !sourceComponent ? 0 : linkPreviewData.show_large_media ? parent.width : Theme.iconSizeLarge
        height: !sourceComponent ? 0 : linkPreviewData.show_large_media ? width * 2 / 3 : width
        anchors {
            top: sourceComponent && linkPreviewData.show_large_media ? infoColumn.bottom : undefined
            left: !sourceComponent || linkPreviewData.show_large_media ? undefined : infoColumn.right
            topMargin: !sourceComponent ? undefined : (Theme.paddingSmall + linkPreviewData.show_large_media ? Theme.paddingMedium : 0)
            leftMargin: !sourceComponent ? undefined : (Theme.paddingSmall + linkPreviewData.show_large_media ? 0 : Theme.paddingMedium)
            margins: sourceComponent ? Theme.paddingSmall : 0
        }

        readonly property bool highlighted: parent.highlighted

        sourceComponent:
            switch(linkPreviewData.type['@type']) {
            case 'linkPreviewTypePhoto':
            case 'linkPreviewTypeApp':
            case 'linkPreviewTypeArticle':
            case 'linkPreviewTypeWebApp':

            // chatPhoto (compatible with photo):
            case 'linkPreviewTypeChat':
            case 'linkPreviewTypeUser':
            case 'linkPreviewTypeChannelBoost':
            case 'linkPreviewTypeSupergroupBoost':
                return photoComponent

            case 'linkPreviewTypeEmbeddedAudioPlayer':
            case 'linkPreviewTypeEmbeddedAnimationPlayer':
            case 'linkPreviewTypeEmbeddedVideoPlayer':
                return embeddedPlayerComponent

            case 'linkPreviewTypeVideo':
                return linkPreviewData.type.cover ? videoCoverComponent
                                                  : (linkPreviewData.type.video.thumbnail || linkPreviewData.type.video.minithumbnail
                                                     ? videoThumbnailComponent : undefined)

            case 'linkPreviewTypeSticker':
            case 'linkPreviewTypeStickerSet': // not really compatible
                return stickerComponent

            default: return undefined
            }

        Component {
            id: photoComponent
            TDLibPhoto {
                anchors.fill: parent
                photo: linkPreviewData.type.photo
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(Qt.resolvedUrl("../../pages/ImagePage.qml"), {photoData: photo})
                }
            }
        }

        Component {
            id: embeddedPlayerComponent
            TDLibPhoto {
                anchors.fill: parent
                photo: linkPreviewData.type.thumbnail
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(Qt.resolvedUrl("../../pages/EmbeddedPlayerPage.qml"), {linkPreviewType: linkPreviewData.type})
                }
            }
        }

        Component {
            id: videoCoverComponent
            TDLibPhoto {
                anchors.fill: parent
                photo: linkPreviewData.type.cover
                // TODO: open video on click
            }
        }
        Component {
            id: videoThumbnailComponent
            TDLibThumbnail {
                width: parent.width //don't use anchors here for easier custom scaling
                height: parent.height
                highlighted: parent.highlighted
                thumbnail: linkPreviewData.type.video.thumbnail
                minithumbnail: linkPreviewData.type.video.minithumbnail

                // TODO: open video on click
            }
        }

        Component {
            id: stickerComponent
            TDLibSticker {
                stickerData: linkPreviewData.type['@type'] === 'linkPreviewTypeStickerSet' ? linkPreviewData.type.stickers[0] : linkPreviewData.type.sticker
                width: Math.min(implicitWidth, parent.width)
                height: Math.min(implicitHeight, parent.height)
                anchors.centerIn: parent
            }
        }
    }

    Label {
        width: parent.width
        text: qsTr("Preview not supported for this link...")
        font.pixelSize: webPagePreviewItem.largerFontSize ? Theme.fontSizeExtraSmall : Theme.fontSizeTiny
        font.italic: true
        color: Theme.secondaryColor
        truncationMode: TruncationMode.Fade
        visible: !infoColumn.visible && !mediaItem.visible
    }

}
