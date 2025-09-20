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

// MessagesModel's main job is to take care of the messages updates (content, interaction info, etc.)
// It also contains utility unctions used by subclasses and handles messages deletion and some other stuff

class MessagesModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(qlonglong chatId READ getChatId NOTIFY chatIdChanged)

public:
    MessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);
    ~MessagesModel() override;

    virtual QHash<int,QByteArray> roleNames() const override;
    virtual int rowCount(const QModelIndex&) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE virtual bool clear();
    Q_INVOKABLE virtual void reset();
    Q_INVOKABLE QVariantMap getMessage(int index);
    Q_INVOKABLE QVariantList getMessageIdsForAlbum(qlonglong albumId);
    Q_INVOKABLE QVariantList getMessagesForAlbum(qlonglong albumId, int startAt);

    Q_INVOKABLE int getMessageIndex(qlonglong messageId);
    inline qlonglong getChatId() const { return chatId; }

signals:
    void chatIdChanged();
    void messageUpdated(int modelIndex);

private slots:
    void handleMessageReceived(qlonglong chatId, qlonglong messageId, const QVariantMap &message);
    void handleMessageSendSucceeded(qlonglong messageId, qlonglong oldMessageId, const QVariantMap &message);
    void handleMessageContentUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &newContent);
    void handleMessageEditedUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &replyMarkup);
    void handleMessageInteractionInfoUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &updatedInfo);

private:
    void updateAlbumMessages(qlonglong albumId, bool checkDeleted);
    void updateAlbumMessages(QList<qlonglong> albumIds, bool checkDeleted);
    void setMessagesAlbum(MessageData *message);

protected:
    void removeRange(int firstDeleted, int lastDeleted);
    virtual void insertMessages(const QList<MessageData*> newMessages);
    void appendMessages(const QList<MessageData*> newMessages);
    void prependMessages(const QList<MessageData*> newMessages);
    void setMessagesAlbum(const QList<MessageData*> newMessages);
    int findLastSentMessageIndex();
    virtual bool handleInsertMessages(const QVariantList &messages, QList<MessageData*> &newMessagesList, bool setAlbum = true, bool reverseOrder = false);

protected slots:
    virtual void handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds);

protected:
signals:
    void messageSendSucceeded();

protected:
    TDLibWrapper *tdLibWrapper;
    qlonglong chatId;
    QList<MessageData*> messages;
    QHash<qlonglong,int> messageIndexMap;
    QHash<qlonglong, QVariantList> albumMessageMap;
};

#endif // MESSAGESMODEL_H
