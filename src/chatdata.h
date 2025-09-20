#ifndef CHATDATA_H
#define CHATDATA_H

#include <QObject>
#include "tdlibwrapper.h"

class ChatData {
public:
    enum Role {
        RoleDisplay = Qt::DisplayRole,
        RoleChatId,
        RoleChatType,
        RoleGroupId,
        RoleTitle,
        RolePhotoSmall,
        RoleUnreadCount,
        RoleUnreadMentionCount,
        RoleUnreadReactionCount,
        RoleAvailableReactions,
        RoleLastReadInboxMessageId,
        RoleLastMessageSenderId,
        RoleLastMessageDate,
        RoleLastMessageText,
        RoleLastMessageStatus,
        RoleChatMemberStatus,
        RoleSecretChatState,
        RoleVerificationStatus,
        RoleIsChannel,
        RoleIsMarkedAsUnread,
        RoleIsPinned,
        RoleFilter,
        RoleDraftMessageText,
        RoleDraftMessageDate
    };

    ChatData(TDLibWrapper *tdLibWrapper, Utilities *utilities, const QVariantMap &data);
    ChatData(TDLibWrapper *tdLibWrapper, Utilities *utilities, qlonglong chatId);

    const QVariantMap lastMessage() const;
    const QVariant lastMessage(const QString &key) const;
    QString title() const;
    int unreadCount() const;
    int unreadMentionCount() const;
    int unreadReactionCount() const;
    QVariant availableReactions() const;
    QVariant photoSmall() const;
    qlonglong lastReadInboxMessageId() const;
    qlonglong senderUserId() const;
    qlonglong senderChatId() const;
    bool senderIsChat() const;
    qlonglong senderMessageDate() const;
    QString senderMessageText() const;
    QString senderMessageStatus() const;
    qlonglong draftMessageDate() const;
    QString draftMessageText() const;
    bool isChannel() const;
    bool isMarkedAsUnread() const;
    bool updateUnreadCount(int unreadCount);
    bool updateLastReadInboxMessageId(qlonglong messageId);
    QVector<int> updateLastMessage(const QVariantMap &message);
    QVector<int> updateGroup(const TDLibWrapper::Group *group);
    QVector<int> updateSecretChat(const QVariantMap &secretChatDetails);
    TDLibWrapper *tdLibWrapper;
    Utilities *utilities;

public:
    QVariantMap chatData;
    qlonglong chatId;
    qlonglong groupId;
    QVariantMap verificationStatus;
    TDLibWrapper::ChatType chatType;
    TDLibWrapper::ChatMemberStatus memberStatus;
    TDLibWrapper::SecretChatState secretChatState;
};

#endif // CHATDATA_H
