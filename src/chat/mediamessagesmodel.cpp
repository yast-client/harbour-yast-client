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

MediaMessagesModel::MediaMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : JumpableMessagesModel(tdLibWrapper, parent) {
    connect(this->tdLibWrapper, &TDLibWrapper::foundChatMessagesReceived, this, &MediaMessagesModel::handleMessagesReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::newMessageReceived, this, &MediaMessagesModel::handleNewMessageReceived);
}

bool MediaMessagesModel::clear() {
    LOG("Clearing media messages model");
    this->nextFromMessageId = 0;
    return JumpableMessagesModel::clear();
}

void MediaMessagesModel::loadMessagesWithLimit(qlonglong fromMessageId, int offset, int limit) {
    LOG("Loading messages" << fromMessageId << offset);
    this->tdLibWrapper->searchChatMessages(this->chatId, QString(), fromMessageId, TDLibWrapper::SearchMessagesFilterPhotoAndVideo, limit, offset);
}

void MediaMessagesModel::init(qlonglong chatId, qlonglong fromMessageId) {
    LOG("Initializing" << chatId << fromMessageId);

    // TODO: add this to JumpableMessagesModel too
    if (this->chatId == chatId) {
        LOG("Model already initialized for this chat ID, checking if other required stuff is already loaded");

        if (fromMessageId == 0) {
            if (endReached) {
                LOG("Message history end already loaded, skipping initialization");
                emit alreadyLoaded();
                return;
            }
        } else {
            if (this->messages.size() > 0 && this->messageIndexMap.contains(fromMessageId)) {
                LOG("Message is already loaded, skipping initialization");
                this->highlightedMessageId = fromMessageId;
                emit alreadyLoaded();
                return;
            }
        }
    }

    clear();
    this->chatId = chatId;
    this->highlightedMessageId = fromMessageId;
    loadMessagesWithLimit(fromMessageId, fromMessageId == 0 ? 0 : -26, fromMessageId == 0 ? 100 : 51);
}

void MediaMessagesModel::loadMoreHistoryImpl() {
    this->loadMessages(nextFromMessageId);
}
void MediaMessagesModel::loadMoreFutureImpl() {
    this->loadMessagesWithLimit(messages.last()->messageId, -26, 27);
}
void MediaMessagesModel::loadHistoryForMessageImpl(qlonglong messageId) {
    this->loadMessagesWithLimit(messageId, -26, 51);
}

void MediaMessagesModel::handleMessagesReceived(TDLibWrapper::SearchMessagesFilter filter, const QVariantList &messages, int totalCount, qlonglong nextFromMessageId) {
    if (filter == TDLibWrapper::SearchMessagesFilterPhotoAndVideo) {
        LOG("Messages received next id:" << nextFromMessageId);
        JumpableMessagesModel::handleMessagesReceived(messages, totalCount);
        this->nextFromMessageId = nextFromMessageId;
    }
}

void MediaMessagesModel::handleNewMessageReceived(qlonglong chatId, const QVariantMap &message) {
    if (!endReached) return;

    const qlonglong messageId = message.value(ID).toLongLong();
    if (chatId == this->chatId && !messageIndexMap.contains(messageId)) {
        const QString contentType = message.value(CONTENT).toMap().value(_TYPE).toString();
        if (contentType == TYPE_MESSAGE_PHOTO || contentType == TYPE_MESSAGE_VIDEO) {
            LOG("New media message received for this chat");
            insertMessages(QList<MessageData*>{new MessageData(message, messageId)});
        }
    }
}
