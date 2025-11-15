#ifndef JUMPABLEMESSAGESMODEL_H
#define JUMPABLEMESSAGESMODEL_H

#include "messagesmodel.h"

class JumpableMessagesModel : public MessagesModel {
    Q_OBJECT

    Q_PROPERTY(bool endReached MEMBER endReached NOTIFY endReachedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit JumpableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) = 0;

    Q_INVOKABLE virtual int calculateScrollPosition();

    Q_INVOKABLE void loadMoreHistory();
    Q_INVOKABLE void loadMoreFuture();
    Q_INVOKABLE void loadHistoryForMessage(qlonglong messageId);

signals:
    void messagesReceived(int totalCount, bool fromIncrementalUpdate);
    void endReachedChanged();
    void loadingChanged();

protected slots:
    void handleMessagesReceived(const QVariantList &messages, int totalCount);

protected:
    enum UpdateType {
        UpdateNone,
        UpdatePreviousSlice,
        UpdateNextSlice,
        UpdateReload
    };

    virtual bool loading() const;

    inline bool waitingForSlice() const { return waitingFor == UpdatePreviousSlice || waitingFor == UpdateNextSlice; }
    virtual inline bool canLoadMoreMessages() const { return true; }

    virtual void loadMoreHistoryImpl() = 0;
    virtual void loadMoreFutureImpl() = 0;
    virtual void loadHistoryForMessageImpl(qlonglong messageId) = 0;

    virtual void updateStartEndReached(int totalCount, UpdateType fromUpdate);

protected:
    UpdateType waitingFor; // if we are waiting for messages after sending a request to load more of them
    bool startReached, endReached;
    qlonglong highlightedMessageId;
};

#endif // JUMPABLEMESSAGESMODEL_H
