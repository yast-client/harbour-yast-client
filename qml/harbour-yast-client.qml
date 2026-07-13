import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import QtMultimedia 5.6
import QtFeedback 5.0
import "pages"
import "components"
import "./js/functions.js" as Functions
import io.yaqtlib 1.0

ApplicationWindow {
    id: appWindow

    initialPage: Qt.resolvedUrl("pages/OverviewPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
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

    Connections {
        target: dBusAdaptor
        onActivateWindow:
            appWindow.activate()
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
        path: '/apps/yast-client'

        property int remainingInteractionHints: 3
        property int remainingDoubleTapHints: 3
        property bool archiveChatListHintCompleted
        property bool welcomeTourCompleted // TBD: is it ok that right now WelcomeDialog doesn't open after logging out or reinstalling the app?

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

            property bool delayMessageRead: true
            property bool highlightUnreadConversations

            property bool forceQtAudioRecorder
            property real voiceNoteVolume: 1

            property bool showTranslateOption: true
            property bool formattedTranslate
            property bool forceAllowAISummary

            property bool showFolderUnreadCount
            property bool chatFoldersTabBarOnBottom
            property bool chatFoldersTabBarShowIcons

            property bool compactChatList: true

            property bool dnbCallRingtone: true
            property bool inAppChatMessagesNgf: true
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


    // Calls
    property var callWindowInstance

    Connections {
        target: NO_HARBOUR_COMPLIANCE ? callsManager : null
        ignoreUnknownSignals: true
        onCallStarted: {
            if (!callWindowInstance)
                callWindowInstance = Qt.createComponent(Qt.resolvedUrl("CallWindow.qml")).createObject()
            callWindowInstance.show()
        }
    }

    ConfigurationValue {
        id: doNotDisturbKey
        key: '/lipstick/do_not_disturb'
        defaultValue: false
    }
    Binding {
        target: notificationManager
        property: 'enableNgfCallsRingtone'
        value: appSettings.dnbCallRingtone || !doNotDisturbKey.value
    }


    // Messages NGF
    SoundEffect {
        id: incomingMessageEffect
        source: Qt.resolvedUrl('../assets/message_incoming.wav')
        onPlayingChanged:
            if (playing) incomingMessageThemeEffect.play()
    }
    ThemeEffect {
        id: incomingMessageThemeEffect
        effect: ThemeEffect.Press
    }

    SoundEffect {
        id: outgoingMessageEffect
        source: Qt.resolvedUrl('../assets/message_outgoing.wav')
        onPlayingChanged:
            if (playing) outgoingMessageThemeEffect.play()
    }
    ThemeEffect {
        id: outgoingMessageThemeEffect
        effect: ThemeEffect.PressStrong
    }

    Connections {
        target: tdLibWrapper
        readonly property bool messagesNgf: appSettings.inAppChatMessagesNgf && Qt.application.state === Qt.ApplicationActive

        onNewMessageReceived:
            if (messagesNgf
                    && notificationManager.activeChatId === chatId && !tdLibWrapper.chatIsMuted(chatId)
                    && !message.is_outgoing && !message.sending_state)
                incomingMessageEffect.play()
        onMessageSendSucceeded:
            if (messagesNgf && (notificationManager.activeChatId === chatId || pageStack.currentPage.objectName == 'overviewPage'))
                outgoingMessageEffect.play()
    }


    Component.onCompleted: {
        Functions.setGlobals({
            tdLibWrapper: tdLibWrapper,
            appNotification: appNotification,
            utilities: utilities
        })
    }
}
