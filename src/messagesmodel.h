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

#ifndef MESSAGESMODEL_H
#define MESSAGESMODEL_H

#include <QAbstractListModel>
#include "tdlibwrapper.h"
#include "messagedata.h"

class MessagesModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(qlonglong chatId READ getChatId NOTIFY chatIdChanged)
    Q_PROPERTY(int lastReadSentMessageIndex READ calculateLastReadSentMessageIndex NOTIFY lastReadSentMessageUpdated)
    Q_PROPERTY(int lastReadMessageIndexInBounds READ calculateLastReadMessageIndexInBounds NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(int lastReadIncomingMessageIndex READ getLastReadMessageIndex NOTIFY lastReadMessageIndexChanged)
    Q_PROPERTY(bool historyEndLoaded READ isMostRecentMessageLoaded NOTIFY historyEndLoadedChanged)

public:
    MessagesModel(TDLibWrapper *tdLibWrapper);
    ~MessagesModel() override;

    virtual QHash<int,QByteArray> roleNames() const override;
    virtual int rowCount(const QModelIndex&) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE virtual void clear();
    Q_INVOKABLE virtual void reset();
    Q_INVOKABLE void triggerLoadMoreHistory();
    Q_INVOKABLE void triggerLoadMoreFuture();
    Q_INVOKABLE void triggerLoadHistoryForMessage(qlonglong messageId);
    Q_INVOKABLE void loadEnd(bool markAllAsRead = false);
    Q_INVOKABLE bool isMostRecentMessageLoaded();
    Q_INVOKABLE QVariantMap getChatInformation();
    Q_INVOKABLE QVariantMap getMessage(int index);
    Q_INVOKABLE QVariantList getMessageIdsForAlbum(qlonglong albumId);
    Q_INVOKABLE QVariantList getMessagesForAlbum(qlonglong albumId, int startAt);

    Q_INVOKABLE int getMessageIndex(qlonglong messageId);
    inline qlonglong getChatId() const { return chatId; }

signals:
    void chatIdChanged();
    void messagesReceived(int scrollPosition, int totalCount);
    void messagesIncrementalUpdate(int scrollPosition);
    void newMessageReceived(const QVariantMap &message);
    void unreadCountUpdated(int unreadCount, const QString &lastReadInboxMessageId);
    void lastReadMessageIndexChanged();
    void lastReadSentMessageUpdated();
    void historyEndLoadedChanged();
    void messageUpdated(int modelIndex);

private slots:
    void handleMessagesReceived(const QVariantList &messages, int totalCount);
    void handleSponsoredMessageReceived(qlonglong chatId, const QVariantMap &sponsoredMessage);
    void handleNewMessageReceived(qlonglong chatId, const QVariantMap &message);
    void handleMessageReceived(qlonglong chatId, qlonglong messageId, const QVariantMap &message);
    void handleChatReadInboxUpdated(const QString &chatId, const QString &lastReadInboxMessageId, int unreadCount);
    void handleChatReadOutboxUpdated(const QString &chatId, const QString &lastReadOutboxMessageId);
    void handleMessageSendSucceeded(qlonglong messageId, qlonglong oldMessageId, const QVariantMap &message);
    void handleChatLastMessageUpdated(const QString &id, const QString &/*order*/, const QVariantMap &lastMessage);
    void handleMessageContentUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &newContent);
    void handleMessageEditedUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &replyMarkup);
    void handleMessageInteractionInfoUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &updatedInfo);
    void handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds);

private:
    void removeRange(int firstDeleted, int lastDeleted);
    void insertMessages(const QList<MessageData*> newMessages);
    void appendMessages(const QList<MessageData*> newMessages);
    void prependMessages(const QList<MessageData*> newMessages);
    void updateAlbumMessages(qlonglong albumId, bool checkDeleted);
    void updateAlbumMessages(QList<qlonglong> albumIds, bool checkDeleted);
    void setMessagesAlbum(const QList<MessageData*> newMessages);
    void setMessagesAlbum(MessageData *message);
    int calculateLastReadMessageIndexInBounds();
    int getLastReadMessageIndex();
    int calculateLastReadSentMessageIndex();
    int calculateScrollPosition();
    int findLastSentMessageIndex();

protected:
    virtual void loadMessages(qlonglong fromMessageId, int offset = -1) = 0;
    virtual inline bool canLoadMoreMessages() const { return true; }

protected:
    TDLibWrapper *tdLibWrapper;
    qlonglong chatId;
    QVariantMap chatInformation;

private:
    QList<MessageData*> messages;
    QHash<qlonglong,int> messageIndexMap;
    QHash<qlonglong, QVariantList> albumMessageMap;
    qlonglong highlightedMessageId;
    bool inReload;
    bool inIncrementalUpdate; // if we are waiting for messages after sending a request to load more of them
    bool loadingFullEnd;
};

#endif // MESSAGESMODEL_H
