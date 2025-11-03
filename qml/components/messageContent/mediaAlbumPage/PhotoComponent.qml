import QtQuick 2.6

ZoomImage {
    photoData: _model.content.photo
    onClicked: {
        if(zoomed) {
            zoomOut(true)
            page.overlayActive = true
        } else {
            page.overlayActive = !page.overlayActive
        }
    }
}
