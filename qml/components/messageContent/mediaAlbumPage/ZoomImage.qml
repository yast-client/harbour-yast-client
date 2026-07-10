import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../../tdlib'

ZoomArea {
    // id
    id: zoomArea
    property var photoData //albumMessages[index].content.photo
    property var photoSize: photoData ? utilities.findBiggestPhotoSize(photoData.sizes) : null
    property bool active: true
    property alias image: image
    property bool highlighted

    signal clicked

    maximumZoom: Math.max(Screen.width, Screen.height) / 200
//    maximumZoom: Math.max(fitZoom, 1) * 3
    implicitContentWidth: image.implicitWidth
    implicitContentHeight: image.implicitHeight
    zoomEnabled: image.status == Image.Ready

    onActiveChanged: {
        if (!active) {
            zoomOut()
        }
    }
    TDLibImage {
        id: image

        width: parent.width
        height: parent.height
        source: file.isDownloadingCompleted ? file.path : ""
        anchors.centerIn: parent

        sourceSize {
            width: photoSize.width
            height: photoSize.height
        }
        fileInformation: photoSize.photo

        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: !(movingVertically || movingHorizontally)

        Behavior on opacity { FadeAnimator{} }
    }
    Item {
        anchors.fill: parent

    }
    MouseArea {
        id: mouseArea
        anchors.centerIn: parent
        width: zoomArea.contentWidth
        height: zoomArea.contentHeight
        onClicked: zoomArea.clicked()
    }


    BusyIndicator {
        running: image.file.isDownloadingActive && !delayBusyIndicator.running
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        parent: zoomArea
        Timer {
            id: delayBusyIndicator
            running: image.file.isDownloadingActive
            interval: 1000
        }
    }
}
