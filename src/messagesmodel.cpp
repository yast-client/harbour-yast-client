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

#include "messagesmodel.h"

#include <QListIterator>
#include <QByteArray>
#include <QBitArray>
#include "utilities.h"

#define DEBUG_MODULE ChatModel
#include "debuglog.h"

namespace {
    const QString ID("id");
    const QString CHAT_ID("chat_id");
    const QString MEDIA_ALBUM_ID("media_album_id");
    const QString TYPE_SPONSORED_MESSAGE("sponsoredMessage");
}

MessagesModel::MessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : QAbstractListModel(parent), chatId(0) {
    this->tdLibWrapper = tdLibWrapper;
    connect(this->tdLibWrapper, &TDLibWrapper::receivedMessage, this, &MessagesModel::handleMessageReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::messageSendSucceeded, this, &MessagesModel::handleMessageSendSucceeded);
    connect(this->tdLibWrapper, &TDLibWrapper::messageContentUpdated, this, &MessagesModel::handleMessageContentUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::messageEditedUpdated, this, &MessagesModel::handleMessageEditedUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::messageInteractionInfoUpdated, this, &MessagesModel::handleMessageInteractionInfoUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::messagesDeleted, this, &MessagesModel::handleMessagesDeleted);
}

MessagesModel::~MessagesModel() {
    LOG("Destroying myself...");
    qDeleteAll(messages);
}

QHash<int,QByteArray> MessagesModel::roleNames() const
{
    QHash<int,QByteArray> roles;
    roles.insert(MessageData::RoleDisplay, "display");
    roles.insert(MessageData::RoleMessageId, "message_id");
    roles.insert(MessageData::RoleMessageContentType, "content_type");
    roles.insert(MessageData::RoleMessageViewCount, "view_count");
    roles.insert(MessageData::RoleMessageReactions, "reactions");
    roles.insert(MessageData::RoleMessageAlbumEntryFilter, "album_entry_filter");
    roles.insert(MessageData::RoleMessageAlbumMessageIds, "album_message_ids");
    return roles;
}

int MessagesModel::rowCount(const QModelIndex &) const
{
    return messages.size();
}

QVariant MessagesModel::data(const QModelIndex &index, int role) const
{
    const int row = index.row();
    if (row >= 0 && row < messages.size()) {
        const MessageData *message = messages.at(row);
        switch ((MessageData::Role)role) {
        case MessageData::RoleDisplay: return message->messageData;
        case MessageData::RoleMessageId: return message->messageId;
        case MessageData::RoleMessageContentType: return message->messageContentType;
        case MessageData::RoleMessageViewCount: return message->viewCount;
        case MessageData::RoleMessageReactions: return message->reactions;
        case MessageData::RoleMessageAlbumEntryFilter: return message->albumEntryFilter;
        case MessageData::RoleMessageAlbumMessageIds: return message->albumMessageIds;
        }
    }
    return QVariant();
}

bool MessagesModel::clear() {
    LOG("Clearing chat model");
    if (!messages.isEmpty()) {
        beginResetModel();
        qDeleteAll(messages);
        messages.clear();
        messageIndexMap.clear();
        albumMessageMap.clear();
        endResetModel();
        return true;
    }
    return false;
}

void MessagesModel::reset() {
    LOG("Resetting chat model");
    clear();
    if (chatId) {
        chatId = 0;
        emit chatIdChanged();
    }
}

QVariantMap MessagesModel::getMessage(int index)
{
    if (index >= 0 && index < messages.size()) {
        return messages.at(index)->messageData;
    }
    return QVariantMap();
}

int MessagesModel::getMessageIndex(qlonglong messageId)
{
    if (messages.size() == 0) {
        return -1;
    }
    if (messageIndexMap.contains(messageId)) {
        return messageIndexMap.value(messageId);
    }
    return -1;
}

QVariantList MessagesModel::getMessageIdsForAlbum(qlonglong albumId)
{
    QVariantList foundMessages;
    if(albumMessageMap.contains(albumId)) { // there should be only one in here
        QHash< qlonglong,  QVariantList >::iterator i = albumMessageMap.find(albumId);
        return i.value();
    }
    return foundMessages;
}

QVariantList MessagesModel::getMessagesForAlbum(qlonglong albumId, int startAt)
{
    LOG("getMessagesForAlbumId" << albumId);
    QVariantList messageIds = getMessageIdsForAlbum(albumId);
    int count = messageIds.size();
    if ( count == 0) {
        return messageIds;
    }
    QVariantList foundMessages;
    for (int messageNum = startAt; messageNum < count; ++messageNum) {
        const int position = messageIndexMap.value(messageIds.at(messageNum).toLongLong(), -1);
        if(position >= 0 && position < messages.size()) {
            foundMessages.append(messages.at(position)->messageData);
        } else {
            LOG("Not found in messages: #"<< messageNum);
        }
    }
    return foundMessages;
}

void MessagesModel::handleMessageReceived(qlonglong chatId, qlonglong messageId, const QVariantMap &message) {
    if (chatId == this->chatId && messageIndexMap.contains(messageId)) {
        LOG("Received a message that we already know, let's update it!");
        const int position = messageIndexMap.value(messageId);
        const QVector<int> changedRoles(messages.at(position)->setMessageData(message));
        LOG("Message was updated at index" << position);
        const QModelIndex messageIndex(index(position));
        emit dataChanged(messageIndex, messageIndex, changedRoles);
    }
}

void MessagesModel::handleMessageSendSucceeded(qlonglong messageId, qlonglong oldMessageId, const QVariantMap &message) {
    LOG("Message send succeeded, new message ID" << messageId << "old message ID" << oldMessageId << ", chat ID" << message.value(CHAT_ID).toString());
    LOG("index map:" << messageIndexMap.contains(oldMessageId) << ", index count:" << messageIndexMap.size() << ", message count:" << messages.size());
    if (this->messageIndexMap.contains(oldMessageId)) {
        LOG("Message was successfully sent" << oldMessageId);
        const int pos = messageIndexMap.take(oldMessageId);
        MessageData* oldMessage = messages.at(pos);
        MessageData* newMessage = new MessageData(message, messageId);
        messages.replace(pos, newMessage);
        messageIndexMap.remove(oldMessageId);
        messageIndexMap.insert(messageId, pos);
        // TODO when we support sending album messages, handle ID change in albumMessageMap
        const QVector<int> changedRoles(newMessage->diff(oldMessage));
        delete oldMessage;
        LOG("Message was replaced at index" << pos);
        const QModelIndex messageIndex(index(pos));
        emit dataChanged(messageIndex, messageIndex, changedRoles);
        emit messageSendSucceeded();
        tdLibWrapper->viewMessage(this->chatId, messageId, false);
    }
}

void MessagesModel::handleMessageContentUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &newContent) {
    LOG("Message content updated" << chatId << messageId);
    if (chatId == this->chatId && messageIndexMap.contains(messageId)) {
        LOG("We know the message that was updated" << messageId);
        const int pos = messageIndexMap.value(messageId, -1);
        if (pos >= 0) {
            MessageData* messageData = messages.at(pos);
            const QVector<int> changedRoles(messageData->setContent(newContent));
            LOG("Message was updated at index" << pos);
            const QModelIndex messageIndex(index(pos));
            emit dataChanged(messageIndex, messageIndex, changedRoles);
            emit messageUpdated(pos);
        }
    }
}

void MessagesModel::handleMessageInteractionInfoUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &updatedInfo) {
    if (chatId == this->chatId && messageIndexMap.contains(messageId)) {
        const int pos = messageIndexMap.value(messageId, -1);
        if (pos >= 0) {
            LOG("Message interaction info was updated at index" << pos);
            const QVector<int> changedRoles(messages.at(pos)->setInteractionInfo(updatedInfo));
            const QModelIndex messageIndex(index(pos));
            emit dataChanged(messageIndex, messageIndex, changedRoles);
        }
    }
}

void MessagesModel::handleMessageEditedUpdated(qlonglong chatId, qlonglong messageId, const QVariantMap &replyMarkup)
{
    LOG("Message edited updated" << chatId << messageId);
    if (chatId == this->chatId && messageIndexMap.contains(messageId)) {
        LOG("We know the message that was updated" << messageId);
        const int pos = messageIndexMap.value(messageId, -1);
        if (pos >= 0) {
            MessageData* messageData = messages.at(pos);
            const QVector<int> changedRoles(messageData->setReplyMarkup(replyMarkup));
            LOG("Message was edited at index" << pos);
            const QModelIndex messageIndex(index(pos));
            emit dataChanged(messageIndex, messageIndex, changedRoles);
            emit messageUpdated(pos);
        }
    }
}

void MessagesModel::handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds) {
    LOG("Messages were deleted in a chat" << chatId);
    if (chatId == this->chatId) {
        const int count = messageIds.size();
        LOG(count << "messages in this chat were deleted...");

        int firstPosition = count, lastPosition = count;
        for (int i = (count - 1); i > -1; i--) {
            const int position = messageIndexMap.value(messageIds.at(i), -1);
            if (position >= 0) {
                // We found at least one message in our list that needs to be deleted
                if (lastPosition == count) {
                    lastPosition = position;
                }
                if (firstPosition == count) {
                    firstPosition = position;
                }
                if (position < (firstPosition - 1)) {
                    // Some gap in between, can remove previous range and reset positions
                    removeRange(firstPosition, lastPosition);
                    firstPosition = lastPosition = position;
                } else {
                    // No gap in between, extend the range and continue loop
                    firstPosition = position;
                }
            }
        }
        // After all elements have been processed, there may be one last range to remove
        // But only if we found at least one item to remove
        if (firstPosition != count && lastPosition != count) {
            removeRange(firstPosition, lastPosition);
        }
    }
}


void MessagesModel::removeRange(int firstDeleted, int lastDeleted)
{
    if (firstDeleted >= 0 && firstDeleted <= lastDeleted) {
        LOG("Removing range" << firstDeleted << "..." << lastDeleted << "| current messages size" << messages.size());
        beginRemoveRows(QModelIndex(), firstDeleted, lastDeleted);
        QList<qlonglong> rescanAlbumIds;
        for (int i = firstDeleted; i <= lastDeleted; i++) {
            MessageData *message = messages.at(i);
            messageIndexMap.remove(message->messageId);

            qlonglong albumId = message->messageData.value(MEDIA_ALBUM_ID).toLongLong();
            if(albumId != 0 && albumMessageMap.contains(albumId)) {
                rescanAlbumIds.append(albumId);
            }
            delete message;
        }
        messages.erase(messages.begin() + firstDeleted, messages.begin() + (lastDeleted + 1));
        // rebuild following messageIndexMap
        for(int i = firstDeleted; i < messages.size(); ++i) {
            messageIndexMap.insert(messages.at(i)->messageId, i);
        }
        endRemoveRows();

        updateAlbumMessages(rescanAlbumIds, true);
    }
}

void MessagesModel::insertMessages(const QList<MessageData*> newMessages)
{
    // Caller ensures that newMessages is not empty
    if (messages.isEmpty()) {
        appendMessages(newMessages);
    } else if (!newMessages.isEmpty()) {
        // There is only an append or a prepend, tertium non datur! (probably ;))
        qlonglong lastKnownId = -1;
        for (int i = (messages.size() - 1); i >= 0; i-- ) {
            const MessageData* message = messages.at(i);
            if (message->messageType != TYPE_SPONSORED_MESSAGE) {
                lastKnownId = message->messageId;
            }
        }
        const qlonglong firstNewId = newMessages.first()->messageId;
        LOG("Inserting messages, last known ID:" << lastKnownId << ", first new ID:" << firstNewId);
        if (lastKnownId < firstNewId) {
            appendMessages(newMessages);
        } else {
            prependMessages(newMessages);
        }
    }
}

void MessagesModel::appendMessages(const QList<MessageData*> newMessages)
{
    const int oldSize = messages.size();
    const int count = newMessages.size();
    LOG("Appending" << count << "new messages...");

    beginInsertRows(QModelIndex(), oldSize, oldSize + count - 1);
    messages.append(newMessages);
    for (int i = 0; i < count; i++) {
        // Append new indices to the map
        messageIndexMap.insert(newMessages.at(i)->messageId, oldSize + i);
    }
    endInsertRows();
}

void MessagesModel::prependMessages(const QList<MessageData*> newMessages)
{
    const int insertCount = newMessages.size();
    const int totalCount = messages.size() + insertCount;
    LOG("Prepending" << insertCount << "messages...");

    beginInsertRows(QModelIndex(), 0, insertCount - 1);
    // Too bad there's no bulk insert
    messages.reserve(totalCount);
    int i;
    for (i = 0; i < insertCount; i++) {
        MessageData* message = newMessages.at(i);
        messages.insert(i, message);
        messageIndexMap.insert(message->messageId, i);
    }
    // The rest of the map has been damaged too
    for (; i < totalCount; i++) {
        messageIndexMap.insert(messages.at(i)->messageId, i);
    }
    endInsertRows();
}

void MessagesModel::updateAlbumMessages(qlonglong albumId, bool checkDeleted) {
    if(albumMessageMap.contains(albumId)) {
        const QVariantList empty;
        QHash< qlonglong,  QVariantList >::iterator album = albumMessageMap.find(albumId);
        QVariantList messageIds = album.value();
        std::sort(messageIds.begin(), messageIds.end());
        int count;
        // first: clear deleted messageIds:
        if(checkDeleted) {
            QVariantList::iterator it = messageIds.begin();
            while (it != messageIds.end()) {
              if (!messageIndexMap.contains(it->toLongLong())) {
                it = messageIds.erase(it);
              }
              else {
                ++it;
              }
            }
        }
        // second: remaining ones still exist
        count = messageIds.size();
        if(count == 0) {
            albumMessageMap.remove(albumId);
        } else {
            for (int i = 0; i < count; i++) {
                const int position = messageIndexMap.value(messageIds.at(i).toLongLong(), -1);
                if(position > -1) {
                    // set list for first entry, empty for all others
                    QVector<int> changedRolesFilter;
                    QVector<int> changedRolesIds;

                    QModelIndex messageIndex(index(position));
                    if(i == 0) {
                        changedRolesFilter = messages.at(position)->setAlbumEntryFilter(false);
                        changedRolesIds = messages.at(position)->setAlbumEntryMessageIds(messageIds);
                    } else {
                        changedRolesFilter = messages.at(position)->setAlbumEntryFilter(true);
                        changedRolesIds = messages.at(position)->setAlbumEntryMessageIds(empty);
                    }
                    emit dataChanged(messageIndex, messageIndex, changedRolesIds);
                    emit dataChanged(messageIndex, messageIndex, changedRolesFilter);
                }
            }
        }
        albumMessageMap.insert(albumId, messageIds);
    }
}

void MessagesModel::updateAlbumMessages(QList<qlonglong> albumIds, bool checkDeleted)
{
    const int albumsCount = albumIds.size();
    for (int i = 0; i < albumsCount; i++) {
        updateAlbumMessages(albumIds.at(i), checkDeleted);
    }
}

void MessagesModel::setMessagesAlbum(const QList<MessageData *> newMessages)
{
    const int count = newMessages.size();
    for (int i = 0; i < count; i++) {
        setMessagesAlbum(newMessages.at(i));
    }
}

void MessagesModel::setMessagesAlbum(MessageData *message) {
    qlonglong albumId = message->messageData.value(MEDIA_ALBUM_ID).toLongLong();
    if (albumId > 0 && (message->messageContentType != "messagePhoto" || message->messageContentType != "messageVideo")) {
        qlonglong messageId = message->messageId;

        if(albumMessageMap.contains(albumId)) {
            // find message id within album:
            QHash< qlonglong,  QVariantList >::iterator i = albumMessageMap.find(albumId);
            if(!i.value().contains(messageId)) {
                i.value().append(messageId);
            }
        } else { // new album id
            albumMessageMap.insert(albumId, QVariantList() << messageId);
        }
        updateAlbumMessages(albumId, false);
    }
}

int MessagesModel::findLastSentMessageIndex() {
    const int myUserId = tdLibWrapper->getUserInformation().value(ID).toInt();
    for (int i = (messages.size() - 1); i >= 0; i--) // find last own message in list
        if (messages.at(i)->senderUserId() == myUserId)
            return i;
    return -1;
}

bool MessagesModel::handleInsertMessages(const QVariantList &messages, QList<MessageData*> &newMessagesList, bool setAlbum, bool reverseOrder) {
    // Returns true if it is required to load more messages

    LOG("Inserting" << messages.size() << "messages from TDLib");

    QListIterator<QVariant> messagesIterator(messages);

    while (messagesIterator.hasNext()) {
        const QVariantMap messageData = messagesIterator.next().toMap();
        const qlonglong messageId = messageData.value(ID).toLongLong();
        if (messageId && messageData.value(CHAT_ID).toLongLong() == chatId && !messageIndexMap.contains(messageId)) {
            LOG("New message will be added:" << messageId);
            MessageData* message = new MessageData(messageData, messageId);
            newMessagesList.append(message);
        }
    }

    std::sort(newMessagesList.begin(), newMessagesList.end(), reverseOrder ? MessageData::moreThan : MessageData::lessThan);

    if (!newMessagesList.isEmpty()) {
        insertMessages(newMessagesList);
        if (setAlbum)
            setMessagesAlbum(newMessagesList);
    }

    // First call only returns a few messages, we need to get a little more than that...
    // (possibly) fixme
    const bool reloadNeeded = !newMessagesList.isEmpty() && (newMessagesList.size() + messages.size()) < 10;
    if (reloadNeeded) LOG("Only a few messages received in first call, requesting to load more...");
    return reloadNeeded;
}
