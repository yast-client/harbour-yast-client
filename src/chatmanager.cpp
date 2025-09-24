#include "chatmanager.h"

#define DEBUG_MODULE ChatManagerAndModel
#include "debuglog.h"

#include "chatdata.h"

namespace {
    const QString _TYPE("@type");
    const QString ID("id");
    const QString SMALL("small");
    const QString USER_ID("user_id");
    const QString CHAT_ID("chat_id");
    const QString PHOTO("photo");
    const QString LAST_READ_INBOX_MESSAGE_ID("last_read_inbox_message_id");
    const QString LAST_READ_OUTBOX_MESSAGE_ID("last_read_outbox_message_id");
    const QString LAST_MESSAGE("last_message");
    const QString TYPE("type");
    const QString IS_CHANNEL("is_channel");
    const QString BASIC_GROUP_ID("basic_group_id");
    const QString SUPERGROUP_ID("supergroup_id");
    const char* PROPERTY_CHAT_INFORMATION = "chatInformation";
}

ChatMessagesModel::ChatMessagesModel(TDLibWrapper *tdLibWrapper, QObject *parent) : ReadableMessagesModel(tdLibWrapper, parent), searchQuery() {}

bool ChatMessagesModel::clear() {
    LOG("Clearing chat model");
    this->searchQuery.clear();
    return ReadableMessagesModel::clear();
}

void ChatMessagesModel::loadMessages(qlonglong fromMessageId, int offset) {
    if (searchQuery.isEmpty())
        this->tdLibWrapper->getChatHistory(chatId, fromMessageId, offset);
    else
        // ignore offset for now
        this->tdLibWrapper->searchChatMessages(chatId, searchQuery, fromMessageId);
}

void ChatMessagesModel::setSearchQuery(const QString newSearchQuery) {
    if (this->searchQuery != newSearchQuery) {
        this->clear();
        this->searchQuery = newSearchQuery;
        this->loadMessages(searchQuery.isEmpty() ? this->parent()->property(PROPERTY_CHAT_INFORMATION).toMap().value(LAST_READ_INBOX_MESSAGE_ID).toLongLong() : 0); // fixme
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



ChatManager::ChatManager(TDLibWrapper *tdLibWrapper, QObject *parent) :
    QObject(parent),
    tdLibWrapper(tdLibWrapper),
    chatId(0),
    pinnedMessageId(0),
    chatMessagesModel(new ChatMessagesModel(tdLibWrapper, this)),
    mediaMessagesModel(new MediaMessagesModel(tdLibWrapper, this)),
    forumTopicsModel(new ForumTopicsModel(tdLibWrapper, this))
{
    connect(this->tdLibWrapper, &TDLibWrapper::chatRolesUpdated, this, &ChatManager::handleChatRolesUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatPinnedMessageUpdated, this, &ChatManager::handleChatPinnedMessageUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatActionUpdated, this, &ChatManager::handleChatActionUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::userUpdated, this, &ChatManager::handleUserUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::basicGroupUpdated, this, &ChatManager::handleBasicGroupUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::superGroupUpdated, this, &ChatManager::handleSupergroupUpdated);

    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::userInfoChanged);
    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::groupInfoChanged);
}

QVariantMap ChatManager::smallPhoto() const {
    return chatInformation().value(PHOTO).toMap().value(SMALL).toMap();
}

TDLibWrapper::ChatType ChatManager::chatType() const {
    ChatData* chatData = tdLibWrapper->getChatData(chatId);
    if (chatData)
        return chatData->chatType;
    return TDLibWrapper::ChatTypeUnknown;
}

bool ChatManager::isChannel() const {
    return chatType() == TDLibWrapper::ChatTypeSupergroup && tdLibWrapper->getChat(chatId).value(TYPE).toMap().value(IS_CHANNEL).toBool();
}

qlonglong ChatManager::userId() const {
    return tdLibWrapper->getChat(chatId).value(TYPE).toMap().value(USER_ID).toLongLong();
}

qlonglong ChatManager::groupId() const {
    return tdLibWrapper->getChat(chatId).value(TYPE).toMap().value(chatType() == TDLibWrapper::ChatTypeSupergroup ? SUPERGROUP_ID : BASIC_GROUP_ID).toLongLong();
}

QVariantMap ChatManager::userInfo() const {
    const TDLibWrapper::ChatType type = chatType();
    if (type == TDLibWrapper::ChatTypePrivate || type == TDLibWrapper::ChatTypeSecret)
        return tdLibWrapper->getUserInformation(QString::number(this->userId()));
    return QVariantMap();
}

QVariantMap ChatManager::groupInfo() const {
    const TDLibWrapper::ChatType type = chatType();
    if (type == TDLibWrapper::ChatTypeBasicGroup)
        return tdLibWrapper->getBasicGroup(groupId());
    if (type == TDLibWrapper::ChatTypeSupergroup)
        return tdLibWrapper->getSuperGroup(groupId());
    return QVariantMap();
}

void ChatManager::handleUserUpdated(const QString &userId) {
    if (this->userId() == userId.toLongLong())
        emit userInfoChanged();
}

void ChatManager::handleBasicGroupUpdated(qlonglong groupId) {
    if (chatType() == TDLibWrapper::ChatTypeBasicGroup && this->groupId() == groupId)
        emit groupInfoChanged();
}

void ChatManager::handleSupergroupUpdated(qlonglong groupId) {
    if (chatType() == TDLibWrapper::ChatTypeSupergroup && this->groupId() == groupId)
        emit groupInfoChanged();
}

void ChatManager::handleChatRolesUpdated(qlonglong chatId, const QVector<int> changedRoles) {
    if (this->chatId == chatId) {
        if (changedRoles.contains(ChatData::RolePhotoSmall)) {
            LOG("Chat photo updated" << chatId);
            emit smallPhotoChanged();
        }
        LOG("Chat roles updated" << chatId << changedRoles);
        emit chatInformationChanged();
    }
}

void ChatManager::handleChatPinnedMessageUpdated(qlonglong id, qlonglong pinnedMessageId) {
    if (id == chatId) {
        LOG("Pinned message updated" << chatId);
        this->pinnedMessageId = pinnedMessageId;
        emit pinnedMessageChanged();
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


void ChatManager::reset() {
    LOG("Resetting chat manager");
    this->chatMessagesModel->reset();
    this->mediaMessagesModel->reset();
    this->forumTopicsModel->reset();

    chatId = 0;
    emit chatIdChanged();
    emit smallPhotoChanged();
    emit chatInformationChanged();

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
    LOG("Initializing chat manager..." << chatId << "from message id" << fromMessageId);

    reset();
    this->chatId = chatId;
    emit chatIdChanged();
    emit smallPhotoChanged();
    emit chatInformationChanged();
    emit isForumChanged();

    if (isForum()) {
        LOG("Initializing a forum chat");
        forumTopicsModel->init(chatId);
    } else {
        LOG("Initializing a regular chat");
        chatMessagesModel->chatId = chatId;
        chatMessagesModel->chatIdChanged();
        emit chatMessagesModel->historyEndLoadedChanged();

        tdLibWrapper->getChatHistory(chatId, fromMessageId != 0 ? fromMessageId : this->chatInformation().value(LAST_READ_INBOX_MESSAGE_ID).toLongLong());
    }
}



void ChatManager::initializeMediaMessagesModel() {
    this->mediaMessagesModel->init(this->chatId);
}

bool ChatManager::isForum() {
    // TODO
    return false;
}
