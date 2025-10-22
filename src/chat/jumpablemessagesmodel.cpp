#include "jumpablemessagesmodel.h"

#define DEBUG_MODULE JumpableMessagesModel
#include "debuglog.h"

JumpableMessagesModel::JumpableMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) :
    MessagesModel(tdLibWrapper, parent),
    highlightedMessageId(0),
    inReload(false),
    inIncrementalUpdate(false)
{}

bool JumpableMessagesModel::clear() {
    LOG("Clearing jumpable messages model");
    inReload = false;
    inIncrementalUpdate = false;
    highlightedMessageId = 0;
    return MessagesModel::clear();
}

void JumpableMessagesModel::triggerLoadMoreHistory() {
    if (!this->inIncrementalUpdate && !messages.isEmpty()) {
        LOG("Loading older messages...");
        this->inIncrementalUpdate = true;
        this->loadMoreHistoryImpl();
    }
}

void JumpableMessagesModel::triggerLoadMoreFuture() {
    if (canLoadMoreMessages() && !this->inIncrementalUpdate && !messages.isEmpty()) {
        LOG("Loading newer messages...");
        this->inIncrementalUpdate = true;
        this->loadMoreFutureImpl();
    }
}

void JumpableMessagesModel::triggerLoadHistoryForMessage(qlonglong messageId) {
    if (!this->inIncrementalUpdate && !messages.isEmpty()) {
        LOG("Trigger loading message with id..." << messageId);
        this->clear();
        this->highlightedMessageId = messageId;
        this->loadHistoryForMessageImpl(messageId);
    }
}

void JumpableMessagesModel::handleMessagesReceived(const QVariantList &messages, int totalCount) {
    LOG("Receiving new messages :)" << messages.size());

    auto notifyMessagesLoaded = [&]() {
        this->inReload = false;

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
