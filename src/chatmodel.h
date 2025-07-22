/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef CHATMODEL_H
#define CHATMODEL_H

#include <QAbstractListModel>
#include "tdlibwrapper.h"

class ChatModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(qlonglong chatId READ getChatId NOTIFY chatIdChanged)
    Q_PROPERTY(QVariantMap smallPhoto READ smallPhoto NOTIFY smallPhotoChanged)
    Q_PROPERTY(int lastReadSentMessageIndex READ calculateLastReadSentMessageIndex NOTIFY lastReadSentMessageUpdated)
    Q_PROPERTY(int lastReadMessageIndexInBounds READ calculateLastReadMessageIndexInBounds NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(int lastReadMessageIndex READ calculateLastReadMessageIndex NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(bool historyEndLoaded READ isMostRecentMessageLoaded NOTIFY historyEndLoadedChanged)
    Q_PROPERTY(QVariantMap chatActionsByUsers MEMBER chatActionsByUsers NOTIFY chatActionsChanged)
    Q_PROPERTY(QVariantMap chatActionsByChats MEMBER chatActionsByChats NOTIFY chatActionsChanged)

public:
    ChatModel(TDLibWrapper *tdLibWrapper);
    ~ChatModel() override;

    virtual QHash<int,QByteArray> roleNames() const override;
    virtual int rowCount(const QModelIndex&) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void clear(bool contentOnly = false);
    Q_INVOKABLE void initialize(const QVariantMap &chatInformation, qlonglong fromMessageId = 0);
    Q_INVOKABLE void triggerLoadMoreHistory();
    Q_INVOKABLE void triggerLoadMoreFuture();
    Q_INVOKABLE void triggerLoadHistoryForMessage(qlonglong messageId);
    Q_INVOKABLE void loadEnd(bool markAllAsRead = false);
    Q_INVOKABLE bool isMostRecentMessageLoaded();
    Q_INVOKABLE QVariantMap getChatInformation();
    Q_INVOKABLE QVariantMap getMessage(int index);
    Q_INVOKABLE QVariantList getMessageIdsForAlbum(qlonglong albumId);
    Q_INVOKABLE QVariantList getMessagesForAlbum(qlonglong albumId, int startAt);
    Q_INVOKABLE void setSearchQuery(const QString newSearchQuery);

    Q_INVOKABLE int getMessageIndex(qlonglong messageId);
    QVariantMap smallPhoto() const;
    qlonglong getChatId() const;

signals:
    void messagesReceived(int scrollPosition, int totalCount);
    void messagesIncrementalUpdate(int scrollPosition);
    void newMessageReceived(const QVariantMap &message);
    void unreadCountUpdated(int unreadCount, const QString &lastReadInboxMessageId);
    void lastReadMessageIndexChanged();
    void lastReadSentMessageUpdated();
    void historyEndLoadedChanged();
    void notificationSettingsUpdated();
    void messageUpdated(int modelIndex);
    void smallPhotoChanged();
    void chatIdChanged();
    void pinnedMessageChanged();
    void chatActionsChanged();

private slots:
    void handleMessagesReceived(const QVariantList &messages, int totalCount);
    void handleSponsoredMessageReceived(qlonglong chatId, const QVariantMap &sponsoredMessage);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);
    void handleMessageReceived(qlonglong chatId, qlonglong messageId, const QVariantMap &message);
    void handleChatReadInboxUpdated(const QString &chatId, const QString &lastReadInboxMessageId, int unreadCount);
    void handleChatReadOutboxUpdated(const QString &chatId, const QString &lastReadOutboxMessageId);
    void handleMessageSendSucceeded(qlonglong messageId, qlonglong oldMessageId, const QVariantMap &message);
    void handleChatNotificationSettingsUpdated(const QString &chatId, const QVariantMap &chatNotificationSettings);
    void handleChatPhotoUpdated(qlonglong chatId, const QVariantMap &photo);
    void handleChatPinnedMessageUpdated(qlonglong chatId, qlonglong pinnedMessageId);
    void handleMessageContentUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &newContent);
    void handleMessageEditedUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &replyMarkup);
    void handleMessageInteractionInfoUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &updatedInfo);
    void handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds);
    void handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &chatAction, qlonglong messageThreadId);

private:
    class MessageData;
    void removeRange(int firstDeleted, int lastDeleted);
    void insertMessages(const QList<MessageData*> newMessages);
    void appendMessages(const QList<MessageData*> newMessages);
    void prependMessages(const QList<MessageData*> newMessages);
    void updateAlbumMessages(qlonglong albumId, bool checkDeleted);
    void updateAlbumMessages(QList<qlonglong> albumIds, bool checkDeleted);
    void setMessagesAlbum(const QList<MessageData*> newMessages);
    void setMessagesAlbum(MessageData *message);
    QVariantMap enhanceMessage(const QVariantMap &message);
    int calculateLastReadMessageIndexInBounds();
    int calculateLastReadMessageIndex();
    int calculateLastReadSentMessageIndex();
    int calculateScrollPosition();
    int findLastSentMessageIndex();

private:
    TDLibWrapper *tdLibWrapper;
    QList<MessageData*> messages;
    QHash<qlonglong,int> messageIndexMap;
    QHash<qlonglong, QVariantList> albumMessageMap;
    QVariantMap chatInformation;
    qlonglong chatId;
    qlonglong highlightedMessageId;
    bool inReload;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
    bool searchModeActive;
    QString searchQuery;

    QVariantMap chatActionsByUsers; // QMap<qlonglong, QString>
    QVariantMap chatActionsByChats; //QMap<qlonglong, QString>
};

#endif // CHATMODEL_H
