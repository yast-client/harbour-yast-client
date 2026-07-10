import QtQuick 2.6
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import '..'

Loader {
    id: loader
    property var minithumbnail
    property string minithumbnailData: minithumbnail ? minithumbnail.data : ''
    property bool highlighted
    property int fillMode: Image.PreserveAspectCrop
    property var image: item ? item.image : null
    // don't rely on visible here (loader itself can be invisible, and invisibility is propogated to children)
    property bool ready: !!image && image.status === Image.Ready

    anchors.fill: parent
    active: !!minithumbnailData
    asynchronous: true

    sourceComponent: Component {
        Item {
            property alias image: minithumbnailImage
            Image {
                id: minithumbnailImage
                anchors.fill: parent
                source: "data:image/jpg;base64,"+minithumbnailData
                fillMode: loader.fillMode
                opacity: status === Image.Ready ? 1.0 : 0.0
                cache: false
                Behavior on opacity { FadeAnimator {} }

                layer {
                    enabled: loader.highlighted
                    effect: PressEffect { source: minithumbnailImage }
                }
            }
            // this had a visible impact on performance
//            FastBlur {
//                anchors.fill: parent
//                source: minithumbnailImage
//                radius: Theme.paddingLarge
//            }
        }
    }
}
