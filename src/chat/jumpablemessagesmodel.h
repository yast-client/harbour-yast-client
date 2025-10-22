#ifndef JUMPABLEMESSAGESMODEL_H
#define JUMPABLEMESSAGESMODEL_H

#include "messagesmodel.h"

class JumpableMessagesModel : public MessagesModel {
    Q_OBJECT
public:
    explicit JumpableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE virtual bool isMostRecentMessageLoaded();
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) = 0;

    Q_INVOKABLE void triggerLoadMoreHistory();
    Q_INVOKABLE void triggerLoadMoreFuture();
    Q_INVOKABLE void triggerLoadHistoryForMessage(qlonglong messageId);

signals:
    void messagesReceived(int totalCount, bool fromIncrementalUpdate);

protected slots:
    void handleMessagesReceived(const QVariantList &messages, int totalCount);

protected:
    virtual inline bool canLoadMoreMessages() const { return true; }

    virtual void loadMoreHistoryImpl() = 0;
    virtual void loadMoreFutureImpl() = 0;
    virtual void loadHistoryForMessageImpl(qlonglong messageId) = 0;

protected:
    qlonglong highlightedMessageId;
    bool inReload;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
};

#endif // JUMPABLEMESSAGESMODEL_H
