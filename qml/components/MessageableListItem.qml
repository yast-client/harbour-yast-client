import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

import ".."
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

PhotoTextsListItem {
    property string titleText
    property bool hideDraft
    property bool showDraft: !!draft_message_text && draft_message_date > last_message_date && !hideDraft
    readonly property string draftText: '<i>'+qsTr("Draft")+'</i>'
    property bool hideAuthor
    property string previewText: showDraft ? draft_message_text : last_message_text
    property string noMessageText: qsTr("No message in this chat")
    property bool showSendingState: true
    property bool _showSendingState: showSendingState && last_message_is_outgoing && !showDraft

    primaryText.text: titleText ? Emoji.emojify(utilities.fixReservedHtmlCharacters(titleText), Theme.fontSizeMedium) : qsTr("Unknown")
    prologSecondaryText.text: showDraft ? draftText : hideAuthor ? ''
                                                                 : last_message_sender_id ?
                                                                        last_message_sender_id !== tdLibWrapper.myUserId
                                                                         ? Emoji.emojify(utilities.getUserName(tdLibWrapper.getUserInformation(last_message_sender_id)), Theme.fontSizeExtraSmall)
                                                                         : qsTr("You")
                                                                     : ''
    secondaryText.text: previewText ? Emoji.emojify(utilities.fixReservedHtmlCharacters(previewText), Theme.fontSizeExtraSmall) : '<i>' + noMessageText + '</i>'
    secondaryText.highlighted: listItem.highlighted || !!chat_actions_text
    minithumbnail: showDraft ? null : last_message_minithumbnail

    Binding {
        target: appSettings.compactChatList ? additionalPrimaryText : tertiaryText
        property: 'text'
        value: {
            var dateFormatter = appSettings.compactChatList ? Functions.getDateTimeTimepointRelative : Functions.getDateTimeElapsed

            if (showDraft)
                return dateFormatter(draft_message_date)
            if (!last_message_date)
                return ''

            var date = dateFormatter(last_message_date)
            if (appSettings.compactChatList || !_showSendingState)
                return date
            return date + Functions.formatMessageSendingState(last_message_id, last_read_outbox_message_id, last_message_sending_state, tertiaryText.font.pixelSize)
        }
    }
    Binding {
        target: appSettings.compactChatList ? tertiaryText : additionalPrimaryText
        property: 'text'
        value: ''
    }
    additionalPrimaryTextIcon.source: appSettings.compactChatList && _showSendingState
                                      ? Functions.getMessageSendingStateIcon(last_message_id, last_read_outbox_message_id, last_message_sending_state)
                                      : ''
    additionalPrimaryTextIcon.highlighted: last_read_outbox_message_id >= last_message_id

    unreadCount: unread_count
    unreadReactionCount: unread_reaction_count
    unreadMentionCount: unread_mention_count
    isPinned: is_pinned

    showSeparator: !appSettings.compactChatList
    contentHeight: appSettings.compactChatList ? Theme.itemSizeLarge + Theme.paddingMedium : Theme.itemSizeExtraLarge
        pictureThumbnailItem.height: appSettings.compactChatList ? Theme.iconSizeLarge : Theme.itemSizeLarge
}
