#ifndef CHATMANAGER_H
#define CHATMANAGER_H

#include "readablemessagesmodel.h"
#include "mediamessagesmodel.h"

class ChatMessagesModel : public ReadableMessagesModel {
    Q_OBJECT
public:
    ChatMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE virtual bool clear() override;
    Q_INVOKABLE void setSearchQuery(const QString newSearchQuery);

    friend class ChatManager;

protected:
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) override;
    virtual inline bool canLoadMoreMessages() const override { return searchQuery.isEmpty(); }

    virtual qlonglong lastReadInboxMessageId() const override;
    virtual qlonglong lastReadOutboxMessageId() const override;
    virtual qlonglong lastMessageId() const override; // FIXME: this is (might be) wrong and shouldn't be used ideally

private:
    QString searchQuery;
};

class ChatManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(qlonglong chatId MEMBER chatId NOTIFY chatIdChanged)
    Q_PROPERTY(QVariantMap chatInformation MEMBER chatInformation NOTIFY chatInformationChanged)
    Q_PROPERTY(bool isForum READ isForum NOTIFY isForumChanged)
    Q_PROPERTY(ChatMessagesModel* model MEMBER chatMessagesModel CONSTANT)
    Q_PROPERTY(MediaMessagesModel* mediaMessagesModel MEMBER mediaMessagesModel CONSTANT)
    Q_PROPERTY(QVariantMap smallPhoto READ smallPhoto NOTIFY smallPhotoChanged)
    Q_PROPERTY(QVariantMap chatActionsByUsers MEMBER chatActionsByUsers NOTIFY chatActionsChanged)
    Q_PROPERTY(QVariantMap chatActionsByChats MEMBER chatActionsByChats NOTIFY chatActionsChanged)

public:
    ChatManager(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE void reset();
    Q_INVOKABLE void initialize(const QVariantMap &chatInformation, qlonglong fromMessageId = 0);
    Q_INVOKABLE void initializeMediaMessagesModel();
    Q_INVOKABLE bool isForum();
    inline qlonglong getChatId() { return chatId; }

    QVariantMap smallPhoto() const;

signals:
    void chatIdChanged();
    void smallPhotoChanged();
    void pinnedMessageChanged();
    void chatActionsChanged();
    void notificationSettingsUpdated();
    void chatInformationChanged();

private slots:
    void handleChatPhotoUpdated(qlonglong chatId, const QVariantMap &photo);
    void handleChatPinnedMessageUpdated(qlonglong chatId, qlonglong pinnedMessageId);
    void handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &chatAction, qlonglong messageThreadId);
    void handleChatNotificationSettingsUpdated(const QString &chatId, const QVariantMap &chatNotificationSettings);
    void handleChatLastMessageUpdated(qlonglong id, const QVariantMap &lastMessage);
    void handleChatReadInboxUpdated(const QString &chatId, const QString &lastReadInboxMessageId, int unreadCount);
    void handleChatReadOutboxUpdated(const QString &chatId, const QString &lastReadOutboxMessageId);

private:
    TDLibWrapper *tdLibWrapper;

    qlonglong chatId;
    QVariantMap chatInformation;

    ChatMessagesModel *chatMessagesModel;
    MediaMessagesModel* mediaMessagesModel;

    QVariantMap chatActionsByUsers; // QMap<qlonglong, QString>
    QVariantMap chatActionsByChats; //QMap<qlonglong, QString>
};

#endif // CHATMANAGER_H
