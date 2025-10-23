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

    connect(this, &MediaMessagesModel::messagesReceivedPre, this, &MediaMessagesModel::updateIsEndReached);
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
    clear();
    this->chatId = chatId;
    this->highlightedMessageId = fromMessageId;
    loadMessagesWithLimit(fromMessageId, fromMessageId == 0 ? 0 : -26, fromMessageId == 0 ? 100 : 51);
}

void MediaMessagesModel::loadMoreHistoryImpl() {
    this->loadMessages(nextFromMessageId);
}
void MediaMessagesModel::loadMoreFutureImpl() {
    this->loadMessages(messages.last()->messageId, -100);
}
void MediaMessagesModel::loadHistoryForMessageImpl(qlonglong messageId) {
    this->loadMessages(messageId, -1);
}

void MediaMessagesModel::updateIsEndReached(int totalCount, UpdateType fromUpdate) {
    if (fromUpdate == UpdateNextSlice && totalCount == 0)
        endReached = true;
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
