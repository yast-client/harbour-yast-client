#ifndef CHATMODEL_H
#define CHATMODEL_H

#include "readablemessagesmodel.h"
#include "mediamessagesmodel.h"

class ChatModel : public ReadableMessagesModel {
    Q_OBJECT
    Q_PROPERTY(QVariantMap chatInformation MEMBER chatInformation)
    Q_PROPERTY(QVariantMap smallPhoto READ smallPhoto NOTIFY smallPhotoChanged)
    Q_PROPERTY(QVariantMap chatActionsByUsers MEMBER chatActionsByUsers NOTIFY chatActionsChanged)
    Q_PROPERTY(QVariantMap chatActionsByChats MEMBER chatActionsByChats NOTIFY chatActionsChanged)
    Q_PROPERTY(MediaMessagesModel* mediaMessagesModel MEMBER mediaMessagesModel)

public:
    ChatModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE virtual void reset() override;
    Q_INVOKABLE void initialize(const QVariantMap &chatInformation, qlonglong fromMessageId = 0);
    Q_INVOKABLE void setSearchQuery(const QString newSearchQuery);
    Q_INVOKABLE void initializeMediaMessagesModel();

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
    void handleChatLastMessageUpdated(qlonglong id, const QVariant &/*order*/, const QVariantMap &lastMessage);
    void handleChatReadInboxUpdated(const QString &chatId, const QString &lastReadInboxMessageId, int unreadCount);
    void handleChatReadOutboxUpdated(const QString &chatId, const QString &lastReadOutboxMessageId);

protected:
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) override;
    virtual inline bool canLoadMoreMessages() const override { return searchQuery.isEmpty(); }

    virtual qlonglong lastReadInboxMessageId() const override;
    virtual qlonglong lastReadOutboxMessageId() const override;
    virtual qlonglong lastMessageId() const override; // FIXME: this is wrong and shouldn't be used ideally

private:
    QVariantMap chatInformation;
    QString searchQuery;

    MediaMessagesModel* mediaMessagesModel;

    QVariantMap chatActionsByUsers; // QMap<qlonglong, QString>
    QVariantMap chatActionsByChats; //QMap<qlonglong, QString>
};

#endif // CHATMODEL_H
