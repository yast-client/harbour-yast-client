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
    virtual void loadMessages(qlonglong fromMessageId = 0, int offset = 0) override;

protected:
    virtual inline void loadMoreHistoryImpl() override;
    virtual inline void loadMoreFutureImpl() override;
    virtual inline void loadHistoryForMessageImpl(qlonglong messageId) override;

private:
    qlonglong nextFromMessageId;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
};

#endif // MEDIAMESSAGESMODEL_H
