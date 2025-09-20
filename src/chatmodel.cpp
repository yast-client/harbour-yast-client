#include "chatmodel.h"

#define DEBUG_MODULE ChatModel
#include "debuglog.h"

namespace {
    const QString _TYPE("@type");
    const QString ID("id");
    const QString SMALL("small");
    const QString USER_ID("user_id");
    const QString CHAT_ID("chat_id");
    const QString PHOTO("photo");
    const QString PINNED_MESSAGE_ID("pinned_message_id");
    const QString LAST_READ_INBOX_MESSAGE_ID("last_read_inbox_message_id");
    const QString LAST_READ_OUTBOX_MESSAGE_ID("last_read_outbox_message_id");
    const QString LAST_MESSAGE("last_message");
}

ChatModel::ChatModel(TDLibWrapper *tdLibWrapper, QObject *parent) :
    ReadableMessagesModel(tdLibWrapper, parent),
    searchQuery(),
    mediaMessagesModel(new MediaMessagesModel(tdLibWrapper, this))
{
    connect(this->tdLibWrapper, &TDLibWrapper::chatPhotoUpdated, this, &ChatModel::handleChatPhotoUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatPinnedMessageUpdated, this, &ChatModel::handleChatPinnedMessageUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatActionUpdated, this, &ChatModel::handleChatActionUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatNotificationSettingsUpdated, this, &ChatModel::handleChatNotificationSettingsUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadInboxUpdated, this, &ChatModel::handleChatReadInboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadOutboxUpdated, this, &ChatModel::handleChatReadOutboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatLastMessageUpdated, this, &ChatModel::handleChatLastMessageUpdated);
}

QVariantMap ChatModel::smallPhoto() const {
    return chatInformation.value(PHOTO).toMap().value(SMALL).toMap();
}

void ChatModel::handleChatPhotoUpdated(qlonglong id, const QVariantMap &photo) {
    if (id == chatId) {
        LOG("Chat photo updated" << chatId);
        chatInformation.insert(PHOTO, photo);
        emit smallPhotoChanged();
    }
}

void ChatModel::handleChatPinnedMessageUpdated(qlonglong id, qlonglong pinnedMessageId) {
    if (id == chatId) {
        LOG("Pinned message updated" << chatId);
        chatInformation.insert(PINNED_MESSAGE_ID, pinnedMessageId);
        emit pinnedMessageChanged();
    }
}

void ChatModel::handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &action, qlonglong messageThreadId) {
    const QString actionType = action.value(_TYPE).toString();
    if (messageThreadId == 0 && chatId == this->chatId) {
        LOG("Chat action updated");
        if (sender.value(_TYPE).toString() == "messageSenderChat") {
            const QString senderChatId = sender.value(CHAT_ID).toString();
            if (actionType == "chatActionCancel")
                chatActionsByChats.remove(senderChatId);
            else chatActionsByChats.insert(senderChatId, actionType);
        } else {
            const QString senderUserId = sender.value(USER_ID).toString();
            if (actionType == "chatActionCancel")
                chatActionsByUsers.remove(senderUserId);
            else chatActionsByUsers.insert(senderUserId, actionType);
        }
        LOG(chatActionsByChats << chatActionsByUsers << chatId << sender << action);
        emit chatActionsChanged();
    }
}

void ChatModel::handleChatNotificationSettingsUpdated(const QString &id, const QVariantMap &chatNotificationSettings) {
    if (id.toLongLong() == chatId) {
        this->chatInformation.insert("notification_settings", chatNotificationSettings);
        LOG("Notification settings updated");
        emit notificationSettingsUpdated();
    }
}



bool ChatModel::clear() {
    this->searchQuery.clear();
    return ReadableMessagesModel::clear();
}

void ChatModel::reset() {
    ReadableMessagesModel::reset();

    this->mediaMessagesModel->clear();

    if (!chatInformation.isEmpty()) {
        chatInformation.clear();
        emit smallPhotoChanged();
    }

    if (!chatActionsByUsers.isEmpty()) {
        chatActionsByUsers.clear();
        emit chatActionsChanged();
    }
    if (!chatActionsByChats.isEmpty()) {
        chatActionsByChats.clear();
        emit chatActionsChanged();
    }
}

void ChatModel::initialize(const QVariantMap &chatInformation, qlonglong fromMessageId) {
    const qlonglong chatId = chatInformation.value(ID).toLongLong();
    LOG("Initializing chat model..." << chatId << "from message id" << fromMessageId);

    reset();
    this->chatInformation = chatInformation;
    this->chatId = chatId;
    emit chatIdChanged();
    emit smallPhotoChanged();
    emit historyEndLoadedChanged();

    tdLibWrapper->getChatHistory(chatId, fromMessageId != 0 ? fromMessageId : this->chatInformation.value(LAST_READ_INBOX_MESSAGE_ID).toLongLong());
}

void ChatModel::setSearchQuery(const QString newSearchQuery) {
    if (this->searchQuery != newSearchQuery) {
        this->clear();
        this->searchQuery = newSearchQuery;
        this->loadMessages(searchQuery.isEmpty() ? this->chatInformation.value(LAST_READ_INBOX_MESSAGE_ID).toLongLong() : 0); // fixme
    }
}



void ChatModel::loadMessages(qlonglong fromMessageId, int offset) {
    if (searchQuery.isEmpty())
        this->tdLibWrapper->getChatHistory(chatId, fromMessageId, offset);
    else
        // ignore offset for now
        this->tdLibWrapper->searchChatMessages(chatId, searchQuery, fromMessageId);
}

void ChatModel::initializeMediaMessagesModel() {
    this->mediaMessagesModel->init(this->chatId);
}


void ChatModel::handleChatLastMessageUpdated(qlonglong id, const QVariant &/*order*/, const QVariantMap &lastMessage) {
    if (id == chatId) {
        this->chatInformation.insert(LAST_MESSAGE, lastMessage);
        LOG("Last message updated");
    }
}

void ChatModel::handleChatReadInboxUpdated(const QString &id, const QString &lastReadInboxMessageId, int unreadCount) {
    if (id.toLongLong() == chatId) {
        LOG("Updating chat unread count, unread messages" << unreadCount << ", last read message ID:" << lastReadInboxMessageId);
        this->chatInformation.insert("unread_count", unreadCount);
        this->chatInformation.insert(LAST_READ_INBOX_MESSAGE_ID, lastReadInboxMessageId);
        emit unreadCountUpdated(unreadCount, lastReadInboxMessageId);
    }
}

void ChatModel::handleChatReadOutboxUpdated(const QString &id, const QString &lastReadOutboxMessageId) {
    if (id.toLongLong() == chatId) {
        this->chatInformation.insert(LAST_READ_OUTBOX_MESSAGE_ID, lastReadOutboxMessageId);
        LOG("Updating sent message ID");
        emit lastReadSentMessageUpdated();
    }
}

qlonglong ChatModel::lastReadInboxMessageId() const {
    return this->chatInformation.value(LAST_READ_INBOX_MESSAGE_ID).toLongLong();
}
qlonglong ChatModel::lastReadOutboxMessageId() const {
    return this->chatInformation.value(LAST_READ_OUTBOX_MESSAGE_ID).toLongLong();
}
qlonglong ChatModel::lastMessageId() const { // FIXME: this is wrong and shouldn't be used ideally
    return this->chatInformation.value(LAST_MESSAGE).toMap().value(ID).toLongLong();
}
