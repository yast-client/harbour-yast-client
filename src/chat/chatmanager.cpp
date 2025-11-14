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

    const QString CONTENT_MESSAGE_PHOTO("messagePhoto");
    const QString CONTENT_MESSAGE_VIDEO("messageVideo");
    const QString CONTENT_MESSAGE_ANIMATION("messageAnimation");
    const QString CONTENT_MESSAGE_VIDEO_NOTE("messageVideoNote");
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
    photoAndVideoMessagesModel(new MediaMessagesModel(tdLibWrapper, TDLibWrapper::SearchMessagesFilterPhotoAndVideo, QStringList{CONTENT_MESSAGE_PHOTO, CONTENT_MESSAGE_VIDEO}, this)),
    animationMessagesModel(new MediaMessagesModel(tdLibWrapper, TDLibWrapper::SearchMessagesFilterAnimation, CONTENT_MESSAGE_ANIMATION, this)),
    videoNoteMessagesModel(new MediaMessagesModel(tdLibWrapper, TDLibWrapper::SearchMessagesFilterVideoNote, CONTENT_MESSAGE_VIDEO_NOTE, this)),
    topicsModel(new ForumTopicsModel(tdLibWrapper, this))
{
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadInboxUpdated, this, &ChatManager::handleChatReadInboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatReadOutboxUpdated, this, &ChatManager::handleChatReadOutboxUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatRolesUpdated, this, &ChatManager::handleChatRolesUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatPinnedMessageUpdated, this, &ChatManager::handleChatPinnedMessageUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::chatActionUpdated, this, &ChatManager::handleChatActionUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::userUpdated, this, &ChatManager::handleUserUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::basicGroupUpdated, this, &ChatManager::handleBasicGroupUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::superGroupUpdated, this, &ChatManager::handleSupergroupUpdated);

    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::smallPhotoChanged);
    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::chatInformationChanged);
    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::viewAsTopicsChanged);
    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::userInfoChanged);
    connect(this, &ChatManager::chatIdChanged, this, &ChatManager::groupInfoChanged);
}

void ChatManager::handleChatReadInboxUpdated(const QString &id) {
    if (this->chatId == id.toLongLong())
        emit this->chatMessagesModel->lastReadMessageIndexChanged();
}

void ChatManager::handleChatReadOutboxUpdated(const QString &id) {
    if (this->chatId == id.toLongLong())
        emit this->chatMessagesModel->lastReadSentMessageUpdated();
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

QVariant ChatManager::userInfo() const {
    const TDLibWrapper::ChatType type = chatType();
    if (type == TDLibWrapper::ChatTypePrivate || type == TDLibWrapper::ChatTypeSecret)
        return tdLibWrapper->getUserInformation(QString::number(this->userId()));
    return QVariant();
}

QVariant ChatManager::groupInfo() const {
    const TDLibWrapper::ChatType type = chatType();
    if (type == TDLibWrapper::ChatTypeBasicGroup)
        return tdLibWrapper->getBasicGroup(groupId());
    if (type == TDLibWrapper::ChatTypeSupergroup)
        return tdLibWrapper->getSuperGroup(groupId());
    return QVariant();
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


void ChatManager::reset(bool resetChatId) {
    LOG("Resetting chat manager resetChatId" << resetChatId);
    this->chatMessagesModel->reset();
    this->photoAndVideoMessagesModel->reset();
    this->animationMessagesModel->reset();
    this->videoNoteMessagesModel->reset();
    this->topicsModel->reset();

    if (resetChatId) {
        chatId = 0;
        emit chatIdChanged();
    }

    if (!chatActionsByUsers.isEmpty()) {
        chatActionsByUsers.clear();
        emit chatActionsChanged();
    }
    if (!chatActionsByChats.isEmpty()) {
        chatActionsByChats.clear();
        emit chatActionsChanged();
    }
    LOG("Finished resetting chat manager" << resetChatId);
}

void ChatManager::doBasicInitialization(const QVariantMap &chatInformation) {
    const qlonglong chatId = chatInformation.value(ID).toLongLong();
    LOG("Doing basic chat manager initialization..." << chatId);

    if (this->chatId != chatId) {
        this->chatId = chatId;
        emit chatIdChanged();
    }
}

void ChatManager::initialize(const QVariantMap &chatInformation, qlonglong fromMessageId) {
    doBasicInitialization(chatInformation);
    LOG("Continuing with full initialization" << chatId << "from message id" << fromMessageId);

    reset(false);
    LOG("Reset for initialization done" << chatId);

    if (viewAsTopics()) {
        LOG("Initializing a forum chat");
        topicsModel->init(chatId);
    } else {
        LOG("Initializing a regular chat");
        chatMessagesModel->chatId = chatId;
        emit chatMessagesModel->chatIdChanged();

        tdLibWrapper->getChatHistory(chatId, fromMessageId != 0 ? fromMessageId : this->chatInformation().value(LAST_READ_INBOX_MESSAGE_ID).toLongLong());
    }
}



void ChatManager::initializeMediaMessagesModel(MediaMessagesModel* model, qlonglong fromMessageId) {
    model->init(this->chatId, fromMessageId);
}

bool ChatManager::viewAsTopics() {
    // TODO
    return false;
}
