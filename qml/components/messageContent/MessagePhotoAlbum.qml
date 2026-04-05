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
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../"

AlbumMessageContentBase {
    id: messageContent
    readonly property int heightUnit: Math.round(width * 0.66666666)
    property bool firstLarge: albumMessages.length % 2 !== 0

    clip: true

    function openDetail(index) {
        pageStack.push(Qt.resolvedUrl("../../pages/MediaAlbumPage.qml"), {
                            chatManager: chatManager,
                            message: albumMessages[index || 0],
                            searchMessagesFilter: TDLibAPI.SearchMessagesFilterPhotoAndVideo
                        })
    }
    onClicked: openDetail(-1)

    Component {
        id: photoPreviewComponent
        MessagePhoto {
            messageListItem: messageContent.messageListItem
            overlayFlickable: messageContent.overlayFlickable
            rawMessage: albumMessages[modelIndex]
            highlighted: _highlighted
        }
    }
    Component {
        id: videoPreviewComponent
        Item {
            property bool highlighted:_highlighted
            anchors.fill: parent
            clip: true
            TDLibThumbnail {
                id: tdLibImage
                width: parent.width //don't use anchors here for easier custom scaling
                height: parent.height
                highlighted: parent.highlighted
                thumbnail: albumMessages[modelIndex].content.video.thumbnail
                minithumbnail: albumMessages[modelIndex].content.video.minithumbnail
            }
            Rectangle {
                anchors {
                    fill: videoIcon
                    leftMargin: -Theme.paddingSmall
                    topMargin: -Theme.paddingSmall
                    bottomMargin: -Theme.paddingSmall
                    rightMargin: -Theme.paddingLarge

                }

                radius: Theme.paddingSmall
                color: Theme.rgba(Theme.overlayBackgroundColor, 0.4)

            }

            Icon {
                id: videoIcon
                source: "image://theme/icon-m-video"
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                highlighted: parent.highlighted
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                    bottom: parent.bottom
                }
            }
        }
    }

    Flow {
        id: contentGrid
        property int firstWidth: firstLarge ? width : normalWidth
        property int firstHeight: firstLarge ? heightUnit - spacing : normalHeight
        property int normalWidth: (width - spacing) / 2
        property int normalHeight: (heightUnit / 2) - spacing

        anchors.fill: parent
        spacing: Theme.paddingMedium

        Repeater {
            model: albumMessages
            delegate: BackgroundItem {
                id: mediaBackgroundItem
                property bool isLarge: firstLarge && model.index === 0
                width: model.index === 0 ? contentGrid.firstWidth : contentGrid.normalWidth
                height: model.index === 0 ? contentGrid.firstHeight : contentGrid.normalHeight

                readonly property bool isSelected: messageListItem.precalculatedValues.pageIsSelecting && page.selectedMessages.some(function(existingMessage) {
                    return existingMessage.id === albumMessages[index].id
                });
                highlighted: isSelected || down || messageContent.highlighted
                onClicked: {
                    if(messageListItem.precalculatedValues.pageIsSelecting) {
                        page.toggleMessageSelection(albumMessages[index]);
                        return;
                    }

                    openDetail(index);
                }
                onPressAndHold: {
                    page.toggleMessageSelection(albumMessages[index]);
                }

                Loader {
                    anchors.fill: parent
                    readonly property int modelIndex: index
                    property bool _highlighted: mediaBackgroundItem.highlighted
                    sourceComponent: albumMessages[index].content["@type"] === 'messageVideo' ? videoPreviewComponent : photoPreviewComponent
                    opacity: status === Loader.Ready
                    Behavior on opacity { FadeAnimator {} }
                }

                Rectangle {
                    visible: mediaBackgroundItem.isSelected
                    anchors {
                        fill: parent
                    }
                    color: 'transparent'
                    border.color: Theme.highlightColor
                    border.width: Theme.paddingSmall
                }
            }
        }
    }
}
