import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import '../components'
import '../components/messageContent/mediaAlbumPage'

MediaAlbumPage {
    property alias userId: profilePicturesModel.userId
    property bool isMyself: userId === tdLibWrapper.myUserId

    model: UserProfilePicturesModel {
        id: profilePicturesModel
        tdlib: tdLibWrapper
    }
    modelIsMedia: false

    pagedView.direction: PagedView.LeftToRight
    delegate: PhotoComponent {
        width: PagedView.contentWidth
        height: PagedView.contentHeight

        property string photoId: photo_id
        property bool isCurrent: is_current

        photoData: null
        photoSize: big_photo
    }

    onIndexChanged:
        if (index >= count - 1 - 10)
            profilePicturesModel.loadMore()

    overlay.previewModel: profilePicturesModel
    overlay.previewComponent: Component {
        TDLibPhoto {
            height: parent.height
            width: ListView.isCurrentItem ? height : (height / 2)
            Behavior on width { NumberAnimation { duration: 150 } }

            fileInformation: small_photo.photo
            minithumbnail: photo_minithumbnail
            highlighted: singlePreviewMouseArea.containsPress

            MouseArea {
                id: singlePreviewMouseArea
                anchors.fill: parent
                onClicked: overlay.jumpedToIndex(index)
            }
        }
    }
    overlay.previewCurrentIndex: index

    overlay.file.fileInformation: pagedView.currentItem.photoSize.photo

    overlay.forwardButtonVisible: false
    overlay.deleteButtonVisible: isMyself
    overlay.applyButtonVisible: true
    overlay.applyButtonEnabled: !pagedView.currentItem.isCurrent // public photo can be set as main too

    overlay.onDeleted:
        tdLibWrapper.deleteProfilePhoto(pagedView.currentItem.photoId)
    overlay.onApplied:
        tdLibWrapper.setPreviousProfilePhoto(pagedView.currentItem.photoId)

    Connections {
        target: tdLibWrapper
        onOkReceived:
            if (extra == 'setPreviousProfilePhoto')
                pageStack.pop()
    }
}
