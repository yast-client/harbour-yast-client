import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."
import "../../js/twemoji.js" as Emoji

Item {
    id: stickerPickerOverlayItem
    anchors.fill: parent

    property var recentStickers: []
    property var favoriteStickers: []
    property var installedStickerSets: []

    Connections {
        target: tdLibWrapper
        onRecentStickersUpdated:
            if (!isAttach)
                tdLibWrapper.getRecentStickers()
        onRecentStickersReceived:
            recentStickers = stickers

        onFavoriteStickersUpdated:
            if (!isAttach)
                tdLibWrapper.getFavoriteStickers()
        onFavoriteStickersReceived:
            favoriteStickers = stickers

        onInstalledStickerSetsUpdated:
            if (stickerType == 'stickerTypeRegular')
                tdLibWrapper.getInstalledStickerSets()
        onInstalledStickerSetsReceived:
            installedStickerSets = stickerSets

        onStickerSetUpdated: {
            for (var i=0; i < installedStickerSets.length; i++)
                if (installedStickerSets[i].id == stickerSetId) {
                    installedStickerSets[i] = stickerSet
                    installedStickerSetsChanged()
                }
        }
    }

    Component.onCompleted: {
        tdLibWrapper.getRecentStickers()
        tdLibWrapper.getFavoriteStickers()
        tdLibWrapper.getInstalledStickerSets()
    }

    Component {
        id: stickerComponent
        BackgroundItem {
           id: stickerSetItem
           width: Theme.itemSizeExtraLarge
           height: Theme.itemSizeExtraLarge

           onClicked: stickerPickerOverlayItem.stickerPicked(modelData.sticker.remote.id)

           TDLibThumbnail {
               thumbnail: modelData.thumbnail
               anchors.fill: parent
               highlighted: stickerSetItem.highlighted
           }

           Label {
               font.pixelSize: Theme.fontSizeSmall
               anchors.right: parent.right
               anchors.bottom: parent.bottom
               text: Emoji.emojify(modelData.emoji, font.pixelSize)
           }

       }
    }

    signal stickerPicked(var stickerId)

    Rectangle {
        id: stickerPickerOverlayBackground
        anchors.fill: parent

        color: Theme.overlayBackgroundColor
        opacity: 0.7
    }

    SilicaListView {
        id: stickerPickerListView
        anchors.fill: parent
        clip: true

        model: stickerPickerOverlayItem.installedStickerSets

        header: Column {
            spacing: Theme.paddingSmall
            width: stickerPickerListView.width
            topPadding: Theme.paddingSmall

            SectionHeader {
                visible: recentStickersGridView.count > 0
                text: qsTr("Recently used", "stickers")
            }
            SilicaGridView {
                id: recentStickersGridView
                width: parent.width
                height: Theme.itemSizeExtraLarge + Theme.paddingSmall
                cellWidth: Theme.itemSizeExtraLarge
                cellHeight: Theme.itemSizeExtraLarge
                visible: count > 0
                clip: true
                flow: GridView.FlowTopToBottom

                model: stickerPickerOverlayItem.recentStickers
                delegate: stickerComponent

                HorizontalScrollDecorator {}
            }

            SectionHeader {
                visible: favoriteStickersGridView.count > 0
                text: qsTr("Favorite", "stickers")
            }
            SilicaGridView {
                id: favoriteStickersGridView
                width: parent.width
                height: Theme.itemSizeExtraLarge + Theme.paddingSmall
                cellWidth: Theme.itemSizeExtraLarge
                cellHeight: Theme.itemSizeExtraLarge
                visible: count > 0
                clip: true
                flow: GridView.FlowTopToBottom

                model: stickerPickerOverlayItem.favoriteStickers
                delegate: stickerComponent

                HorizontalScrollDecorator {}
            }
        }
        delegate: Column {
            id: stickerSetColumn

            property bool isExpanded: false
            property string stickerSetId: modelData.id

            spacing: Theme.paddingSmall
            width: parent.width

            Row {
                id: stickerSetTitleRow
                width: parent.width
                height: Theme.itemSizeMedium + ( 2 * Theme.paddingSmall )
                spacing: Theme.paddingMedium
                BackgroundItem {
                    id: stickerSetToggle
                    width: parent.width - removeSetButton.width - Theme.paddingMedium * 2
                    height: parent.height

                    onClicked:
                        isExpanded = !isExpanded
                    TDLibThumbnail {
                        id: stickerSetThumbnail
                        thumbnail: modelData.thumbnail ? modelData.thumbnail : modelData.covers[0].thumbnail
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.paddingMedium
                        }
                        width: Theme.itemSizeMedium
                        height: Theme.itemSizeMedium
                        highlighted: stickerSetToggle.down
                    }

                    Label {
                        id: setTitleText
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true

                        anchors {
                            left: stickerSetThumbnail.right
                            right: expandSetButton.left
                            verticalCenter: parent.verticalCenter
                            margins: Theme.paddingSmall
                        }
                        truncationMode: TruncationMode.Fade
                        text: modelData.title
                    }

                    Icon {
                        id: expandSetButton
                        source: stickerSetColumn.isExpanded ? "image://theme/icon-m-up" : "image://theme/icon-m-down"
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: Theme.paddingMedium
                        }
                    }


                }


                IconButton {
                    id: removeSetButton
                    icon.source: "image://theme/icon-m-remove"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        var stickerSetId = modelData.id;
                        Remorse.popupAction(chatPage, qsTr("Removing sticker set"), function() {
                            tdLibWrapper.changeStickerSet(stickerSetId, false)
                        });
                    }
                }

            }

            Loader {
                id: stickerSetLoader
                width: parent.width
                active: stickerSetColumn.isExpanded || height > 0
                height: stickerSetColumn.isExpanded ? Theme.itemSizeExtraLarge + Theme.paddingSmall : 0
                opacity: stickerSetColumn.isExpanded ? 1.0 : 0.0

                Behavior on height { NumberAnimation { duration: 200 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                sourceComponent: Component {
                    SilicaListView {
                        id: installedStickerSetGridView
                        width: stickerSetLoader.width
                        height: stickerSetLoader.height

                        orientation: Qt.Horizontal
                        visible: count > 0

                        delegate: stickerComponent

                        Component.onCompleted: {
                            if (stickerManager.hasStickerSet(stickerSetColumn.stickerSetId))
                                model = stickerManager.getStickerSet(stickerSetColumn.stickerSetId).stickers
                            else
                                tdLibWrapper.getStickerSet(stickerSetColumn.stickerSetId)
                        }

                        Connections {
                            target: stickerManager
                            onStickerSetStickersUpdated:
                                if (stickerSetId == stickerSetColumn.stickerSetId)
                                    installedStickerSetGridView.model = stickerManager.getStickerSet(stickerSetColumn.stickerSetId).stickers
                        }

                        HorizontalScrollDecorator {}
                    }
                }
            }
        }
    }
}
