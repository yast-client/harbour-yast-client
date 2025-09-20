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

MediaMessagesModel::MediaMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : InvertedMessagesModel(tdLibWrapper, parent), inIncrementalUpdate(false) {
    connect(this->tdLibWrapper, &TDLibWrapper::foundChatMessagesReceived, this, &MediaMessagesModel::handleMessagesReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::newMessageReceived, this, &MediaMessagesModel::handleNewMessageReceived);
}

bool MediaMessagesModel::clear() {
    this->nextFromMessageId = 0;
    return MessagesModel::clear();
}

inline void MediaMessagesModel::loadMessages(qlonglong fromMessageId) {
    this->tdLibWrapper->searchChatMessages(this->chatId, QString(), fromMessageId, TDLibWrapper::SearchMessagesFilterPhotoAndVideo, 100);
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
        const bool reloadNeeded = handleInsertMessages(messages, addedMessages, false);

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
