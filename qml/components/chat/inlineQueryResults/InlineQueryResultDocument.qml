import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../../../js/twemoji.js" as Emoji

Loader {
    Component {
        id: documentComponent
        InlineQueryResultDefaultBase {
            id: queryResultItem

            title: Emoji.emojify(model.title || model.document.file_name || "", titleLable.font.pixelSize)
            description: Emoji.emojify(model.description || model.document.file_name || "", descriptionLabel.font.pixelSize)
            extraText: Format.formatFileSize(model.document.document.expected_size)

            thumbnailFileInformation: model.thumbnail ? model.thumbnail.file : {}

            icon.source: Theme.iconForMimeType(model.document.mime_type)
            icon.visible: thumbnail.visible && thumbnail.opacity === 0
        }
    }
    Component {
        id: voiceNoteDocumentComponent
        InlineQueryResultVoiceNote {
            resultData: model.document
            audioData: model.document.document
        }
    }
    sourceComponent: model.document.mime_type === "audio/ogg" ? voiceNoteDocumentComponent : documentComponent
}
