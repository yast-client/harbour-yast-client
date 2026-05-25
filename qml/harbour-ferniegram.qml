/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "pages"
import "components"
import "./js/functions.js" as Functions
import io.libfernie 1.0

ApplicationWindow {
    id: appWindow

    initialPage: Qt.resolvedUrl("pages/OverviewPage.qml")
    cover: Qt.resolvedUrl("pages/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Connections {
        target: tdLibWrapper
        onErrorReceived: Functions.handleErrorMessage(code, message, extra)
        onServiceNotificationReceived: {
            var text = utilities.getMessageContentText(content, Utilities.MessageTextSimple)
            if (type.indexOf('AUTH_KEY_DROP_') === 0) {
                pageStack.completeAnimation()
                pageStack.push(Qt.resolvedUrl('dialogs/AuthKeyDropDialog.qml'), {text: text})
            } else
                appNotification.show(text)
        }
        onDeepLinkInfoReceived: appNotification.show(utilities.enhanceMessageText(text))
        onLinkUnsupportedByApp: appNotification.show(qsTr("Link unsupported: %1").arg(type))
    }

    Connections {
        target: Qt.application
        onStateChanged:
            tdLibWrapper.options.online = Qt.application.state === Qt.ApplicationActive
    }

    AppNotification {
        id: appNotification
        parent: contentItem
        layoutMaxWidth: orientation & Orientation.LandscapeMask ? parent.height : parent.width
        rotation: switch (appWindow.orientation) {
                      // 90 * (appWindow.orientation-1) would work, but it can break
                  case Orientation.Portrait: return 0
                  case Orientation.Landscape: return 90
                  case Orientation.PortraitInverted: return 180
                  case Orientation.LandscapeInverted: return 270
                  }
    }

    ConfigurationGroup {
        id: appConfig
        path: '/apps/io.ferniegram/ferniegram'

        property int remainingInteractionHints: 3
        property int remainingDoubleTapHints: 3
        property bool archiveChatListHintCompleted

        ConfigurationGroup {
            id: appSettings
            path: 'settings'

            property bool sendByEnter
            property bool sendAttachmentByEnter
            property bool focusTextAreaAfterSend
            property bool focusTextAreaOnChatOpen

            property bool showStickersAsEmojis
            property bool showStickersAsImages
            property bool animateStickers: true
            property bool videoStickers: true
            property bool downscaleAnimatedStickers

            property bool goToQuotedMessage
            property bool delayMessageRead: true
            property bool highlightUnreadConversations

            property bool forceQtAudioRecorder
            property real voiceNoteVolume: 1

            property bool showTranslateOption
            property bool formattedTranslate
            property bool forceAllowAISummary

            property bool showFolderUnreadCount
            property bool chatFoldersTabBarOnBottom
            property bool chatFoldersTabBarShowIcons

            property bool compactChatList: true
        }
    }

    Binding {
        target: voiceNoteRecorder
        property: 'forceQtAudioRecorder'
        value: appSettings.forceQtAudioRecorder
    }
    Binding {
        target: voiceNoteRecorder
        property: 'volume'
        value: appSettings.voiceNoteVolume
    }

    Component.onCompleted: {
        Functions.setGlobals({
            tdLibWrapper: tdLibWrapper,
            appNotification: appNotification,
            utilities: utilities,
        })
    }

    Button {
        visible: callsManager.currentCallState == CallsManager.Ready
        enabled: visible
        anchors.centerIn: parent
        text: "[DEBUG] Call active, tap to discard"
        onClicked: callsManager.discardCurrentCall()
    }
}
