#include "chatmanager.h"

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
    const char* PROPERTY_CHAT_INFORMATION = "chatInformation";
}

ChatManager::ChatManager(TDLibWrapper *tdLibWrapper, QObject *parent) :
    QObject(parent),
    tdLibWrapper(tdLibWrapper),
    chatId(0),
    chatMessagesModel(new ChatMessagesModel(tdLibWrapper, this)),
    mediaMessagesModel(new MediaMessagesModel(tdLibWrapper, this))
{
    connect(this->tdLibWrapper, &TDLibWrapper::chatPhotoUpdated, this, &ChatManager::handleChatPhotoUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatPinnedMessageUpdated, this, &ChatManager::handleChatPinnedMessageUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatActionUpdated, this, &ChatManager::handleChatActionUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatNotificationSettingsUpdated, this, &ChatManager::handleChatNotificationSettingsUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadInboxUpdated, this, &ChatManager::handleChatReadInboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadOutboxUpdated, this, &ChatManager::handleChatReadOutboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatLastMessageUpdated, this, &ChatManager::handleChatLastMessageUpdated);
}

QVariantMap ChatManager::smallPhoto() const {
    return chatInformation.value(PHOTO).toMap().value(SMALL).toMap();
}

void ChatManager::handleChatPhotoUpdated(qlonglong id, const QVariantMap &photo) {
    if (id == chatId) {
        LOG("Chat photo updated" << chatId);
        chatInformation.insert(PHOTO, photo);
        emit smallPhotoChanged();
        emit chatInformationChanged();
    }
}

void ChatManager::handleChatPinnedMessageUpdated(qlonglong id, qlonglong pinnedMessageId) {
    if (id == chatId) {
        LOG("Pinned message updated" << chatId);
        chatInformation.insert(PINNED_MESSAGE_ID, pinnedMessageId);
        emit pinnedMessageChanged();
        emit chatInformationChanged();
    }
}

void ChatManager::handleChatActionUpdated(qlonglong chatId, const QVariantMap &sender, const QVariantMap &action, qlonglong messageThreadId) {
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

void ChatManager::handleChatNotificationSettingsUpdated(const QString &id, const QVariantMap &chatNotificationSettings) {
    if (id.toLongLong() == chatId) {
        this->chatInformation.insert("notification_settings", chatNotificationSettings);
        LOG("Notification settings updated");
        emit notificationSettingsUpdated();
        emit chatInformationChanged();
    }
}



ChatMessagesModel::ChatMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : ReadableMessagesModel(tdLibWrapper, parent), searchQuery() {}

bool ChatMessagesModel::clear() {
    this->searchQuery.clear();
    return ReadableMessagesModel::clear();
}

void ChatManager::reset() {
    this->mediaMessagesModel->reset();

    if (!chatInformation.isEmpty()) {
        chatInformation.clear();
        emit smallPhotoChanged();
        emit chatInformationChanged();
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

void ChatManager::initialize(const QVariantMap &chatInformation, qlonglong fromMessageId) {
    const qlonglong chatId = chatInformation.value(ID).toLongLong();
    LOG("Initializing chat model..." << chatId << "from message id" << fromMessageId);

    reset();
    this->chatInformation = chatInformation;
    this->chatId = chatId;
    emit chatIdChanged();
    emit smallPhotoChanged();

    chatMessagesModel->chatId = chatId;
    chatMessagesModel->chatIdChanged();
    emit chatMessagesModel->historyEndLoadedChanged();

    tdLibWrapper->getChatHistory(chatId, fromMessageId != 0 ? fromMessageId : this->chatInformation.value(LAST_READ_INBOX_MESSAGE_ID).toLongLong());
}

void ChatMessagesModel::setSearchQuery(const QString newSearchQuery) {
    if (this->searchQuery != newSearchQuery) {
        this->clear();
        this->searchQuery = newSearchQuery;
        this->loadMessages(searchQuery.isEmpty() ? this->parent()->property(PROPERTY_CHAT_INFORMATION).toMap().value(LAST_READ_INBOX_MESSAGE_ID).toLongLong() : 0); // fixme
    }
}



void ChatMessagesModel::loadMessages(qlonglong fromMessageId, int offset) {
    if (searchQuery.isEmpty())
        this->tdLibWrapper->getChatHistory(chatId, fromMessageId, offset);
    else
        // ignore offset for now
        this->tdLibWrapper->searchChatMessages(chatId, searchQuery, fromMessageId);
}

void ChatManager::initializeMediaMessagesModel() {
    this->mediaMessagesModel->init(this->chatId);
}

bool ChatManager::isForum() {
    // TODO
    return false;
}


void ChatManager::handleChatLastMessageUpdated(qlonglong id, const QVariantMap &lastMessage) {
    if (id == chatId) {
        this->chatInformation.insert(LAST_MESSAGE, lastMessage);
        LOG("Last message updated");
        emit chatInformationChanged();
    }
}

void ChatManager::handleChatReadInboxUpdated(const QString &id, const QString &lastReadInboxMessageId, int unreadCount) {
    if (id.toLongLong() == chatId) {
        LOG("Updating chat unread count, unread messages" << unreadCount << ", last read message ID:" << lastReadInboxMessageId);
        this->chatInformation.insert("unread_count", unreadCount);
        this->chatInformation.insert(LAST_READ_INBOX_MESSAGE_ID, lastReadInboxMessageId);
        emit this->chatMessagesModel->unreadCountUpdated(unreadCount, lastReadInboxMessageId);
        emit chatInformationChanged();
    }
}

void ChatManager::handleChatReadOutboxUpdated(const QString &id, const QString &lastReadOutboxMessageId) {
    if (id.toLongLong() == chatId) {
        this->chatInformation.insert(LAST_READ_OUTBOX_MESSAGE_ID, lastReadOutboxMessageId);
        LOG("Updating sent message ID");
        emit this->chatMessagesModel->lastReadSentMessageUpdated();
        emit chatInformationChanged();
    }
}

qlonglong ChatMessagesModel::lastReadInboxMessageId() const {
    return this->parent()->property(PROPERTY_CHAT_INFORMATION).toMap().value(LAST_READ_INBOX_MESSAGE_ID).toLongLong();
}
qlonglong ChatMessagesModel::lastReadOutboxMessageId() const {
    return this->parent()->property(PROPERTY_CHAT_INFORMATION).toMap().value(LAST_READ_OUTBOX_MESSAGE_ID).toLongLong();
}
qlonglong ChatMessagesModel::lastMessageId() const { // FIXME: this is wrong and shouldn't be used ideally
    return this->parent()->property(PROPERTY_CHAT_INFORMATION).toMap().value(LAST_MESSAGE).toMap().value(ID).toLongLong();
}
