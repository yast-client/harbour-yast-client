import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../components/tdlib'
import '../components/messageContent/mediaAlbumPage'

MediaAlbumPage {
    id: page
    property var chatManager

    model: ChatPhotosModel {
        id: chatPhotosModel
        tdlib: tdLibWrapper
        chatId: chatManager.chatId
        filter: TDLibAPI.SearchMessagesFilterChatPhoto
    }

    pagedView.direction: PagedView.LeftToRight
    delegate: PhotoComponent {
        width: PagedView.contentWidth
        height: PagedView.contentHeight

        readonly property var _model: display
    }

    onIndexChanged:
        if (index >= count - 1 - 10)
            model.loadMoreHistory()

    overlay.previewModel: chatPhotosModel
    overlay.previewComponent: Component {
        TDLibPhoto {
            property var chatPhoto: model.display.content.photo

            height: parent.height
            width: ListView.isCurrentItem ? height : (height / 2)
            Behavior on width { NumberAnimation { duration: 150 } }

            fileInformation: utilities.findSmallestPhotoSize(chatPhoto.sizes).photo
            minithumbnail: chatPhoto.minithumbnail
            highlighted: singlePreviewMouseArea.containsPress

            MouseArea {
                id: singlePreviewMouseArea
                anchors.fill: parent
                onClicked: overlay.jumpedToIndex(index)
            }
        }
    }
    overlay.previewCurrentIndex: index

    overlay.message: pagedView.currentItem._model
    overlay.forwardButtonVisible: false
    // TODO: allow deleting currently set photo if it does not have a message
    overlay.deleteButtonVisible: !!overlay.propertiesLoader.properties.can_be_deleted_for_all_users
    overlay.applyButtonVisible: false // TODO

    overlay.onDeleted:
        if (overlay.message.id === 0)
            tdLibWrapper.setChatPhoto(chatManager.chatId)
        else
            tdLibWrapper.deleteMessages(chatManager.chatId, [overlay.message.id], true)
    overlay.onApplied:
        tdLibWrapper.setPreviousChatPhoto(chatManager.chatId, overlay.message.content.photo.id)
}
