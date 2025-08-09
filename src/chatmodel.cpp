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
}

ChatModel::ChatModel(TDLibWrapper *tdLibWrapper) : MessagesModel(tdLibWrapper), searchQuery() {
    connect(this->tdLibWrapper, &TDLibWrapper::chatPhotoUpdated, this, &ChatModel::handleChatPhotoUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatPinnedMessageUpdated, this, &ChatModel::handleChatPinnedMessageUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatActionUpdated, this, &ChatModel::handleChatActionUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatNotificationSettingsUpdated, this, &ChatModel::handleChatNotificationSettingsUpdated);
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



void ChatModel::clear() {
    this->searchQuery.clear();
    MessagesModel::clear();
}

void ChatModel::reset() {
    MessagesModel::reset();

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
