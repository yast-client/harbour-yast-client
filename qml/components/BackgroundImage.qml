import QtQuick 2.6
import Sailfish.Silica 1.0

Icon {
    id: imageLoadingBackgroundImage
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    width: sourceDimension
    height: sourceDimension
    opacity: 0.15
    source: "../../images/background.svg"
    color: Theme.colorPrimary
    property int sourceDimension: Math.min(parent.width, parent.height) - Theme.paddingMedium
    anchors.centerIn: parent
    sourceSize {
        width: sourceDimension
        height: sourceDimension
    }
}
