import QtQuick 2.6
import io.yaqtlib 1.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    id: tdLibPhoto
    property var photo
    property bool highlighted
    property alias fileInformation: tdLibImage.fileInformation
    readonly property alias image: tdLibImage
    property bool minithumbnailReady: minithumbnailLoader.ready
    property alias minithumbnailItem: minithumbnailLoader.item
    property alias minithumbnail: minithumbnailLoader.minithumbnail
    property bool loadBackgroundImage: !tdLibImage.visible && !minithumbnailReady
    property bool showEmpty

    onWidthChanged: setImageFile()
    onPhotoChanged: setImageFile()

    function setImageFile() {
        if (photo) {
            var photoSize = utilities.findPhotoSize(photo.sizes, width).photo
            if (photoSize && photoSize.id !== tdLibImage.fileInformation.id)
                tdLibImage.fileInformation = photoSize
        }
    }

    TDLibMinithumbnail {
        id: minithumbnailLoader
        active: !!minithumbnail && tdLibImage.opacity < 1.0
        minithumbnail: tdLibPhoto.photo.minithumbnail
        highlighted: parent.highlighted
        fillMode: tdLibImage.fillMode
    }

    Loader {
        active: loadBackgroundImage
        source: Qt.resolvedUrl('../BackgroundImage.qml')
    }

    TDLibImage {
        id: tdLibImage
        width: parent.width //don't use anchors here for easier custom scaling
        height: parent.height
        cache: false
        highlighted: parent.highlighted
        file.clearWithInvalidFileInfo: showEmpty
    }

    Component.onCompleted: setImageFile()
}
