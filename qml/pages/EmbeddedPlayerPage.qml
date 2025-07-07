import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0

FullscreenContentPage {
    property var linkPreviewType: ({})

    MouseArea {
        width: parent.width
        anchors.bottom: webView.top
        onClicked: closeButton.enabled = !closeButton.enabled
    }

    WebView {
        id: webView
        url: linkPreviewType.url
        width: parent.width
        height: width / (linkPreviewType.width / linkPreviewType.height)
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        width: parent.width
        anchors {
            top: webView.bottom
            bottom: parent.bottom
        }
        onClicked: closeButton.enabled = !closeButton.enabled
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
       opacity: enabled ? 1 : 0
       Behavior on opacity { FadeAnimator {} }
       onEnabledChanged: if (enabled) hideCloseButtonTimer.start()
                         else hideCloseButtonTimer.stop()
    }

    Timer {
        id: hideCloseButtonTimer
        running: true
        interval: 3000
        onTriggered: closeButton.enabled = false
    }
}
