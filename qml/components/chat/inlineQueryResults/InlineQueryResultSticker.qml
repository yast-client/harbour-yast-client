import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import Nemo.Thumbnailer 1.0
import "../.."

InlineQueryResult {
    id: queryResultItem

    property bool animate
    property bool animating: animate && model.sticker.is_animated
    property url stickerId: "http://sticker/" + model.sticker.sticker.remote.id
    onAnimatingChanged: {
        if(animating) {
            resultView.requestPlayback(stickerId);
        }
    }

    Connections {
        target: resultView
        onRequestPlayback: {
            if(queryResultItem.animating && queryResultItem.stickerId !== playbackSource) {
                animate = false
            }
        }
    }

    onPressAndHold: {
        animate = !animate
    }

    TDLibFile {
        id: file
        tdlib: tdLibWrapper
        fileInformation: model.sticker.sticker
        autoLoad: true
    }

    Loader {
        id: animatedStickerLoader
        anchors {
            fill: parent
            margins: Theme.paddingLarge
        }
        active: queryResultItem.animating
        sourceComponent: Component {
            AnimatedImage {
                id: animatedSticker
                anchors.fill: parent
                source: file.path
                asynchronous: true
                paused: !Qt.application.active
                cache: false
                layer.enabled: highlighted
                layer.effect: PressEffect { source: animatedSticker }
            }
        }
    }

    Image {
        id: staticSticker
        anchors {
            fill: parent
            margins: Theme.paddingLarge
        }
        source: file.path
        fillMode: Image.PreserveAspectFit
        autoTransform: true
        asynchronous: true
        visible: !queryResultItem.animating && opacity > 0
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { FadeAnimation {} }
        layer.enabled: queryResultItem.highlighted
        layer.effect: PressEffect { source: staticSticker }
    }

    Icon {
        source: "image://theme/icon-m-video"
        width: Theme.iconSizeExtraSmall
        height: width
        visible: model.sticker.is_animated
        highlighted: queryResultItem.highlighted || queryResultItem.animating
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
    }
}
