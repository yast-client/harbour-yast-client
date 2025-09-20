#include "mediamessagesmodel.h"

#define DEBUG_MODULE MediaMessagesModel
#include "debuglog.h"

namespace {
    const QString ID("id");
    const QString CONTENT("content");
    const QString _TYPE("@type");
    const QString TYPE_MESSAGE_PHOTO("messagePhoto");
    const QString TYPE_MESSAGE_VIDEO("messageVideo");
}

MediaMessagesModel::MediaMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : MessagesModel(tdLibWrapper, parent), inIncrementalUpdate(false) {
    connect(this->tdLibWrapper, &TDLibWrapper::foundChatMessagesReceived, this, &MediaMessagesModel::handleMessagesReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::newMessageReceived, this, &MediaMessagesModel::handleNewMessageReceived);
}

bool MediaMessagesModel::clear() {
    this->nextFromMessageId = 0;
    return MessagesModel::clear();
}

inline void MediaMessagesModel::loadMessages(qlonglong fromMessageId) {
    this->tdLibWrapper->searchChatMessages(this->chatId, QString(), fromMessageId, TDLibWrapper::SearchMessagesFilterPhotoAndVideo);
}

void MediaMessagesModel::init(qlonglong chatId) {
    LOG("Initializing" << chatId);
    this->chatId = chatId;
    loadMessages();
}

void MediaMessagesModel::triggerLoadMoreHistory() {
    if (!inIncrementalUpdate && !messages.isEmpty() && nextFromMessageId != 0) {
        LOG("Loading older messages...");
        loadMessages(nextFromMessageId);
        inIncrementalUpdate = false;
    }
}

void MediaMessagesModel::handleMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int /*totalCount*/, qlonglong nextFromMessageId) {
    if (filter == TDLibWrapper::SearchMessagesFilterPhotoAndVideo) {
        LOG("Messages received next id:" << nextFromMessageId << "size:" << messages.size());

        QList<MessageData*> addedMessages;
        const bool reloadNeeded = handleInsertMessages(messages, addedMessages, false, true);

        if (reloadNeeded) {
            LOG("Only a few messages received in first call, loading more...");
            loadMessages(addedMessages.first()->messageId);
            this->inIncrementalUpdate = true;
        } else
            this->inIncrementalUpdate = false;

        this->nextFromMessageId = nextFromMessageId;

    }
}

void MediaMessagesModel::handleNewMessageReceived(qlonglong chatId, const QVariantMap &message) {
    const qlonglong messageId = message.value(ID).toLongLong();
    if (chatId == this->chatId && !messageIndexMap.contains(messageId)) {
        const QString contentType = message.value(CONTENT).toMap().value(_TYPE).toString();
        if (contentType == TYPE_MESSAGE_PHOTO || contentType == TYPE_MESSAGE_VIDEO) {
            LOG("New media message received for this chat");
            insertMessages(QList<MessageData*>{new MessageData(message, messageId)});
        }
    }
}

void MediaMessagesModel::insertMessages(const QList<MessageData*> newMessages) {
    // Caller ensures that newMessages is not empty
    if (messages.isEmpty()) {
        appendMessages(newMessages);
    } else if (!newMessages.isEmpty()) {
        // No sponsored messages here
        // There is only an append or a prepend, tertium non datur! (probably ;))
        const qlonglong lastKnownId = (messages.size() > 0) ? messages.at(0)->messageId : -1;
        const qlonglong firstNewId = newMessages.first()->messageId;
        LOG("Inserting messages, last known ID:" << lastKnownId << ", first new ID:" << firstNewId);
        if (firstNewId > lastKnownId)
            prependMessages(newMessages);
        else
            appendMessages(newMessages);
    }
}

void MediaMessagesModel::handleMessagesDeleted(qlonglong chatId, const QList<qlonglong> &messageIds) {
    LOG("Messages were deleted in a chat" << chatId);
    if (chatId == this->chatId) {
        const int count = messageIds.size();
        LOG(count << "messages in this chat were deleted...");

        int firstPosition = count, lastPosition = count;
        for (int i = 0; i < count; i++) { // Normal, non-reversed order, unlike what's used in MessagesModel
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
