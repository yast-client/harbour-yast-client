import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../tdlib'

MessageContentBase {
    height: Math.max(Theme.itemSizeExtraSmall, Math.min(Math.round(width * 0.66666666), width / getAspectRatio()))
    readonly property alias photoData: photo.photo

    onClicked: {
        pageStack.push(Qt.resolvedUrl("../../pages/MediaAlbumPage.qml"), {
            chatManager: chatManager,
            message: rawMessage,
            singleElement: isSponsored,
            searchMessagesFilter: TDLibAPI.SearchMessagesFilterPhotoAndVideo
        })
    }
    function getAspectRatio() {
        var candidate = photoData.sizes[photoData.sizes.length - 1];
        if (candidate.width === 0 && photoData.sizes.length > 1) {
           for (var i = (photoData.sizes.length - 2); i >= 0; i--) {
               candidate = photoData.sizes[i];
               if (candidate.width > 0) {
                   break;
               }
           }
        }
        return candidate.width / candidate.height;
    }
    TDLibPhoto {
        id: photo
        anchors.fill: parent
        photo: rawMessage.content.photo
        highlighted: parent.highlighted
    }
}
