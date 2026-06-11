import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'
import '../../js/twemoji.js' as Emoji

Loader {
    id: reactionLoader
    width: Theme.fontSizeExtraLarge
    height: width

    property var type
    property bool highlighted
    property bool supported: !!sourceComponent && (!item || item.status !== Image.Error)

    sourceComponent:
        switch (type['@type']) {
        case 'reactionTypeEmoji':
            return emojiReactionComponent
        //case 'reactionTypeCustomEmoji':
        //    return customEmojiReactionComponent
        //case 'reactionTypePaid':
        //    return paidReactionComponent
        default:
            return undefined
        }

    Component {
        id: emojiReactionComponent
        Image {
            id: emojiReaction
            anchors.fill: parent
            sourceSize: {
                width: width
                height: height
            }
            source: Emoji.getEmojiPath(type.emoji)

            layer.enabled: highlighted
            layer.effect: PressEffect { source: emojiReaction }
        }
    }
}
