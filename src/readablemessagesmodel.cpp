#include "readablemessagesmodel.h"

#define DEBUG_MODULE ReadableMessagesModel
#include "debuglog.h"

namespace {
    const QString ID("id");
    const QString CHAT_ID("chat_id");
    const QString LAST_READ_INBOX_MESSAGE_ID("last_read_inbox_message_id");
    const QString LAST_READ_OUTBOX_MESSAGE_ID("last_read_outbox_message_id");
    const QString MESSAGE_ID("message_id");
}

ReadableMessagesModel::ReadableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) :
    MessagesModel(tdLibWrapper, parent),
    highlightedMessageId(0),
    inReload(false),
    inIncrementalUpdate(false),
    loadingFullEnd(false)
{
    connect(this->tdLibWrapper, &TDLibWrapper::messagesReceived, this, &ReadableMessagesModel::handleMessagesReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::foundChatMessagesReceived, this, &ReadableMessagesModel::handleFoundChatMessagesReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::sponsoredMessageReceived, this, &ReadableMessagesModel::handleSponsoredMessageReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::newMessageReceived, this, &ReadableMessagesModel::handleNewMessageReceived);

    connect(this, &ReadableMessagesModel::messageSendSucceeded, this, &ReadableMessagesModel::lastReadSentMessageUpdated);

    // FIXME: can this be implemented better?
    connect(this, &ReadableMessagesModel::messagesReceived, this, &ReadableMessagesModel::lastReadMessageIndexChanged);
    connect(this, &ReadableMessagesModel::newMessageReceived, this, &ReadableMessagesModel::lastReadMessageIndexChanged);
    connect(this, &ReadableMessagesModel::unreadCountUpdated, this, &ReadableMessagesModel::lastReadMessageIndexChanged);

    // FIXME: can this be implemented better?
    connect(this, &ReadableMessagesModel::messagesReceived, this, &ReadableMessagesModel::historyEndLoadedChanged);
}

bool ReadableMessagesModel::clear() {
    LOG("Clearing readable messages model");
    inReload = false;
    inIncrementalUpdate = false;
    highlightedMessageId = 0;
    loadingFullEnd = false;
    if (MessagesModel::clear()) {
        emit historyEndLoadedChanged();
        emit lastReadSentMessageUpdated();
        return true;
    }
    return false;
}

int ReadableMessagesModel::getLastReadMessageIndex() {
    int listInboxPosition = messageIndexMap.value(lastReadInboxMessageId(), -1);
    if (listInboxPosition > messages.size() - 1) listInboxPosition = -1;
    return listInboxPosition;
}

int ReadableMessagesModel::calculateLastReadSentMessageIndex() {
    LOG("calculateLastReadSentMessageIndex");
    qlonglong id = lastReadOutboxMessageId();
    LOG("lastReadSentMessageId" << id);
    LOG("size messageIndexMap" << messageIndexMap.size());
    LOG("contains ID?" << messageIndexMap.contains(id));
    int listOutboxPosition;
    if (messageIndexMap.contains(id))
        listOutboxPosition = messageIndexMap.value(id, -1);
    else {
        LOG("Last read sent message is not loaded, falling back to last loaded sent message");
        listOutboxPosition = findLastSentMessageIndex();
    }
    LOG("Last read sent message" << id << "is at position" << listOutboxPosition);
    return listOutboxPosition;
}

int ReadableMessagesModel::calculateScrollPosition() {
    if (loadingFullEnd) return this->messages.size() - 1;

    int scrollPosition = this->messageIndexMap.value(this->highlightedMessageId, -1);
    if (scrollPosition == -1) {
        LOG("calculateLastScrollMessageIndex");

        int listInboxPosition = this->messageIndexMap.value(lastReadInboxMessageId(), -1);
        int listOwnPosition = findLastSentMessageIndex();

        if (listInboxPosition > messages.size() - 1) listInboxPosition = -1;
        if (listOwnPosition > messages.size() - 1) listOwnPosition = -1;

        LOG("Last read received message is at position" << listInboxPosition << "; last read sent message is at position" << listOwnPosition);

        scrollPosition = qMax(listInboxPosition, listOwnPosition);
    }

    LOG("Calculating new scroll position, current:" << scrollPosition << ", list size:" << this->messages.size());
    return qMin(scrollPosition + 1, this->messages.size() - 1);
}

bool ReadableMessagesModel::isMostRecentMessageLoaded() {
    // Need to check if we can actually add messages (only possible if the previously latest messages are loaded)
    // some other things also depend on this now

    const qlonglong messageId = lastMessageId();
    const bool result = this->messageIndexMap.contains(messageId);
    LOG("Checking if most recent message is loaded" << messageId << result << messageIndexMap);
    return result;
}

int ReadableMessagesModel::calculateLastReadMessageIndexInBounds() {
    LOG("calculateLastReadMessageIndexInBounds");
    const qlonglong lastReadMessageId = lastReadInboxMessageId(); // last read incoming message id

    LOG("lastReadMessageId" << lastReadMessageId);
    LOG("size messageIndexMap" << messageIndexMap.size()
        << "; contains last read ID?" << messageIndexMap.contains(lastReadMessageId)
        );

    int listInboxPosition = messageIndexMap.value(lastReadMessageId, messages.size() - 1);
    int listOwnPosition = findLastSentMessageIndex();

    if (listInboxPosition > messages.size() - 1)
        listInboxPosition = messages.size() - 1;
    if (listOwnPosition > messages.size() - 1)
        listOwnPosition = -1;

    LOG("Last known message is at position" << listInboxPosition << "; last own message is at position" << listOwnPosition);

    return qMax(listInboxPosition, listOwnPosition);
}


void ReadableMessagesModel::triggerLoadHistoryForMessage(qlonglong messageId) {
    if (!this->inIncrementalUpdate && !messages.isEmpty()) {
        LOG("Trigger loading message with id..." << messageId);
        this->clear();
        this->highlightedMessageId = messageId;
        this->loadMessages(messageId);
    }
}

void ReadableMessagesModel::triggerLoadMoreHistory() {
    if (!this->inIncrementalUpdate && !messages.isEmpty()) {
        this->inIncrementalUpdate = true;
        LOG("Loading older messages...");
        this->loadMessages(messages.first()->messageId);
    }
}

void ReadableMessagesModel::triggerLoadMoreFuture() {
    if (canLoadMoreMessages() && !this->inIncrementalUpdate && !messages.isEmpty()) {
        LOG("Loading newer messages...");
        this->inIncrementalUpdate = true;
        this->loadMessages(messages.last()->messageId, -49);
    }
}

void ReadableMessagesModel::handleMessagesReceived(const QVariantList &messages, int totalCount) {
    LOG("Receiving new messages :)" << messages.size());

    auto notifyMessagesLoaded = [&]() {
        this->inReload = false;
        emit lastReadSentMessageUpdated();

        bool fromIncrementalUpdate = this->inIncrementalUpdate;
        this->inIncrementalUpdate = false;
        emit messagesReceived(totalCount, fromIncrementalUpdate);
    };

    if (messages.size() == 0) {
        LOG("No additional messages loaded, notifying chat UI...");
        notifyMessagesLoaded();
    } else {
        if (this->inIncrementalUpdate || this->inReload || this->messages.size() == 0 || this->isMostRecentMessageLoaded()) {
            QList<MessageData*> addedMessages;
            const bool reloadNeeded = handleInsertMessages(messages, addedMessages);

            // First call only returns a few messages, we need to get a little more than that...
            if (reloadNeeded && !inReload) {
                LOG("Only a few messages received in first call, loading more...");
                this->inReload = true;
                this->loadMessages(addedMessages.first()->messageId, 0); // (possibly) fixme
            } else {
                LOG("Messages loaded, notifying chat UI...");
                notifyMessagesLoaded();
            }
        } else {
            // Cleanup... Is that really needed? Well, let's see...
            this->inReload = this->inIncrementalUpdate = false;
            LOG("New messages in this chat, but not relevant as less recent messages need to be loaded first!");
        }
    }

}

void ReadableMessagesModel::handleFoundChatMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int totalCount, qlonglong /*nextFromMessageId*/) {
    if (filter == TDLibWrapper::SearchMessagesFilterEmpty) {
        LOG("Found chat messages received");
        handleMessagesReceived(messages, totalCount);
    }
}

void ReadableMessagesModel::handleSponsoredMessageReceived(qlonglong chatId, const QVariantMap &sponsoredMessage) {
    LOG("Handling sponsored message" << chatId);
    QList<MessageData*> messagesToBeAdded;
    const qlonglong messageId = sponsoredMessage.value(MESSAGE_ID).toLongLong();
    if (messageId && !messageIndexMap.contains(messageId)) {
        LOG("New sponsored message will be added:" << messageId);
        messagesToBeAdded.append(new MessageData(sponsoredMessage, messageId));
    }
    appendMessages(messagesToBeAdded);
}

void ReadableMessagesModel::handleNewMessageReceived(qlonglong chatId, const QVariantMap &message) {
    const qlonglong messageId = message.value(ID).toLongLong();
    if (chatId == this->chatId && !messageIndexMap.contains(messageId)) {
        if (canLoadMoreMessages() && this->isMostRecentMessageLoaded()) {
            LOG("New message received for this chat");
            QList<MessageData*> messagesToBeAdded;
            messagesToBeAdded.append(new MessageData(message, messageId));
            insertMessages(messagesToBeAdded);
            setMessagesAlbum(messagesToBeAdded);
            emit newMessageReceived(message);
        } else {
            LOG("New message in this chat, but not relevant as less recent messages need to be loaded first!");
        }
    }
}


void ReadableMessagesModel::loadEnd(bool markAllAsRead) {
    if (!this->inIncrementalUpdate && !messages.isEmpty() && !inReload) {
        LOG("Loading end of the chat... markAllAsRead:" << markAllAsRead << (markAllAsRead ? 0 : lastReadOutboxMessageId()) << chatId);

        //if (markAllAsRead) // FIXME: is this really needed?
        //    this->tdLibWrapper->toggleChatIsMarkedAsUnread(this->chatId, false);
        this->loadingFullEnd = markAllAsRead; // doesn't seem to always work (also a similar issue with search)

        this->clear();
        this->loadMessages(markAllAsRead ? 0 : lastReadOutboxMessageId());
    }
}
