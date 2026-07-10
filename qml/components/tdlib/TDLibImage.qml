import QtQuick 2.6
import io.yaqtlib 1.0
import Sailfish.Silica 1.0
import '..'

Image {
    id: tdLibImage
    property alias fileInformation: file.fileInformation
    readonly property alias file: file
    property bool highlighted

    asynchronous: true
    enabled: !!file.fileId
    fillMode: Image.PreserveAspectCrop
    clip: true
    opacity: status === Image.Ready ? 1.0 : 0.0
    source: enabled && file.isDownloadingCompleted ? file.path : ''
    visible: opacity > 0
    sourceSize {
        width: width
        height: height
    }

    Behavior on opacity { FadeAnimator {} }

    layer {
        enabled: tdLibImage.enabled && tdLibImage.highlighted
        effect: PressEffect { source: tdLibImage }
    }

    TDLibFile {
        id: file
        autoLoad: true
        tdlib: tdLibWrapper
    }
}
