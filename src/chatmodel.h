#ifndef CHATMODEL_H
#define CHATMODEL_H

#include "messagesmodel.h"

class ChatModel : public MessagesModel {
    Q_OBJECT
    Q_PROPERTY(QVariantMap smallPhoto READ smallPhoto NOTIFY smallPhotoChanged)
    Q_PROPERTY(QVariantMap chatActionsByUsers MEMBER chatActionsByUsers NOTIFY chatActionsChanged)
    Q_PROPERTY(QVariantMap chatActionsByChats MEMBER chatActionsByChats NOTIFY chatActionsChanged)

public:
    ChatModel(TDLibWrapper *tdLibWrapper);

    Q_INVOKABLE virtual void clear() override;
    Q_INVOKABLE virtual void reset() override;
    Q_INVOKABLE void initialize(const QVariantMap &chatInformation, qlonglong fromMessageId = 0);
    Q_INVOKABLE void setSearchQuery(const QString newSearchQuery);

    QVariantMap smallPhoto() const;

signals:
    void smallPhotoChanged();
    void pinnedMessageChanged();
    void chatActionsChanged();
    void notificationSettingsUpdated();

private slots:
    void handleChatPhotoUpdated(qlonglong chatId, const QVariantMap &photo);
    void handleChatPinnedMessageUpdated(qlonglong chatId, qlonglong pinnedMessageId);
    void handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &chatAction, qlonglong messageThreadId);
    void handleChatNotificationSettingsUpdated(const QString &chatId, const QVariantMap &chatNotificationSettings);

protected:
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) override;
    virtual inline bool canLoadMoreMessages() const override { return searchQuery.isEmpty(); }

private:
    QString searchQuery;

    QVariantMap chatActionsByUsers; // QMap<qlonglong, QString>
    QVariantMap chatActionsByChats; //QMap<qlonglong, QString>
};

#endif // CHATMODEL_H
