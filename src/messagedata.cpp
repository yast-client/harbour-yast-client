#include "messagedata.h"

#define DEBUG_MODULE MessageData
#include "debuglog.h"

namespace {
    const QString CONTENT("content");
    const QString CHAT_ID("chat_id");
    const QString SENDER_ID("sender_id");
    const QString USER_ID("user_id");
    const QString REPLY_MARKUP("reply_markup");
    const QString _TYPE("@type");

    // "interaction_info": {
    //     "@type": "messageInteractionInfo",
    //     "forward_count": 0,
    //     "view_count": 47
    // }
    const QString INTERACTION_INFO("interaction_info");
    const QString VIEW_COUNT("view_count");
    const QString REACTIONS("reactions");

    const QString TYPE_SPONSORED_MESSAGE("sponsoredMessage");
}

MessageData::MessageData(const QVariantMap &data, qlonglong msgid) :
    messageData(data),
    messageId(msgid),
    messageType(data.value(_TYPE).toString()),
    messageContentType(data.value(CONTENT).toMap().value(_TYPE).toString()),
    viewCount(data.value(INTERACTION_INFO).toMap().value(VIEW_COUNT).toInt()),
    reactions(data.value(INTERACTION_INFO).toMap().value(REACTIONS).toMap().value(REACTIONS).toList()),
    albumEntryFilter(false),
    albumMessageIds(QVariantList())
{}

QVector<int> MessageData::flagsToRoles(uint flags) {
    QVector<int> roles;
    if (flags & RoleFlagDisplay) {
        roles.append(RoleDisplay);
    }
    if (flags & RoleFlagMessageId) {
        roles.append(RoleMessageId);
    }
    if (flags & RoleFlagMessageContentType) {
        roles.append(RoleMessageContentType);
    }
    if (flags & RoleFlagMessageViewCount) {
        roles.append(RoleMessageViewCount);
    }
    if (flags & RoleFlagMessageReactions) {
        roles.append(RoleMessageReactions);
    }
    if (flags & RoleFlagMessageAlbumEntryFilter) {
        roles.append(RoleMessageAlbumEntryFilter);
    }
    if (flags & RoleFlagMessageAlbumMessageIds) {
        roles.append(RoleMessageAlbumMessageIds);
    }
    return roles;
}

int MessageData::senderUserId() const {
    return messageData.value(SENDER_ID).toMap().value(USER_ID).toInt();
}

qlonglong MessageData::senderChatId() const {
    return messageData.value(SENDER_ID).toMap().value(CHAT_ID).toLongLong();
}

bool MessageData::senderIsChat() const {
    return messageData.value(SENDER_ID).toMap().value(_TYPE).toString() == "messageSenderChat";
}

QVector<int> MessageData::diff(const MessageData *message) const {
    QVector<int> roles;
    if (message != this) {
        roles.append(RoleDisplay);
        if (message->messageId != messageId) {
            roles.append(RoleMessageId);
        }
        if (message->messageContentType != messageContentType) {
            roles.append(RoleMessageContentType);
        }
        if (message->viewCount != viewCount) {
            roles.append(RoleMessageViewCount);
        }
        if (message->reactions != reactions) {
            roles.append(RoleMessageReactions);
        }
        if (message->albumEntryFilter != albumEntryFilter) {
            roles.append(RoleMessageAlbumEntryFilter);
        }
        if (message->albumMessageIds != albumMessageIds) {
            roles.append(RoleMessageAlbumMessageIds);
        }
    }
    return roles;
}

uint MessageData::updateMessageData(const QVariantMap &data) {
    messageData = data;
    messageType = data.value(_TYPE).toString();
    return RoleFlagDisplay |
        updateContentType(data.value(CONTENT).toMap()) |
        updateInteractionInfo(data.value(INTERACTION_INFO).toMap());
}

QVector<int> MessageData::setMessageData(const QVariantMap &data) {
    return flagsToRoles(updateMessageData(data));
}

uint MessageData::updateContentType(const QVariantMap &content) {
    const QString oldContentType(messageContentType);
    messageContentType = content.value(_TYPE).toString();
    return (oldContentType == messageContentType) ? 0 : RoleFlagMessageContentType;
}

uint MessageData::updateContent(const QVariantMap &content) {
    messageData.insert(CONTENT, content);
    return RoleFlagDisplay | updateContentType(content);
}

QVector<int> MessageData::setContent(const QVariantMap &content) {
    return flagsToRoles(updateContent(content));
}

uint MessageData::updateReplyMarkup(const QVariantMap &replyMarkup) {
    messageData.insert(REPLY_MARKUP, replyMarkup);
    return RoleFlagDisplay;
}

QVector<int> MessageData::setReplyMarkup(const QVariantMap &replyMarkup) {
    return flagsToRoles(updateReplyMarkup(replyMarkup));
}

uint MessageData::updateViewCount(const QVariantMap &interactionInfo) {
    const int oldViewCount = viewCount;
    viewCount = interactionInfo.value(VIEW_COUNT).toInt();
    return (viewCount == oldViewCount) ? 0 : RoleFlagMessageViewCount;
}

uint MessageData::updateInteractionInfo(const QVariantMap &interactionInfo) {
    messageData.insert(INTERACTION_INFO, interactionInfo);
    return RoleFlagDisplay | updateViewCount(interactionInfo) | updateReactions(interactionInfo);
}

uint MessageData::updateReactions(const QVariantMap &interactionInfo) {
    LOG("Updating reactions...");
    const QVariantList oldReactions = reactions;
    reactions = interactionInfo.value(REACTIONS).toMap().value(REACTIONS).toList();
    return (reactions == oldReactions) ? 0 : RoleFlagMessageReactions;
}

uint MessageData::updateAlbumEntryFilter(const bool isAlbumChild) {
    LOG("Updating album filter... for id " << messageId << " value:" << isAlbumChild << "previously" << albumEntryFilter);
    const bool oldAlbumFiltered = albumEntryFilter;
    albumEntryFilter = isAlbumChild;
    return (isAlbumChild == oldAlbumFiltered) ? 0 : RoleFlagMessageAlbumEntryFilter;
}


QVector<int> MessageData::setAlbumEntryFilter(bool isAlbumChild) {
    LOG("setAlbumEntryFilter");
    return flagsToRoles(updateAlbumEntryFilter(isAlbumChild));
}

uint MessageData::updateAlbumEntryMessageIds(const QVariantList &newAlbumMessageIds) {
    LOG("Updating albumMessageIds... id" << messageId);
    LOG("  Updating albumMessageIds..." << newAlbumMessageIds << "previously" << albumMessageIds << "same?" << (newAlbumMessageIds == albumMessageIds));
    const QVariantList oldAlbumMessageIds = albumMessageIds;
    albumMessageIds = newAlbumMessageIds;

    LOG("  Updating albumMessageIds... same again?" << (newAlbumMessageIds == oldAlbumMessageIds));
    return (newAlbumMessageIds == oldAlbumMessageIds) ? 0 : RoleFlagMessageAlbumMessageIds;
}

QVector<int> MessageData::setAlbumEntryMessageIds(const QVariantList &newAlbumMessageIds) {
    return flagsToRoles(updateAlbumEntryMessageIds(newAlbumMessageIds));
}

QVector<int> MessageData::setInteractionInfo(const QVariantMap &info) {
    return flagsToRoles(updateInteractionInfo(info));
}


bool MessageData::lessThan(const MessageData *message1, const MessageData *message2) {
    bool message1Sponsored = message1->messageType == TYPE_SPONSORED_MESSAGE;
    bool message2Sponsored = message2->messageType == TYPE_SPONSORED_MESSAGE;
    if (message1Sponsored != message2Sponsored)
        // sponsored messages are considered more than normal messages
        return !message1Sponsored && message2Sponsored;

    return message1->messageId < message2->messageId;
}
