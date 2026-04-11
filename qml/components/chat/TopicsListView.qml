import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import ".."
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug

Item {
    property bool loading: true
    property bool inCooldown

    Timer {
        id: resetCooldownTimer
        interval: 2000
        onTriggered: {
            Debug.log("[ChatPendingJoinRequestsPage] Cooldown completed")
            inCooldown = false
        }
    }

    Connections {
        target: chatManager.topicsModel
        ignoreUnknownSignals: true
        onForumTopicsReceived: {
            loading = false
            resetCooldownTimer.restart()
        }
    }

    SilicaListView {
        id: view
        anchors.fill: parent
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

        delegate: PhotoTextsListItem {
            width: parent.width

            property bool showDraft: !!draft_message_text && draft_message_date > last_message_date
            property string previewText: showDraft ? draft_message_text : last_message_text

            primaryText.text: name
            prologSecondaryText.text: showDraft ? "<i>"+qsTr("Draft")+"</i>" : (last_message_sender_id ? (last_message_sender_id !== tdLibWrapper.myUserId ? Emoji.emojify(utilities.getUserName(tdLibWrapper.getUserInformation(last_message_sender_id)), Theme.fontSizeExtraSmall) : qsTr("You")) : "")
            secondaryText.text: previewText ? Emoji.emojify(utilities.fixReservedHtmlCharacters(previewText), Theme.fontSizeExtraSmall) : "<i>" + qsTr("This topic was created") + "</i>"
            minithumbnail: showDraft ? null : last_message_minithumbnail
            tertiaryText.text: showDraft ? Functions.getDateTimeElapsed(draft_message_date) : (last_message_date ? (last_message_date.length === 0 ? "" : Functions.getDateTimeElapsed(last_message_date) + Emoji.emojify(last_message_status, tertiaryText.font.pixelSize)) : "")

            unreadCount: unread_count
            unreadReactionCount: unread_reaction_count
            unreadMentionCount: unread_mention_count
            isPinned: is_pinned
            muted: notification_settings.mute_for > 0

            onClicked: pageStack.push(topicMessagesPage, {chatId: chatInformation.id, forumTopicData: display})
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
                property alias chatId: topicMessagesModel.chatId
                property alias forumTopicData: topicMessagesModel.forumTopicData

                SilicaFlickable {
                    anchors.fill: parent

                    ChatHeader {
                        id: chatHeader
                        chatNameText.text: topicMessagesModel.forumTopicName
                        // TODO: icon, and status text (%n messages and typing)
                    }

                    MessagesView {
                        width: parent.width
                        anchors {
                            top: chatHeader.bottom
                            bottom: parent.bottom
                        }

                        messagesModel: topicMessagesModel
                        topicId: {'@type': 'messageTopicForum', 'forum_topic_id': topicMessagesModel.forumTopicId}
                        forumTopicName: topicMessagesModel.forumTopicName
                        messageSource: TDLibAPI.MessageSourceForumTopicHistory
                        draftMessage: forumTopicData.draft_message
                        unreadCount: forumTopicData.unread_count

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
