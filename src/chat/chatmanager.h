#ifndef CHATMANAGER_H
#define CHATMANAGER_H

#include "readablemessagesmodel.h"
#include "mediamessagesmodel.h"
#include "forumtopicsmodel.h"

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
    Q_PROPERTY(bool infoInitialized READ infoInitialized NOTIFY chatIdChanged)
    Q_PROPERTY(QVariantMap chatInformation READ chatInformation NOTIFY chatInformationChanged)
    Q_PROPERTY(bool viewAsTopics READ viewAsTopics NOTIFY viewAsTopicsChanged)
    Q_PROPERTY(QVariantMap smallPhoto READ smallPhoto NOTIFY smallPhotoChanged)
    Q_PROPERTY(TDLibWrapper::ChatType chatType READ chatType NOTIFY chatIdChanged)
    Q_PROPERTY(bool isChannel READ isChannel NOTIFY chatIdChanged)
    Q_PROPERTY(QVariant userInfo READ userInfo NOTIFY userInfoChanged)
    Q_PROPERTY(QVariant groupInfo READ groupInfo NOTIFY groupInfoChanged)

    Q_PROPERTY(ChatMessagesModel* model MEMBER chatMessagesModel CONSTANT)
    Q_PROPERTY(MediaMessagesModel* mediaMessagesModel MEMBER mediaMessagesModel CONSTANT)
    Q_PROPERTY(ForumTopicsModel* topicsModel MEMBER topicsModel CONSTANT)

    Q_PROPERTY(qlonglong pinnedMessageId MEMBER pinnedMessageId NOTIFY pinnedMessageChanged)
    Q_PROPERTY(QVariantMap chatActionsByUsers MEMBER chatActionsByUsers NOTIFY chatActionsChanged)
    Q_PROPERTY(QVariantMap chatActionsByChats MEMBER chatActionsByChats NOTIFY chatActionsChanged)

public:
    ChatManager(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    Q_INVOKABLE void reset(bool resetChatId = true);
    Q_INVOKABLE void doBasicInitialization(const QVariantMap &chatInformation);
    Q_INVOKABLE void initialize(const QVariantMap &chatInformation, qlonglong fromMessageId = 0);
    Q_INVOKABLE void initializeMediaMessagesModel(qlonglong fromMessageId = 0);
    bool viewAsTopics();
    inline qlonglong getChatId() { return chatId; }
    inline bool infoInitialized() { return chatId != 0; }
    inline QVariantMap chatInformation() const { return tdLibWrapper->getChat(chatId); }

    QVariantMap smallPhoto() const;
    TDLibWrapper::ChatType chatType() const;
    bool isChannel() const;
    QVariant userInfo() const;
    QVariant groupInfo() const;

signals:
    void chatIdChanged();
    void smallPhotoChanged();
    void pinnedMessageChanged();
    void chatActionsChanged();
    void chatInformationChanged();
    void viewAsTopicsChanged();
    void userInfoChanged();
    void groupInfoChanged();

private slots:
    void handleChatReadInboxUpdated(const QString &id);
    void handleChatReadOutboxUpdated(const QString &id);
    void handleChatRolesUpdated(qlonglong chatId, const QVector<int> changedRoles = QVector<int>());
    void handleChatPinnedMessageUpdated(qlonglong chatId, qlonglong pinnedMessageId);
    void handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &chatAction, qlonglong messageThreadId);
    void handleUserUpdated(const QString &userId);
    void handleBasicGroupUpdated(qlonglong groupId);
    void handleSupergroupUpdated(qlonglong groupId);

private:
    qlonglong userId() const;
    qlonglong groupId() const;

private:
    TDLibWrapper *tdLibWrapper;

    qlonglong chatId;
    qlonglong pinnedMessageId;

    ChatMessagesModel *chatMessagesModel;
    MediaMessagesModel* mediaMessagesModel;
    ForumTopicsModel *topicsModel;

    QVariantMap chatActionsByUsers; // QMap<qlonglong, QString>
    QVariantMap chatActionsByChats; //QMap<qlonglong, QString>
};

#endif // CHATMANAGER_H
