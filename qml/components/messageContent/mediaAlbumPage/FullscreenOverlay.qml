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
import "../../../js/functions.js" as Functions
import "../../../js/twemoji.js" as Emoji
import "../.."


Item {
    id: overlay

    property int currentIndex
    property alias text: captionLabel.text
    property bool active: true
    property var message
    property bool hidePreview
    property var previewModel
    readonly property color gradientColor: '#bb000000'
    readonly property int gradientPadding: Theme.itemSizeMedium

    signal jumpedToIndex(int index)

    anchors.fill: parent
    opacity: active ? 1 : 0
    Behavior on opacity { FadeAnimator {} }

    function forwardMessage() {
        var neededPermissions = Functions.getMessagesNeededForwardPermissions([message]);
        pageStack.push(Qt.resolvedUrl("../../../pages/ChatSelectionPage.qml"), {
            myUserId: tdLibWrapper.getUserInformation().id,
            headerDescription: qsTr("Forward %Ln messages", "dialog header", 1),
            payload: {fromChatId: message.chat_id, messageIds:[message.id], neededPermissions: neededPermissions},
            state: "forwardMessages"
        });
    }

    // "header"

    LinearGradient {
        id: topGradient
        property int startY: 0;
//        Behavior on startY { NumberAnimation {duration: 2000} }
        start: Qt.point(0, Math.min(height-gradientPadding*2, startY))
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: closeButton.bottom

            bottomMargin: -gradientPadding
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: gradientColor }
            GradientStop { position: 1.0; color: 'transparent' }
        }
    }


    IconButton {
        id: closeButton
         icon.source: "image://theme/icon-m-cancel?" + (pressed
                      ? Theme.highlightColor
                      : Theme.lightPrimaryColor)
         onClicked: pageStack.pop()
         anchors {
             right: parent.right
             top: parent.top
             margins: Theme.horizontalPageMargin
         }
     }

    SilicaFlickable {
        id: captionFlickable
        anchors {
            left: parent.left
//            leftMargin: Theme.horizontalPageMargin
            right: closeButton.left
            top: parent.top
//            topMargin: Theme.horizontalPageMargin
        }
        interactive: captionLabel.expanded && contentHeight > height
        clip: true
        height: Math.min(contentHeight, parent.height / 4)
        contentHeight: captionLabel.height + Theme.horizontalPageMargin
        flickableDirection: Flickable.VerticalFlick
        VerticalScrollDecorator {
            opacity: visible ? 1.0 : 0.0
            flickable: captionFlickable
        }

        Label {
            id: captionLabel
            property bool expandable: expanded || height < contentHeight
            property bool expanded

            height: text ?
                        expanded
                            ? contentHeight
                            : Theme.itemSizeMedium
                      : 0;
    //        maximumLineCount: expanded ? 0 : 3
            color: Theme.primaryColor
//            text: model.modelData.content.caption.text
            linkColor: Theme.highlightColor
            text: Emoji.emojify(Functions.enhanceMessageText(message.content.caption, false), Theme.fontSizeExtraSmall)
            onTextChanged: expanded = false
            font.pixelSize: Theme.fontSizeExtraSmall
            wrapMode: Text.Wrap
            bottomPadding: expanded ? Theme.paddingLarge : 0
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.paddingLarge
                right: parent.right
                top: parent.top
                topMargin: (!!Screen.hasCutouts && pageStack.currentPage.orientation === Orientation.Portrait) ? Screen.topCutout.height : Theme.horizontalPageMargin
            }

            Behavior on height { NumberAnimation {duration: 300} }
            Behavior on text {
                SequentialAnimation {
                    FadeAnimation {
                        target: captionLabel
                        to: 0.0
                        duration: 300
                    }
                    PropertyAction {}
                    FadeAnimation {
                        target: captionLabel
                        to: 1.0
                        duration: 300
                    }
                }
            }

        }

        OpacityRampEffect {
                        sourceItem: captionLabel
                        enabled: !captionLabel.expanded
                        direction: OpacityRamp.TopToBottom
                    }
        MouseArea {
            anchors.fill: captionLabel
            enabled: captionLabel.expandable
            onClicked: {
                captionLabel.expanded = !captionLabel.expanded
            }
        }
    }

    // "footer"
    LinearGradient {
        anchors {
            left: parent.left
            right: parent.right
            top: buttons.top
            bottom: parent.bottom
            topMargin: -gradientPadding
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: 'transparent' }
            GradientStop { position: 1.0; color: gradientColor }
        }
    }
    Loader {
        id: previewsLoader
        asynchronous: true
        active: !!previewModel && previewModel.count > 1
        height: hidePreview ? 0 : Theme.itemSizeExtraSmall
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: hidePreview ? 0 : Theme.paddingSmall
        }

        sourceComponent: Component {
            Row {
                height: Theme.itemSizeExtraSmall
                spacing: Theme.paddingMedium

                Repeater {
                    model: previewModel

                    Loader {
                        id: singlePreviewLoader

                        readonly property bool current: message.id === message_id
                        readonly property bool isVideo: content_type === 'messageVideo'
                        readonly property var minithumbnail: (isVideo ? (display.content.cover || display.content.video) : display.content.photo).minithumbnail

                        height: parent.height
                        width: current ? height : (height / 2)

                        Behavior on width { NumberAnimation { duration: 150 } }

                        sourceComponent: isVideo && !display.content.cover ? thumbnailComponent : photoComponent

                        Component {
                            id: thumbnailComponent
                            TDLibThumbnail {
                                anchors.fill: parent
                                thumbnail: display.content.video.thumbnail
                                minithumbnail: singlePreviewLoader.minithumbnail
                                highlighted: singlePreviewMouseArea.containsPress
                            }
                        }

                        Component {
                            id: photoComponent
                            TDLibPhoto {
                                fileInformation: utilities.findSmallestPhotoSize((isVideo ? display.content.cover : display.content.photo).sizes).photo || {}
                                minithumbnail: singlePreviewLoader.minithumbnail
                                highlighted: singlePreviewMouseArea.containsPress
                            }
                        }

                        MouseArea {
                            id: singlePreviewMouseArea
                            anchors.fill: parent
                            onClicked: jumpedToIndex(previewModel.mapToSource(index))
                        }
                    }
                }
            }
        }
    }


    TDLibFile {
        id: file
        autoLoad: false
        tdlib: tdLibWrapper
        readonly property bool isPhoto: message.content['@type'] === 'messagePhoto'
        property var videoData: isPhoto ? null : message.content['@type'] === "messageVideo"
                                          ? message.content.video
                                          : (
                                                message.content['@type'] === "messageAnimation"
                                                ? message.content.animation
                                                : message.content.video_note)

        fileInformation: {
            if(isPhoto) {
                return utilities.findBiggestPhotoSize(message.content.photo.sizes).photo || {}
            }
            return videoData[message.content['@type'] === 'messageVideoNote' ? "video" : videoData['@type']]
        }
        // Progress is already displayed on play button
    }

    MessagePropertiesLoader {
        id: propertiesLoader
        message: overlay.message
    }

    Row {
        id: buttons
        height: Theme.itemSizeSmall
        width: childrenRect.width
        spacing:  Theme.paddingLarge
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: previewsLoader.top
            bottomMargin: Theme.paddingSmall
        }

        IconButton {
            icon.source: (file.isDownloadingActive
                       ? "image://theme/icon-m-cancel"
                       : "image://theme/icon-m-downloads")
                      + "?"
                      + (
                          pressed
                          ? Theme.highlightColor
                          : Theme.lightPrimaryColor
                          )
            onClicked: {
                if(file.isDownloadingCompleted)
                    tdLibWrapper.copyFileToDownloads(file.path, false) // TODO: don't open after downloading and show a button for this instead
                else if(!file.isDownloadingActive) file.load()
                else file.cancel()
            }
        }
        Item {
            width: Theme.itemSizeSmall
            height: Theme.itemSizeSmall
        }

        IconButton {
            enabled: propertiesLoader.properties.can_be_forwarded
            opacity: enabled ? 1.0 : 0.2
            icon.source: "image://theme/icon-m-share?" + (pressed
                      ? Theme.highlightColor
                      : Theme.lightPrimaryColor)
            onClicked: forwardMessage()
        }
    }

    states: [
        State {
            name: 'hasCaption'
            when: captionLabel.height > 0
            PropertyChanges { target: topGradient;
                startY: captionFlickable.height
            }
            AnchorChanges {
                target: topGradient
                anchors.bottom: captionFlickable.bottom
            }
        }
    ]
    transitions:
        Transition {
            AnchorAnimation { duration: 200 }
            NumberAnimation { properties: "startY"; duration: 200 }
        }
}
