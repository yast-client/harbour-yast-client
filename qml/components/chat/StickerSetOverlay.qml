import QtQuick 2.6
import Sailfish.Silica 1.0
import '../tdlib'
import '../../js/twemoji.js' as Emoji

Flickable {
    id: stickerSetOverlayFlickable
    anchors.fill: parent
    boundsBehavior: Flickable.StopAtBounds
    contentHeight: stickerSetContentColumn.height
    clip: true

    property string stickerSetId // Sticker set ID is int64, which can only be represented as a string in JS
    property bool isInstalled: stickerSet && stickerSet.is_installed
    property var stickerSet
    signal requestClose
    signal stickerPicked(var stickerId)

    Component.onCompleted:
        tdLibWrapper.getStickerSet(stickerSetId)

    onIsInstalledChanged: {
        if (isInstalled)
            appNotification.show(qsTr("Sticker set installed"))
        else
            appNotification.show(qsTr("Sticker set removed"))
    }

    Connections {
        target: tdLibWrapper
        onStickerSetReceived:
            if (stickerSetId === stickerSetOverlayFlickable.stickerSetId)
                stickerSetOverlayFlickable.stickerSet = stickerSet
        onStickerSetUpdated:
            if (stickerSetId === stickerSetOverlayFlickable.stickerSetId)
                stickerSetOverlayFlickable.stickerSet = stickerSet
    }

    Rectangle {
        id: stickerSetContentBackground
        color: Theme.overlayBackgroundColor
        opacity: 0.7
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            onClicked: requestClose()
        }
    }

    Column {
        id: stickerSetContentColumn
        spacing: Theme.paddingMedium
        width: parent.width
        height: parent.height

        Row {
            id: stickerSetTitleRow
            width: parent.width - ( 2 * Theme.horizontalPageMargin )
            height: overlayStickerTitleText.height + ( 2 * Theme.paddingMedium )
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                id: overlayStickerTitleText

                width: parent.width - changeSetButton.width - closeSetButton.width
                text: stickerSet.title
                font.pixelSize: Theme.fontSizeExtraLarge
                font.weight: Font.ExtraBold
                maximumLineCount: 1
                truncationMode: TruncationMode.Fade
                textFormat: Text.StyledText
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                id: changeSetButton
                icon.source: 'image://theme/icon-m-' + (isInstalled ? 'remove' : 'add')
                anchors.verticalCenter: parent.verticalCenter
                onClicked:
                    tdLibWrapper.changeStickerSet(stickerSet.id, !isInstalled)
            }

            IconButton {
                id: closeSetButton
                icon.source: "image://theme/icon-m-clear"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    stickerSetOverlayFlickable.requestClose();
                }
            }
        }

        SilicaGridView {
            id: stickerSetGridView

            width: parent.width - ( 2 * Theme.horizontalPageMargin )
            height: parent.height - stickerSetTitleRow.height - Theme.paddingMedium
            anchors.horizontalCenter: parent.horizontalCenter

            cellWidth: chatPage.isLandscape ? (width / 5) : (width / 3);
            cellHeight: cellWidth

            visible: count > 0

            clip: true

            model: stickerSet.stickers
            delegate: BackgroundItem {
                width: stickerSetGridView.cellWidth
                height: stickerSetGridView.cellHeight

                TDLibThumbnail {
                    id: singleStickerThumbnail
                    anchors.centerIn: parent
                    width: stickerSetGridView.cellWidth - Theme.paddingSmall
                    height: stickerSetGridView.cellHeight - Theme.paddingSmall

                    thumbnail: modelData.thumbnail

                    Label {
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        text: Emoji.emojify(modelData.emoji, font.pixelSize)
                    }
                }

                onClicked: stickerPicked(modelData.sticker.remote.id)
            }

            VerticalScrollDecorator {}
        }

    }

}
