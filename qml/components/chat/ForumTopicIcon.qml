import QtQuick 2.0
import Sailfish.Silica 1.0
import '../tdlib'

Loader {
    anchors.centerIn: parent

    property bool isGeneral
    property string iconCustomEmojiId
    property bool small

    active: isGeneral || iconCustomEmojiId !== '0'
    sourceComponent: isGeneral ? generalIconComponent : customEmojiIconComponent
    Component {
        id: generalIconComponent
        Icon { source: 'image://theme/icon-' + (small ? 's-chat' : 'm-chat') }
    }
    Component {
        id: customEmojiIconComponent
        TDLibCustomEmojiSticker {
            width: small ? Theme.iconSizeSmall : Theme.iconSizeMedium
            customEmojiId: iconCustomEmojiId
            useThumbnail: true
        }
    }
}
