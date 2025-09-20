#ifndef INVERTEDMESSAGESMODEL_H
#define INVERTEDMESSAGESMODEL_H

#include "messagesmodel.h"

class InvertedMessagesModel : public MessagesModel {
    Q_OBJECT
public:
    explicit InvertedMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

protected:
    virtual void insertMessages(const QList<MessageData*> newMessages) override;
    inline virtual bool handleInsertMessages(const QVariantList &messages, QList<MessageData*> &newMessagesList, bool setAlbum = true, bool reverseOrder = true) override {
        return MessagesModel::handleInsertMessages(messages, newMessagesList, setAlbum, reverseOrder);
    }

protected slots:
    virtual void handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds) override;
};

#endif // INVERTEDMESSAGESMODEL_H
