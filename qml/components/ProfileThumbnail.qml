import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import 'tdlib'

Item {
    id: profileThumbnail

    property var photoData
    property var minithumbnail
    property string replacementStringHint: "X"
    property int radius: width / 2
    property int imageStatus: -1
    property bool optimizeImageSize: true
    property bool highlighted

    layer.enabled: highlighted
    layer.effect: PressEffect { source: profileThumbnail }

    function getReplacementString() {
        if (replacementStringHint.length > 2) {
            // Remove all emoji images
            var strippedText = replacementStringHint.replace(/\<[^>]+\>/g, "").trim();
            if (strippedText.length > 0) {
                var textElements = strippedText.split(" ");
                if (textElements.length > 1) {
                    return textElements[0].charAt(0) + textElements[textElements.length - 1].charAt(0);
                } else {
                    return textElements[0].charAt(0);
                }
            }
        }
        return replacementStringHint;
    }

    Loader {
        id: profileImageLoader
        active: !!(photoData || minithumbnail)
        asynchronous: true
        width: parent.width
        sourceComponent: Component {
            Item {
                width: parent.width
                height: width
                visible: opacity > 0
                opacity: (photo.minithumbnailReady || photo.image.status === Image.Ready) ? 1 : 0
                Behavior on opacity { FadeAnimation {} }

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
                    color: Theme.primaryColor
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
            id: replacementThumbnailBackground
            anchors.fill: parent
            color: (Theme.colorScheme === Theme.LightOnDark) ? Theme.darkSecondaryColor : Theme.lightSecondaryColor
            radius: parent.width / 2
            opacity: 0.8
        }

        Text {
            anchors.centerIn: replacementThumbnailBackground
            text: getReplacementString()
            color: Theme.primaryColor
            font.bold: true
            font.pixelSize: (profileThumbnail.height >= Theme.itemSizeSmall)
                            ? Theme.fontSizeLarge
                            : (profileThumbnail.height >= Theme.fontSizeLarge ? Theme.fontSizeMedium : Theme.fontSizeTiny)
        }
    }
}
