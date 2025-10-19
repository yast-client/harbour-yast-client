#ifndef READABLEMESSAGESMODEL_H
#define READABLEMESSAGESMODEL_H

// FIXME: why is chat/ prefix needed here?..
#include "chat/messagesmodel.h"

class ReadableMessagesModel : public MessagesModel {
    Q_OBJECT
    Q_PROPERTY(int lastReadMessageIndexInBounds READ calculateLastReadMessageIndexInBounds NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(int lastReadIncomingMessageIndex READ getLastReadMessageIndex NOTIFY lastReadMessageIndexChanged)

    Q_PROPERTY(int lastReadSentMessageIndex READ calculateLastReadSentMessageIndex NOTIFY lastReadSentMessageUpdated)
    Q_PROPERTY(bool historyEndLoaded READ isMostRecentMessageLoaded NOTIFY historyEndLoadedChanged)

public:
    ReadableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE bool isMostRecentMessageLoaded();

    Q_INVOKABLE void triggerLoadMoreHistory();
    Q_INVOKABLE void triggerLoadMoreFuture();
    Q_INVOKABLE void triggerLoadHistoryForMessage(qlonglong messageId);
    Q_INVOKABLE void loadEnd(bool markAllAsRead = false);

    Q_INVOKABLE int calculateScrollPosition();

signals:
    void messagesReceived(int totalCount, bool fromIncrementalUpdate);
    void newMessageReceived(const QVariantMap &message);
    void unreadCountUpdated(int unreadCount, const QString &lastReadInboxMessageId);

    void lastReadSentMessageUpdated();
    void historyEndLoadedChanged();
    void lastReadMessageIndexChanged();

private slots:
    void handleMessagesReceived(const QVariantList &messages, int totalCount);
    void handleFoundChatMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int totalCount, qlonglong /*nextFromMessageId*/);
    void handleSponsoredMessageReceived(qlonglong chatId, const QVariantMap &sponsoredMessage);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);

protected:
    int calculateLastReadMessageIndexInBounds();

    int getLastReadMessageIndex();
    int calculateLastReadSentMessageIndex();

    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) = 0;
    virtual inline bool canLoadMoreMessages() const { return true; }

    virtual qlonglong lastReadInboxMessageId() const = 0;
    virtual qlonglong lastReadOutboxMessageId() const = 0;
    virtual qlonglong lastMessageId() const = 0; // FIXME: this is wrong and shouldn't be used ideally

protected:
    qlonglong highlightedMessageId;
    bool inReload;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
    bool loadingFullEnd;
};

#endif // READABLEMESSAGESMODEL_H
