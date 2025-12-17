#include "chatdata.h"

#include "chatlistmodel.h"

#define DEBUG_MODULE ChatData
#include "debuglog.h"

namespace {
    const QString ID("id");
    const QString DATE("date");
    const QString TEXT("text");
    const QString TYPE("type");
    const QString TITLE("title");
    const QString PHOTO("photo");
    const QString SMALL("small");
    const QString ORDER("order");
    const QString CHAT_ID("chat_id");
    const QString CONTENT("content");
    const QString LAST_MESSAGE("last_message");
    const QString DRAFT_MESSAGE("draft_message");
    const QString SENDER_ID("sender_id");
    const QString USER_ID("user_id");
    const QString BASIC_GROUP_ID("basic_group_id");
    const QString SUPERGROUP_ID("supergroup_id");
    const QString UNREAD_COUNT("unread_count");
    const QString UNREAD_MENTION_COUNT("unread_mention_count");
    const QString UNREAD_REACTION_COUNT("unread_reaction_count");
    const QString AVAILABLE_REACTIONS("available_reactions");
    const QString NOTIFICATION_SETTINGS("notification_settings");
    const QString LAST_READ_INBOX_MESSAGE_ID("last_read_inbox_message_id");
    const QString LAST_READ_OUTBOX_MESSAGE_ID("last_read_outbox_message_id");
    const QString SENDING_STATE("sending_state");
    const QString IS_CHANNEL("is_channel");
    const QString VERIFICATION_STATUS("verification_status");
    const QString IS_MARKED_AS_UNREAD("is_marked_as_unread");
    const QString PINNED_MESSAGE_ID("pinned_message_id");
    const QString _TYPE("@type");
    const QString SECRET_CHAT_ID("secret_chat_id");
    const QString UNREAD_UNMUTED_COUNT("unread_unmuted_count");
}

ChatData::ChatData(TDLibWrapper *tdLibWrapper, Utilities *utilities, const QVariantMap &data) :
    tdLibWrapper(tdLibWrapper),
    utilities(utilities),
    chatId(data.value(ID).toLongLong()),
    groupId(0),
    memberStatus(TDLibWrapper::ChatMemberStatusUnknown),
    secretChatState(TDLibWrapper::SecretChatStateUnknown)
{
    this->updateChatData(data);
}

ChatData::ChatData(TDLibWrapper *tdLibWrapper, Utilities *utilities, qlonglong chatId) :
    tdLibWrapper(tdLibWrapper),
    utilities(utilities),
    chatData(),
    chatId(chatId),
    groupId(0),
    memberStatus(TDLibWrapper::ChatMemberStatusUnknown),
    secretChatState(TDLibWrapper::SecretChatStateUnknown)
{}

void ChatData::updateChatData(const QVariantMap &data) {
    this->chatData = data;

    const QVariantMap type(data.value(TYPE).toMap());
    switch (chatType = TDLibWrapper::chatTypeFromString(type.value(_TYPE).toString())) {
    case TDLibWrapper::ChatTypeBasicGroup:
        groupId = type.value(BASIC_GROUP_ID).toLongLong();
        break;
    case TDLibWrapper::ChatTypeSupergroup:
        groupId = type.value(SUPERGROUP_ID).toLongLong();
        break;
    case TDLibWrapper::ChatTypeUnknown:
    case TDLibWrapper::ChatTypePrivate:
        break;
    case TDLibWrapper::ChatTypeSecret:
        QVariantMap secretChatDetails = tdLibWrapper->getSecretChatFromCache(data.value(TYPE).toMap().value(SECRET_CHAT_ID).toLongLong());
        if (!secretChatDetails.isEmpty())
            this->updateSecretChat(secretChatDetails);
        break;
    }

    if (groupId != 0) {
        const TDLibWrapper::Group *group = tdLibWrapper->getGroup(this->groupId);
        if (group)
            this->updateGroup(group);
    }
}

inline const QVariantMap ChatData::lastMessage() const {
    return chatData.value(LAST_MESSAGE).toMap();
}
inline const QVariant ChatData::lastMessage(const QString &key) const {
    return lastMessage().value(key);
}

QString ChatData::title() const
{
    return chatData.value(TITLE).toString();
}

int ChatData::unreadCount() const
{
    return chatData.value(UNREAD_COUNT).toInt();
}

int ChatData::unreadMentionCount() const
{
    return chatData.value(UNREAD_MENTION_COUNT).toInt();
}

QVariant ChatData::availableReactions() const
{
    return chatData.value(AVAILABLE_REACTIONS);
}

int ChatData::unreadReactionCount() const
{
    return chatData.value(UNREAD_REACTION_COUNT).toInt();
}

QVariant ChatData::photoSmall() const
{
    return chatData.value(PHOTO).toMap().value(SMALL);
}

qlonglong ChatData::lastReadInboxMessageId() const
{
    return chatData.value(LAST_READ_INBOX_MESSAGE_ID).toLongLong();
}

qlonglong ChatData::senderUserId() const
{
    return lastMessage(SENDER_ID).toMap().value(USER_ID).toLongLong();
}

qlonglong ChatData::senderChatId() const
{
    return lastMessage(SENDER_ID).toMap().value(CHAT_ID).toLongLong();
}

bool ChatData::senderIsChat() const
{
    return lastMessage(SENDER_ID).toMap().value(_TYPE).toString() == "messageSenderChat";
}

qlonglong ChatData::senderMessageDate() const
{
    return lastMessage(DATE).toLongLong();
}

QString ChatData::senderMessageText() const {
    return utilities->getMessageText(lastMessage(), Utilities::MessageTextSimpleWithThumbnails);
}

QVariant ChatData::senderMessageMinithumbnail() const {
    return utilities->getMessageMinithumbnail(lastMessage(CONTENT).toMap());
}

bool ChatData::senderMessageIsService() const {
    return Utilities::messageContentIsService(lastMessage(CONTENT).toMap().value(_TYPE).toString());
}


QString ChatData::senderMessageStatus() const
{
    qlonglong myUserId = tdLibWrapper->getUserInformation().value(ID).toLongLong();
    if (isChannel() || myUserId != senderUserId() || myUserId == chatId) {
        return "";
    }
    if (lastMessage(ID) == chatData.value(LAST_READ_OUTBOX_MESSAGE_ID)) {
        return "&nbsp;&nbsp;✅";
    } else {
        QVariantMap lastMessage = chatData.value(LAST_MESSAGE).toMap();
        if (lastMessage.contains(SENDING_STATE)) {
            QVariantMap sendingState = lastMessage.value(SENDING_STATE).toMap();
            if (sendingState.value(_TYPE).toString() == "messageSendingStatePending") {
                return "&nbsp;&nbsp;🕙";
            } else {
                return "&nbsp;&nbsp;❌";
            }
        } else {
            return "&nbsp;&nbsp;☑️";
        }
    }
}
qlonglong ChatData::draftMessageDate() const
{
    QVariantMap draft = chatData.value(DRAFT_MESSAGE).toMap();
    if(draft.isEmpty()) {
        return qlonglong(0);
    }
    return draft.value(DATE).toLongLong();
}

QString ChatData::draftMessageText() const
{
    QVariantMap draft = chatData.value(DRAFT_MESSAGE).toMap();
    if(draft.isEmpty()) {
        return QString();
    }
    return draft.value("input_message_text").toMap().value(TEXT).toMap().value(TEXT).toString();
}

bool ChatData::isChannel() const
{
    return chatData.value(TYPE).toMap().value(IS_CHANNEL).toBool();
}

bool ChatData::isMarkedAsUnread() const
{
    return chatData.value(IS_MARKED_AS_UNREAD).toBool();
}

bool ChatData::updateUnreadCount(int count)
{
    const int prevUnreadCount(unreadCount());
    chatData.insert(UNREAD_COUNT, count);
    return prevUnreadCount != unreadCount();
}

bool ChatData::updateLastReadInboxMessageId(qlonglong messageId)
{
    const qlonglong prevLastReadInboxMessageId(lastReadInboxMessageId());
    chatData.insert(LAST_READ_INBOX_MESSAGE_ID, messageId);
    return prevLastReadInboxMessageId != lastReadInboxMessageId();
}

QVector<int> ChatData::updateLastMessage(const QVariantMap &message) {
    const qlonglong prevSenderUserId(senderUserId());
    const qlonglong prevSenderMessageDate(senderMessageDate());
    const QString prevSenderMessageText(senderMessageText());
    const QVariant prevSenderMessageMinithumbnail(senderMessageMinithumbnail());
    const bool prevSenderMessageIsService(senderMessageIsService());
    const QString prevSenderMessageStatus(senderMessageStatus());


    chatData.insert(LAST_MESSAGE, message);

    QVector<int> changedRoles;
    changedRoles.append(ChatData::RoleDisplay);
    if (prevSenderUserId != senderUserId()) {
        changedRoles.append(ChatData::RoleLastMessageSenderId);
    }
    if (prevSenderMessageDate != senderMessageDate()) {
        changedRoles.append(ChatData::RoleLastMessageDate);
    }
    if (prevSenderMessageText != senderMessageText()) {
        changedRoles.append(ChatData::RoleFilter);
        changedRoles.append(ChatData::RoleLastMessageText);
    }
    if (prevSenderMessageMinithumbnail != senderMessageMinithumbnail()) {
        changedRoles.append(ChatData::RoleLastMessageMinithumbnail);
    }
    if (prevSenderMessageIsService != senderMessageIsService()) {
        changedRoles.append(ChatData::RoleLastMessageIsService);
    }
    if (prevSenderMessageStatus != senderMessageStatus()) {
        changedRoles.append(ChatData::RoleLastMessageStatus);
    }
    return changedRoles;
}

QVector<int> ChatData::updateGroup(const TDLibWrapper::Group *group)
{
    QVector<int> changedRoles;

    if (group && this->groupId == group->groupId) {
        LOG("Updating group information for chat" << this->chatId << this->groupId);
        const TDLibWrapper::ChatMemberStatus memberStatus = group->chatMemberStatus();
        if (this->memberStatus != memberStatus) {
            this->memberStatus = memberStatus;
            changedRoles.append(ChatData::RoleChatMemberStatus);
        }
        const QVariantMap verificationStatus = group->groupInfo.value(VERIFICATION_STATUS).toMap();
        if (this->verificationStatus != verificationStatus) {
            this->verificationStatus = verificationStatus;
            changedRoles.append(ChatData::RoleVerificationStatus);
        }
    }
    return changedRoles;
}

QVector<int> ChatData::updateSecretChat(const QVariantMap &secretChatDetails)
{
    QVector<int> changedRoles;

    TDLibWrapper::SecretChatState newSecretChatState = TDLibWrapper::secretChatStateFromString(secretChatDetails.value("state").toMap().value(_TYPE).toString());
    if (newSecretChatState != secretChatState) {
        secretChatState = newSecretChatState;
        changedRoles.append(ChatData::RoleSecretChatState);
    }
    return changedRoles;
}
