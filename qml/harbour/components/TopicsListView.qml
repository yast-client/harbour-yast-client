import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaListView {
    model: chatManager.forumTopicsModel

    delegate: PhotoTextsListItem {
        width: parent.width
        primaryText.text: name
    }
}
