#ifndef READABLEMESSAGESMODEL_H
#define READABLEMESSAGESMODEL_H

#include "jumpablemessagesmodel.h"

class ReadableMessagesModel : public JumpableMessagesModel {
    Q_OBJECT
    Q_PROPERTY(int lastReadMessageIndexInBounds READ calculateLastReadMessageIndexInBounds NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(int lastReadIncomingMessageIndex READ getLastReadMessageIndex NOTIFY lastReadMessageIndexChanged)

    Q_PROPERTY(int lastReadSentMessageIndex READ calculateLastReadSentMessageIndex NOTIFY lastReadSentMessageUpdated)
    Q_PROPERTY(bool historyEndLoaded READ isMostRecentMessageLoaded NOTIFY historyEndLoadedChanged)

public:
    ReadableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE virtual bool isMostRecentMessageLoaded() override;

    Q_INVOKABLE void loadEnd(bool markAllAsRead = false);

    Q_INVOKABLE int calculateScrollPosition();

signals:
    void newMessageReceived(const QVariantMap &message);
    void unreadCountUpdated(int unreadCount, const QString &lastReadInboxMessageId);

    void lastReadSentMessageUpdated();
    void historyEndLoadedChanged();
    void lastReadMessageIndexChanged();

private slots:
    void handleFoundChatMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int totalCount, qlonglong /*nextFromMessageId*/);
    void handleSponsoredMessageReceived(qlonglong chatId, const QVariantMap &sponsoredMessage);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);

protected:
    int calculateLastReadMessageIndexInBounds();

    int getLastReadMessageIndex();
    int calculateLastReadSentMessageIndex();

    virtual inline void loadMoreHistoryImpl() override;
    virtual inline void loadMoreFutureImpl() override;
    virtual inline void loadHistoryForMessageImpl(qlonglong messageId) override;

    virtual qlonglong lastReadInboxMessageId() const = 0;
    virtual qlonglong lastReadOutboxMessageId() const = 0;
    virtual qlonglong lastMessageId() const = 0; // FIXME: this is wrong and shouldn't be used ideally

protected:
    bool loadingFullEnd;
};

#endif // READABLEMESSAGESMODEL_H
