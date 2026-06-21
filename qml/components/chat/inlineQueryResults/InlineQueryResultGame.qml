import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

InlineQueryResultDefaultBase {
    id: queryResultItem

    title: Emoji.emojify(model.game.title || "", titleLable.font.pixelSize)
    description: Emoji.emojify(model.game.description || "", descriptionLabel.font.pixelSize)
    descriptionLabel {
        maximumLineCount: 3
        wrapMode: Text.Wrap
    }

    icon.source: "image://theme/icon-m-game-controller"
    icon.visible: thumbnail.opacity === 0


    Component.onCompleted: {
        if (model.game.photo) {
            // Check first which size fits best...
            var photo = utilities.findPhotoSize(model.game.photo.sizes, queryResultItem.width).photo
            if (photo)
                thumbnailFileInformation = photo
        }
    }
}
