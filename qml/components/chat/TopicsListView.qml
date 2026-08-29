//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import ".."
import '../tdlib'
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug

Item {
    property bool loading: true
    property bool inCooldown

    property int forumTopicIdToShow

    property var forwardFromChatId
    property var forwardMessageIds
    property bool forwardSendCopy
    property bool forwardRemoveCaption

    function openAtTopicId(forumTopicId) {
        forumTopicIdToShow = forumTopicId
        tdLibWrapper.getForumTopic(chatId, forumTopicId)
    }

    Connections {
        target: tdLibWrapper
        onForumTopicReceived:
            if (chatPage.chatId === chatId && forumTopicIdToShow == forumTopicId) {
                pageStack.push(topicMessagesPage, {chatId: chatId, forumTopicData: topic})
                forumTopicIdToShow = 0
            }
        onForumTopicNotFound:
            if (chatPage.chatId === chatId && forumTopicIdToShow == forumTopicId) {
                appNotification.show(qsTr("Forum topic not found"))
                forumTopicIdToShow = 0
            }
    }

    Timer {
        id: resetCooldownTimer
        interval: 2000
        onTriggered: {
            Debug.log("[ChatPendingJoinRequestsPage] Cooldown completed")
            inCooldown = false
        }
    }

    Connections {
        target: tdLibWrapper
    }

    Connections {
        target: chatManager.topicsModel
        ignoreUnknownSignals: true
        onForumTopicsReceived: {
            loading = false
            resetCooldownTimer.restart()
        }
    }

    Loader {
        id: forwardHeaderLoader
        width: parent.width
        active: !!(forwardFromChatId || forwardMessageIds)
        sourceComponent: Component {
            PageHeader { title: qsTr("Forward to…") }
        }
    }

    Binding {
        target: chatHeader
        property: 'visible'
        value: !forwardHeaderLoader.active
    }

    SilicaListView {
        id: view
        width: parent.width
        anchors {
            top: forwardHeaderLoader.bottom
            bottom: parent.bottom
        }
        clip: true
        opacity: loading ? 0 : 1
        Behavior on opacity { FadeAnimator {} }

        model: chatManager.topicsModel

        ViewPlaceholder {
            anchors.fill: parent
            enabled: view.count === 0 // TODO: telegram for android shows this when there's only the general topic too, consider doing the same
            text: qsTr("No topics here yet")
            hintText: qsTr("Pull down to start the first topic or view the group as messages")
        }

        delegate: MessageableListItem {
            titleText: name
            noMessageText: qsTr("This topic was created")

            pictureThumbnail {
                replacementBackgroundColor: icon_color
                replacementImageFile: iconLoader.stickerData.thumbnail.file
                replacementIconSource: is_general ? 'image://theme/icon-m-chat' : ''
            }
            TDLibCustomEmojiStickerDataLoader {
                id: iconLoader
                customEmojiId: is_general ? null : icon_custom_emoji_id
            }

            muted: notification_settings.mute_for > 0 // TODO: use something like in ChatListViewItem

            onClicked: {
                var page = pageStack.push(topicMessagesPage, {chatId: chatId, forumTopicData: display})
                if (forwardHeaderLoader.active) {
                    page.messagesView.forwardMessages(forwardFromChatId, forwardMessageIds, forwardSendCopy, forwardRemoveCaption)
                    forwardFromChatId = forwardMessageIds = null
                }
            }
        }

        onContentYChanged: {
            if (inCooldown || count == 0) return

            var i = indexAt(contentX, contentY + height)
            if (i === -1 || i > Math.max(0, count - 10)) {
                Debug.log("[TopicsListView] Loading more")
                inCooldown = true
                chatManager.topicsModel.loadMore()
            }
        }

        Component {
            id: topicMessagesPage
            Page {
                allowedOrientations: Orientation.All

                property alias chatId: topicMessagesModel.chatId
                property alias forumTopicData: topicMessagesModel.forumTopicData

                property alias messagesView: messagesView

                SilicaFlickable {
                    anchors.fill: parent

                    ChatHeader {
                        id: chatHeader
                        chatNameText.text: topicMessagesModel.name

                        pictureThumbnail {
                            replacementBackgroundColor: topicMessagesModel.iconColor
                            replacementImageFile: iconLoader.stickerData.thumbnail.file
                            replacementIconSource: topicMessagesModel.isGeneral ? 'image://theme/icon-s-chat' : ''
                            replacementImageWidth: Theme.iconSizeSmall
                        }
                        TDLibCustomEmojiStickerDataLoader {
                            id: iconLoader
                            customEmojiId: topicMessagesModel.isGeneral ? null : topicMessagesModel.iconCustomEmojiId
                        }

                        // TODO: status text (%n messages and typing)
                    }

                    MessagesView {
                        id: messagesView
                        width: parent.width
                        anchors {
                            top: chatHeader.bottom
                            bottom: parent.bottom
                        }

                        messagesModel: topicMessagesModel
                        topicId: {'@type': 'messageTopicForum', 'forum_topic_id': topicMessagesModel.forumTopicId}
                        forumTopicName: topicMessagesModel.name
                        messageSource: TDLibAPI.MessageSourceForumTopicHistory
                        draftMessage: forumTopicData.draft_message
                        unreadCount: forumTopicData.unread_count
                        showPinnedMessage: false

                        ForumTopicMessagesModel {
                            id: topicMessagesModel
                            tdlib: tdLibWrapper
                        }

                        Component.onCompleted: prepareView()
                    }
                }
            }
        }
    }

    BusyLabel {
        running: loading
    }
}
