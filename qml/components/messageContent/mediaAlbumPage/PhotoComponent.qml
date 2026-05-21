import QtQuick 2.6

ZoomImage {
    photoData: _model.content && _model.content['@type'] === 'messagePhoto' ? _model.content.photo : _model
    onClicked: {
        if(zoomed) {
            zoomOut(true)
            page.overlayActive = true
        } else {
            page.overlayActive = !page.overlayActive
        }
    }
}
