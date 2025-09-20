#ifndef MEDIAMESSAGESMODEL_H
#define MEDIAMESSAGESMODEL_H

#include "invertedmessagesmodel.h"

class MediaMessagesModel : public InvertedMessagesModel {
    Q_OBJECT
public:
    MediaMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE void init(qlonglong chatId);
    Q_INVOKABLE void triggerLoadMoreHistory();

private slots:
    void handleMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int /*totalCount*/, qlonglong nextFromMessageId);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);

private:
    void loadMessages(qlonglong fromMessageId = 0);

private:
    qlonglong nextFromMessageId;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
};

#endif // MEDIAMESSAGESMODEL_H
