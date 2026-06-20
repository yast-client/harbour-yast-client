import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

Dialog {
    allowedOrientations: Orientation.All
    backNavigation: false

    acceptDestination: Qt.resolvedUrl('InitializationDialog.qml')
    acceptDestinationProperties: ({initial: true})
    onAccepted: appConfig.welcomeTourCompleted = true

    DialogHeader {
        id: dialogHeader
        acceptText: qsTr("Start Messaging")
    }

    PagedView {
        id: welcomePagedView
        width: parent.width
        anchors {
            top: dialogHeader.bottom
            bottom: parent.bottom
        }
        wrapMode: PagedView.NoWrap
        model: [
            {image: Qt.resolvedUrl('../../images/yast-client.svg'), title: "YAST Client", description: qsTr("YAST Client is a yet another SailfishOS Telegram client")},
            {image: Qt.resolvedUrl('../../images/folders/icon-m-folder-airplane.svg'), title: "Telegram", description: qsTr("YAST is not an official Telegram client, but it uses the official Telegram API through TDLib")},
            {image: Qt.resolvedUrl('../../images/icon-tour-free.svg'), title: qsTr("Free"), description: qsTr("Telegram provides free unlimited cloud storage for chats and media")},
            {image: Qt.resolvedUrl('../../images/icon-tour-secure.svg'), title: qsTr("Secure"), description: qsTr("Telegram keeps your messages safe from hacker attacks")},
            {image: Qt.resolvedUrl('../../images/icon-tour-cloud-based.svg'), title: qsTr("Cloud-Based"), description: qsTr("Telegram lets you access your messages from multiple devices")},
        ]

        delegate: Item {
            width: PagedView.contentWidth
            height: PagedView.contentHeight

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: parent.height
                spacing: Theme.paddingLarge

                Image {
                    source: modelData.image
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(2 * Theme.itemSizeHuge, Math.min(Screen.width, Screen.height) / 2)
                    height: width
                    sourceSize {
                        width: width
                        height: height
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Label {
                    width: parent.width
                    text: modelData.title
                    color: Theme.highlightColor
                    font {
                        pixelSize: Theme.fontSizeExtraLarge
                        family: Theme.fontFamilyHeading
                    }
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    width: parent.width
                    text: modelData.description
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Row {
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }
            spacing: Theme.paddingMedium

            Repeater {
                model: welcomePagedView.count
                Rectangle {
                    property bool active: welcomePagedView.currentIndex == index

                    width: Theme.paddingLarge
                    height: width
                    radius: width
                    color: active ? Theme.highlightColor : 'transparent'
                    border {
                        width: Theme.paddingSmall/2
                        color: active || pageDotMouseArea.containsPress ? Theme.highlightColor : Theme.primaryColor
                    }

                    MouseArea {
                        id: pageDotMouseArea
                        anchors.fill: parent
                        onClicked: welcomePagedView.currentIndex = index
                    }
                }
            }
        }
    }
}
