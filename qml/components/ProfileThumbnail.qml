//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import 'tdlib'

SilicaControl {
    id: profileThumbnail

    property var photoData
    property var minithumbnail

    property string replacementStringHint: "X"
    property string replacementIconSource
    property var replacementImageFile
    property real replacementImageWidth: Theme.iconSizeMedium
    property real replacementImageHeight: replacementImageWidth
    property alias replacementContentLoader: replacementContentLoader

    property real radius: width / 2
    property int imageStatus: -1
    property bool optimizeImageSize: true
    property bool highlighted
    readonly property color defaultReplacementBackgroundColor: palette.colorScheme === Theme.LightOnDark ? Theme.darkSecondaryColor : Theme.lightSecondaryColor
    property alias accentColorId: accentColor.colorId
    property alias replacementBackgroundColor: replacementBackground.color
    property bool asSavedMessages

    layer.enabled: highlighted
    layer.effect: PressEffect { source: profileThumbnail }

    TDLibAccentColor { id: accentColor }

    states: State {
        name: 'savedMessages'
        when: asSavedMessages
        PropertyChanges {
            target: pictureThumbnail
            photoData: null
            minithumbnail: null
            replacementBackgroundColor: palette.highlightBackgroundColor
            replacementIconSource: "image://theme/icon-m-favorite-selected"
        }
    }

    function getReplacementString() {
        // Remove all emoji images
        var strippedText = replacementStringHint.replace(/\<[^>]+\>/g, '').trim()
        if (strippedText.length <= 2)
            return strippedText

        var textElements = strippedText.split(' ')
        var result = textElements[0].charAt(0)
        if (textElements.length > 1)
            result += textElements[textElements.length - 1].charAt(0)
        return result
    }

    Loader {
        id: profileImageLoader
        active: !!(photoData || minithumbnail)
        asynchronous: true
        width: parent.width
        height: width
        sourceComponent: Component {
            Item {
                width: parent.width
                height: width
                visible: opacity > 0
                opacity: (photo.minithumbnailReady || photo.image.status === Image.Ready) ? 1 : 0
                Behavior on opacity { FadeAnimator {} }

                // if this will have bad performance, we can put Image and TDLibThumbnail here manually
                TDLibPhoto {
                    id: photo
                    width: parent.width - Theme.paddingSmall
                    height: width
                    anchors.centerIn: parent
                    image.sourceSize {
                        width: optimizeImageSize ? width : undefined
                        height: optimizeImageSize ? height : undefined
                    }
                    image.autoTransform: true
                    visible: false
                    image.onStatusChanged:
                        profileThumbnail.imageStatus = status

                    fileInformation: photoData
                    minithumbnail: profileThumbnail.minithumbnail
                    loadBackgroundImage: false
                }

                Rectangle {
                    id: profileThumbnailMask
                    width: parent.width - Theme.paddingSmall
                    height: parent.height - Theme.paddingSmall
                    color: palette.primaryColor
                    radius: profileThumbnail.radius
                    anchors.centerIn: photo
                    visible: false
                }

                OpacityMask {
                    source: photo.minithumbnailReady ? photo.minithumbnailItem : photo.image
                    maskSource: profileThumbnailMask
                    anchors.fill: photo
                }
            }
        }
    }

    Item {
        width: parent.width - Theme.paddingSmall
        height: parent.height - Theme.paddingSmall
        anchors.centerIn: parent
        visible: !profileImageLoader.item || !profileImageLoader.item.visible

        Rectangle {
            id: replacementBackground
            anchors.fill: parent
            color: accentColor.invalid ? defaultReplacementBackgroundColor : accentColor.builtInColor
            radius: parent.width / 2
            opacity: 0.8
        }

        Text {
            anchors.centerIn: parent
            visible: replacementContentLoader.status != Loader.Ready || replacementContentLoader.item.status !== Image.Ready
            text: getReplacementString()
            color: palette.primaryColor
            font.bold: true
            font.pixelSize: (profileThumbnail.height >= Theme.itemSizeSmall)
                            ? Theme.fontSizeLarge
                            : (profileThumbnail.height >= Theme.fontSizeLarge ? Theme.fontSizeMedium : Theme.fontSizeTiny)
        }

        Loader {
            id: replacementContentLoader
            anchors.centerIn: parent
            sourceComponent: replacementImageFile ? imageReplacementComponent
                                                  : (replacementIconSource ? iconReplacementComponent : null)

            Component {
                id: iconReplacementComponent
                Icon {
                    source: replacementIconSource
                    highlighted: profileThumbnail.highlighted
                }
            }
            Component {
                id: imageReplacementComponent
                TDLibImage {
                    width: replacementImageWidth
                    height: replacementImageHeight
                    fileInformation: replacementImageFile
                    highlighted: profileThumbnail.highlighted
                }
            }
        }
    }
}
