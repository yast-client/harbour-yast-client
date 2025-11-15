#include "jumpablemessagesmodel.h"

#define DEBUG_MODULE JumpableMessagesModel
#include "debuglog.h"

JumpableMessagesModel::JumpableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) :
    MessagesModel(tdLibWrapper, parent),
    waitingFor(UpdateNone),
    startReached(false),
    endReached(false),
    highlightedMessageId(0)
{
    connect(this, &JumpableMessagesModel::endReachedChanged, this, &JumpableMessagesModel::loadingChanged);
}

bool JumpableMessagesModel::clear() {
    LOG("Clearing jumpable messages model");
    waitingFor = UpdateNone;
    startReached = endReached = false;
    emit endReachedChanged();
    loadingChanged();
    highlightedMessageId = 0;
    return MessagesModel::clear();
}

void JumpableMessagesModel::loadMoreHistory() {
    if (!startReached && !waitingForSlice() && !messages.isEmpty()) {
        LOG("Loading older messages...");
        this->waitingFor = UpdatePreviousSlice;
        this->loadMoreHistoryImpl();
    }
}

void JumpableMessagesModel::loadMoreFuture() {
    if (canLoadMoreMessages() && !endReached && !waitingForSlice() && !messages.isEmpty()) {
        LOG("Loading newer messages...");
        this->waitingFor = UpdateNextSlice;
        this->loadMoreFutureImpl();
    }
}

void JumpableMessagesModel::loadHistoryForMessage(qlonglong messageId) {
    if (!waitingForSlice() && !messages.isEmpty()) {
        LOG("Trigger loading message with id..." << messageId);
        this->clear();
        this->highlightedMessageId = messageId;
        this->loadHistoryForMessageImpl(messageId);
    }
}

bool JumpableMessagesModel::loading() const {
    // If messages isn't empty, we aren't loading
    // Otherwise, if it is empty and both end and start is reached, means that the chat is empty for sure, meaning we have finished loading too
    return messages.isEmpty() && !endReached && !startReached;
}

void JumpableMessagesModel::updateStartEndReached(int totalCount, UpdateType fromUpdate) {
    if (totalCount == 0) {
        if (fromUpdate == UpdateNextSlice)
            endReached = true;
        else if (fromUpdate == UpdatePreviousSlice)
            startReached = true;
        else if (fromUpdate == UpdateNone) // No messages in chat
            startReached = endReached = true;
    }

    LOG("Updated endReached" << endReached << "startReached" << startReached);

    emit endReachedChanged();
}

void JumpableMessagesModel::handleMessagesReceived(const QVariantList &messages, int totalCount) {
    LOG("Received messages" << messages.size());

    auto notifyMessagesLoaded = [&]() {
        const UpdateType fromUpdate = this->waitingFor;
        const bool fromSliceUpdate = waitingForSlice();
        this->waitingFor = UpdateNone;
        this->updateStartEndReached(totalCount, fromUpdate); // emits loadingChanged() as well
        emit messagesReceived(totalCount, fromSliceUpdate);
    };

    if (messages.size() == 0) {
        LOG("No additional messages loaded, notifying chat UI...");
        notifyMessagesLoaded();
    } else {
        if (this->waitingFor != UpdateNone || this->messages.size() == 0) {
            QList<MessageData*> addedMessages;
            const bool reloadNeeded = handleInsertMessages(messages, addedMessages);

            // First call only returns a few messages, we need to get a little more than that...
            if (reloadNeeded && this->waitingFor != UpdateReload) {
                LOG("Only a few messages received in first call, loading more...");
                this->waitingFor = UpdateReload;
                this->loadMessages(addedMessages.first()->messageId, 0); // (possibly) FIXME
            } else {
                LOG("Messages loaded, notifying chat UI...");
                notifyMessagesLoaded();
            }
        } else {
            // Cleanup... Is that really needed? Well, let's see...
            this->waitingFor = UpdateNone;
            LOG("New messages in this chat, but not relevant as less recent messages need to be loaded first!");
        }
    }
}

int JumpableMessagesModel::calculateScrollPosition() {
    return this->messageIndexMap.value(this->highlightedMessageId, -1);
}
