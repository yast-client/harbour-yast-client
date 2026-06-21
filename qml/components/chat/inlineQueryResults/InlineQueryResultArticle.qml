import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

InlineQueryResultDefaultBase {
    id: queryResultItem

    title: Emoji.emojify(model.title || "", titleLable.font.pixelSize)
    description: Emoji.emojify(model.description || "", descriptionLabel.font.pixelSize)
    descriptionLabel {
        maximumLineCount: 3
        wrapMode: extraText.length === 0 ? Text.Wrap : Text.NoWrap
    }

    extraText: model.url || ""
    extraTextLabel.visible: !model.hide_url && extraText.length > 0

    thumbnailFileInformation: model.thumbnail ? model.thumbnail.file : {}

    icon.source: "image://theme/icon-m-link"
    icon.visible: thumbnail.visible && thumbnail.opacity === 0

    thumbnail.visible: model.thumbnail || !!model.url
}
