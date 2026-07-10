import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../"
import "../../js/twemoji.js" as Emoji

MessageContentBase {
    id: stickerMessage

    property list<Item> extraContextMenuItems: [
        MenuItem {
            property bool isFavorite: stickerManager.favoriteStickerIds.indexOf(stickerData.sticker.id)
            text: isFavorite ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
            onClicked:
                if (isFavorite)
                    tdLibWrapper.removeFavoriteSticker(stickerData.sticker.id)
                else
                    tdLibWrapper.addFavoriteSticker(stickerData.sticker.id)
        }
    ]

    property var stickerData: rawMessage.content.sticker
    readonly property bool isOwnSticker: !!(messageListItem && messageListItem.isOwnMessage)

    implicitWidth: Theme.itemSizeLarge*3
    implicitHeight: implicitWidth * sticker.aspectRatio

    TDLibSticker {
        id: sticker
        width: Math.min(parent.width, parent.implicitWidth)
        // (centered in image mode, text-like in sticker mode)
        anchors {
            horizontalCenter: appSettings.showStickersAsImages ? parent.horizontalCenter : undefined
            right: !appSettings.showStickersAsImages && isOwnSticker ? parent.right : undefined
            verticalCenter: parent.verticalCenter
        }

        stickerData: stickerMessage.stickerData
        highlighted: stickerMessage.highlighted
    }

    onClicked: {
        stickerSetOverlayLoader.stickerSetId = stickerData.set_id
        stickerSetOverlayLoader.active = true
    }
}
