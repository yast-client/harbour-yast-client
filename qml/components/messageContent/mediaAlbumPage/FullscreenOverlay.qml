import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../../../js/functions.js' as Functions
import '../../../js/twemoji.js' as Emoji
import '../..'
import '../../tdlib'


Item {
    id: overlay

    property int currentIndex
    property alias text: captionLabel.text
    property bool active: true
    property var message
    property bool hidePreview
    property var previewModel
    property int previewCurrentIndex: -1
    property bool previewInverted
    property alias propertiesLoader: propertiesLoader
    property alias buttonsRow: buttons
    property alias file: file
    readonly property color gradientColor: '#bb000000'
    readonly property int gradientPadding: Theme.itemSizeMedium

    property bool forwardButtonVisible: true
    property bool deleteButtonVisible
    property bool applyButtonVisible
    property bool applyButtonEnabled: true

    property Component previewComponent: Component {
        Loader {
            id: singlePreviewLoader

            readonly property bool isVideo: content_type === 'messageVideo'
            readonly property var minithumbnail: (isVideo ? (display.content.cover || display.content.video) : display.content.photo).minithumbnail

            height: parent.height
            width: ListView.isCurrentItem ? height : (height / 2)
            Behavior on width { NumberAnimation { duration: 150 } }

            sourceComponent: isVideo && !display.content.cover ? thumbnailComponent : photoComponent

            Component {
                id: thumbnailComponent
                TDLibThumbnail {
                    anchors.fill: parent
                    thumbnail: display.content.video.thumbnail
                    minithumbnail: singlePreviewLoader.minithumbnail
                    highlighted: singlePreviewMouseArea.containsPress
                }
            }

            Component {
                id: photoComponent
                TDLibPhoto {
                    fileInformation: utilities.findSmallestPhotoSize((isVideo ? display.content.cover : display.content.photo).sizes).photo || {}
                    minithumbnail: singlePreviewLoader.minithumbnail
                    highlighted: singlePreviewMouseArea.containsPress
                }
            }

            MouseArea {
                id: singlePreviewMouseArea
                anchors.fill: parent
                onClicked: jumpedToIndex(previewModel.mapToSource(index))
            }
        }
    }

    signal jumpedToIndex(int index)
    signal deleted
    signal applied

    anchors.fill: parent
    opacity: active ? 1 : 0
    Behavior on opacity { FadeAnimator {} }

    function forwardMessage() {
        var neededPermissions = Functions.getMessagesNeededForwardPermissions([message]);
        pageStack.push(Qt.resolvedUrl("../../../pages/ChatSelectionPage.qml"), {
            headerDescription: qsTr("Forward %Ln messages", "dialog header", 1),
            payload: {fromChatId: message.chat_id, messageIds:[message.id], neededPermissions: neededPermissions},
            state: "forwardMessages"
        });
    }

    // "header"

    LinearGradient {
        id: topGradient
        property int startY: 0;
//        Behavior on startY { NumberAnimation {duration: 2000} }
        start: Qt.point(0, Math.min(height-gradientPadding*2, startY))
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: closeButton.bottom

            bottomMargin: -gradientPadding
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: gradientColor }
            GradientStop { position: 1.0; color: 'transparent' }
        }
    }


    IconButton {
        id: closeButton
         icon.source: "image://theme/icon-m-cancel?" + (pressed
                      ? Theme.highlightColor
                      : Theme.lightPrimaryColor)
         onClicked: pageStack.pop()
         anchors {
             right: parent.right
             top: parent.top
             margins: Theme.horizontalPageMargin
         }
     }

    SilicaFlickable {
        id: captionFlickable
        anchors {
            left: parent.left
//            leftMargin: Theme.horizontalPageMargin
            right: closeButton.left
            top: parent.top
//            topMargin: Theme.horizontalPageMargin
        }
        interactive: captionLabel.expanded && contentHeight > height
        clip: true
        height: Math.min(contentHeight, parent.height / 4)
        contentHeight: captionLabel.height + Theme.horizontalPageMargin
        flickableDirection: Flickable.VerticalFlick
        VerticalScrollDecorator {
            opacity: visible ? 1.0 : 0.0
            flickable: captionFlickable
        }

        Label {
            id: captionLabel
            property bool expandable: expanded || height < contentHeight
            property bool expanded

            height: text ?
                        expanded
                            ? contentHeight
                            : Theme.itemSizeMedium
                      : 0;
    //        maximumLineCount: expanded ? 0 : 3
            color: Theme.primaryColor
//            text: model.modelData.content.caption.text
            linkColor: Theme.highlightColor
            text: Emoji.emojify(Functions.enhanceMessageText(message.content.caption, false), Theme.fontSizeExtraSmall)
            onTextChanged: expanded = false
            font.pixelSize: Theme.fontSizeExtraSmall
            wrapMode: Text.Wrap
            bottomPadding: expanded ? Theme.paddingLarge : 0
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.paddingLarge
                right: parent.right
                top: parent.top
                topMargin: (!!Screen.hasCutouts && pageStack.currentPage.orientation === Orientation.Portrait) ? Screen.topCutout.height : Theme.horizontalPageMargin
            }

            Behavior on height { NumberAnimation {duration: 300} }
            Behavior on text {
                SequentialAnimation {
                    FadeAnimation {
                        target: captionLabel
                        to: 0.0
                        duration: 300
                    }
                    PropertyAction {}
                    FadeAnimation {
                        target: captionLabel
                        to: 1.0
                        duration: 300
                    }
                }
            }

        }

        OpacityRampEffect {
                        sourceItem: captionLabel
                        enabled: !captionLabel.expanded
                        direction: OpacityRamp.TopToBottom
                    }
        MouseArea {
            anchors.fill: captionLabel
            enabled: captionLabel.expandable
            onClicked: {
                captionLabel.expanded = !captionLabel.expanded
            }
        }
    }

    // "footer"
    LinearGradient {
        anchors {
            left: parent.left
            right: parent.right
            top: buttons.top
            bottom: parent.bottom
            topMargin: -gradientPadding
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: 'transparent' }
            GradientStop { position: 1.0; color: gradientColor }
        }
    }
    Loader {
        id: previewsLoader
        asynchronous: true
        active: !!previewModel && (typeof previewModel.count == 'undefined' || previewModel.count > 1)
        width: parent.width
        height: hidePreview ? 0 : Theme.itemSizeExtraSmall
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: hidePreview ? 0 : Theme.paddingSmall
        }

        sourceComponent: Component {
            ListView {
                height: Theme.itemSizeExtraSmall
                width: parent.width
                spacing: Theme.paddingMedium

                orientation: Qt.Horizontal
                layoutDirection: previewInverted ? Qt.RightToLeft : Qt.LeftToRight
                preferredHighlightBegin: (width - Theme.itemSizeExtraSmall)/2
                preferredHighlightEnd: (width + Theme.itemSizeExtraSmall)/2
                highlightRangeMode: ListView.StrictlyEnforceRange

                currentIndex: previewCurrentIndex
                model: previewModel
                delegate: previewComponent
            }
        }
    }


    TDLibFile {
        id: file
        autoLoad: false
        tdlib: tdLibWrapper

        fileInformation: {
            if (message['@type'] === 'photo')
                return utilities.findBiggestPhotoSize(message.sizes).photo || {}

            if (message.content['@type'] === 'messagePhoto' || message.content['@type'] === 'messageChatChangePhoto')
                return utilities.findBiggestPhotoSize(message.content.photo.sizes).photo || {}

            var videoData
            switch (message.content['@type']) {
            case 'messageVideo':
                videoData = message.content.video
                break
            case 'messageAnimation':
                videoData = message.content.animation
                break
            default:
                videoData = message.content.video_note
                break
            }

            return videoData[message.content['@type'] === 'messageVideoNote' ? "video" : videoData['@type']]
        }
        // Progress is already displayed on play button
    }

    MessagePropertiesLoader {
        id: propertiesLoader
        message: overlay.message
        autoLoad: !!message && message['@type'] !== 'photo'
    }

    Row {
        id: buttons
        height: Theme.itemSizeSmall
        spacing: visibleChildren.length > 2 ? Theme.paddingLarge : Theme.paddingLarge*2 + Theme.itemSizeSmall
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: previewsLoader.top
            bottomMargin: Theme.paddingSmall
        }

        property color iconColor: pressed ? Theme.highlightColor : Theme.lightPrimaryColor

        IconButton {
            icon.source: file.isDownloadingActive
                       ? "image://theme/icon-m-cancel"
                       : "image://theme/icon-m-downloads"
            icon.color: buttons.iconColor
            onClicked: {
                if(file.isDownloadingCompleted)
                    tdLibWrapper.copyFileToDownloads(file.fileId, file.path, false)
                else if(!file.isDownloadingActive) file.load()
                else file.cancel()
            }
        }

        IconButton {
            visible: forwardButtonVisible
            enabled: !!propertiesLoader.properties.can_be_forwarded
            opacity: enabled ? 1.0 : 0.2
            icon.source: 'image://theme/icon-m-share'
            icon.color: buttons.iconColor
            onClicked: forwardMessage()
        }

        IconButton {
            visible: deleteButtonVisible
            icon.source: 'image://theme/icon-m-delete'
            icon.color: buttons.iconColor
            onClicked: deleted()
        }

        IconButton {
            visible: applyButtonVisible
            enabled: applyButtonEnabled
            icon.source: 'image://theme/icon-m-acknowledge'
            icon.color: buttons.iconColor
            onClicked: applied()
        }
    }

    states: [
        State {
            name: 'hasCaption'
            when: captionLabel.height > 0
            PropertyChanges { target: topGradient;
                startY: captionFlickable.height
            }
            AnchorChanges {
                target: topGradient
                anchors.bottom: captionFlickable.bottom
            }
        }
    ]
    transitions:
        Transition {
            AnchorAnimation { duration: 200 }
            NumberAnimation { properties: "startY"; duration: 200 }
        }
}
