#ifndef MEDIAMESSAGESMODEL_H
#define MEDIAMESSAGESMODEL_H

#include "jumpablemessagesmodel.h"

class MediaMessagesModel : public JumpableMessagesModel {
    Q_OBJECT
public:
    MediaMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE void init(qlonglong chatId, qlonglong fromMessageId = 0);

private slots:
    void handleMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int totalCount, qlonglong nextFromMessageId);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);

private:
    inline virtual void loadMessages(qlonglong fromMessageId = 0, int offset = 0) override { loadMessagesWithLimit(fromMessageId, offset); }
    void loadMessagesWithLimit(qlonglong fromMessageId = 0, int offset = 0, int limit = 100);

protected:
    virtual void loadMoreHistoryImpl() override;
    virtual void loadMoreFutureImpl() override;
    virtual void loadHistoryForMessageImpl(qlonglong messageId) override;

private:
    qlonglong nextFromMessageId;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
};

#endif // MEDIAMESSAGESMODEL_H
