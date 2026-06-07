import QtQuick 2.0
import Sailfish.Silica 1.0
import "../chat"
import "../../js/functions.js" as Functions

ChatInformationTabItemMediaList {
    messageDelegate: Component {
        WebPagePreview {
            width: parent.width
            y: Theme.paddingMedium
            height: Math.max(Theme.itemSizeExtraSmall, implicitHeight) + 2*y

            linkPreviewData: parent.listItem.message.content.link_preview
            highlighted: parent.listItem.highlighted
            showLargeMedia: false
            infoColumnMouseArea.enabled: false

            function clicked() {
                utilities.handleLink(linkPreviewData.url)
            }
        }
    }
}
