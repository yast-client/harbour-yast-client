#include "forumtopicsmodel.h"

#define DEBUG_MODULE ForumTopicsModel
#include "debuglog.h"

namespace {
    const QString _TYPE("@type");
    const QString INFO("info");
    const QString IS_PINNED("is_pinned");
    const QString UNREAD_COUNT("unread_count");
    const QString LAST_READ_INBOX_MESSAGE_ID("last_read_inbox_message_id");
    const QString LAST_READ_OUTBOX_MESSAGE_ID("last_read_outbox_message_id");
    const QString UNREAD_MENTION_COUNT("unread_mention_count");
    const QString UNREAD_REACTION_COUNT("unread_reaction_count");
    const QString NOTIFICATION_SETTINGS("notification_settings");
    const QString DRAFT_MESSAGE("draft_message");
    const QString MESSAGE_THREAD_ID("message_thread_id");
    const QString NAME("name");
    const QString FORUM_TOPIC_ID("forum_topic_id");
    const QString ID("id");
    const QString ICON("icon");
    const QString COLOR("color");
    const QString CUSTOM_EMOJI_ID("custom_emoji_id");
    const QString CREATOR_ID("creator_id");
    const QString CHAT_ID("chat_id");
    const QString TOPIC_ID("topic_id");
    const QString TYPE_MESSAGE_TOPIC_FORUM("messageTopicForum");
}

ForumTopicsModel::ForumTopicsModel(TDLibWrapper *tdLibWrapper, Utilities *utilities, qlonglong chatId, QObject *parent) :
    QAbstractListModel(parent),
    tdLibWrapper(tdLibWrapper),
    utilities(utilities),
    chatId(0),
    nextOffsetDate(0),
    nextOffsetMessageId(0),
    nextOffsetForumTopicId(0),
    endReached(false)
{
    LOG("Initializing" << chatId);

    connect(tdLibWrapper, &TDLibWrapper::forumTopicsReceived, this, &ForumTopicsModel::handleForumTopicsReceived);
    connect(tdLibWrapper, &TDLibWrapper::forumTopicUpdated, this, &ForumTopicsModel::handleForumTopicUpdated);
    connect(tdLibWrapper, &TDLibWrapper::forumTopicInfoUpdated, this, &ForumTopicsModel::handleForumTopicInfoUpdated);
    connect(tdLibWrapper, &TDLibWrapper::newMessageReceived, this, &ForumTopicsModel::handleNewMessageReceived);
    connect(tdLibWrapper, &TDLibWrapper::forumTopicReceived, this, &ForumTopicsModel::handleForumTopicReceived);

    this->chatId = chatId;
    this->tdLibWrapper->getForumTopics(chatId);
}

QHash<int,QByteArray> ForumTopicsModel::roleNames() const {
    return QHash<int,QByteArray>{
        {ForumTopic::RoleDisplay, "display"},
        {ForumTopic::RoleId, "forum_topic_id"},
        {ForumTopic::RoleName, "name"},
        {ForumTopic::RoleIconColor, "icon_color"},
        {ForumTopic::RoleIconCustomEmojiId, "icon_custom_emoji_id"},
        {ForumTopic::RoleCreationDate, "creation_date"},
        {ForumTopic::RoleCreatorIsChat, "creator_is_chat"},
        {ForumTopic::RoleCreatorUserId, "creator_user_id"},
        {ForumTopic::RoleCreatorChatId, "creator_chat_id"},
        {ForumTopic::RoleIsGeneral, "is_general"},
        {ForumTopic::RoleIsOutgoing, "is_outgoing"},
        {ForumTopic::RoleIsClosed, "is_closed"},
        {ForumTopic::RoleIsHidden, "is_hidden"},
        {ForumTopic::RoleIsNameImplicit, "is_name_implicit"},
        {ForumTopic::RoleLastMessageSenderId, "last_message_sender_id"},
        {ForumTopic::RoleLastMessageDate, "last_message_date"},
        {ForumTopic::RoleLastMessageText, "last_message_text"},
        {ForumTopic::RoleLastMessageMinithumbnail, "last_message_minithumbnail"},
        {ForumTopic::RoleLastMessageIsService, "last_message_is_service"},
        {ForumTopic::RoleLastMessageStatus, "last_message_status"},
        {ForumTopic::RoleIsPinned, "is_pinned"},
        {ForumTopic::RoleUnreadCount, "unread_count"},
        {ForumTopic::RoleUnreadMentionCount, "unread_mention_count"},
        {ForumTopic::RoleUnreadReactionCount, "unread_reaction_count"},
        {ForumTopic::RoleNotificationSettings, "notification_settings"},
        {ForumTopic::RoleDraftMessageDate, "draft_message_date"},
        {ForumTopic::RoleDraftMessageText, "draft_message_text"}
    };
}

int ForumTopicsModel::rowCount(const QModelIndex &) const {
    return topics.size();
}

QVariant ForumTopicsModel::data(const QModelIndex &index, int role) const {
    const int row = index.row();
    if (row >= 0 && row < topics.size()) {
        const ForumTopic *topic = topics.at(row);
        switch (role) {
        case ForumTopic::RoleDisplay:
            return topic->data;
        case ForumTopic::RoleId:
            return topic->id;
        case ForumTopic::RoleName:
            return topic->info(NAME).toString();
        case ForumTopic::RoleIconColor:
            return topic->info(ICON).toMap().value(COLOR).toInt();
        case ForumTopic::RoleIconCustomEmojiId:
            return topic->info(ICON).toMap().value(CUSTOM_EMOJI_ID).toLongLong();
        case ForumTopic::RoleCreationDate:
            return topic->info("creation_date").toInt();
        case ForumTopic::RoleCreatorIsChat:
            return topic->info(CREATOR_ID).toMap().value(_TYPE).toString() == "messageSenderChat";
        case ForumTopic::RoleCreatorUserId:
            return topic->info(CREATOR_ID).toMap().value("user_id");
        case ForumTopic::RoleCreatorChatId:
            return topic->info(CREATOR_ID).toMap().value("chat_id");
        case ForumTopic::RoleIsGeneral:
            return topic->info("is_general").toBool();
        case ForumTopic::RoleIsOutgoing:
            return topic->info("is_outgoing").toBool();
        case ForumTopic::RoleIsClosed:
            return topic->info("is_closed").toBool();
        case ForumTopic::RoleIsHidden:
            return topic->info("is_hidden").toBool();
        case ForumTopic::RoleIsNameImplicit:
            return topic->info("is_name_implicit").toBool();

        case ForumTopic::RoleLastMessageSenderId: return topic->lastMessageSenderUserId();
        case ForumTopic::RoleLastMessageText: return topic->lastMessageText();
        case ForumTopic::RoleLastMessageMinithumbnail: return topic->lastMessageMinithumbnail();
        case ForumTopic::RoleLastMessageIsService: return topic->lastMessageIsService();
        case ForumTopic::RoleLastMessageDate: return topic->lastMessageDate();
        case ForumTopic::RoleLastMessageStatus: return topic->lastMessageStatus();

        case ForumTopic::RoleIsPinned: return topic->isPinned();
        case ForumTopic::RoleUnreadCount: return topic->unreadCount();
        case ForumTopic::RoleUnreadMentionCount: return topic->unreadCount();
        case ForumTopic::RoleUnreadReactionCount: return topic->unreadCount();
        case ForumTopic::RoleDraftMessageDate: return topic->draftMessageDate();
        case ForumTopic::RoleDraftMessageText: return topic->draftMessageText();

        default:
            return QVariant();
        }
    }
    return QVariant();
}

void ForumTopicsModel::reset() {
    LOG("Resetting");
    chatId = 0;
    nextOffsetDate = 0;
    nextOffsetMessageId = 0;
    nextOffsetForumTopicId = 0;
    emit chatIdChanged();
}

void ForumTopicsModel::loadMore() {
    if (chatId != 0 && nextOffsetDate != 0 && nextOffsetMessageId != 0 && nextOffsetForumTopicId != 0) {
        if (endReached)
            LOG("End was reached, not loading more");
        else {
            LOG("Loading more");
            this->tdLibWrapper->getForumTopics(chatId, nextOffsetDate, nextOffsetMessageId, nextOffsetForumTopicId);
        }
    }
}

void ForumTopicsModel::handleForumTopicsReceived(qlonglong chatId, int totalCount, QVariantList newTopics, qint32 nextOffsetDate, qlonglong nextOffsetMessageId, int nextOffsetForumTopicId) {
    if (this->chatId == chatId) {
        if (newTopics.isEmpty()) {
            LOG("End was reached");
            endReached = true;
            emit forumTopicsReceived();
            return;
        }

        QList<ForumTopic*> newForumTopics;

        LOG("Forum topics received" << totalCount << newTopics.length());
        for (const QVariant &topicVariant : newTopics)
            newForumTopics.append(new ForumTopic(tdLibWrapper, utilities, topicVariant.toMap()));

        std::sort(newForumTopics.begin(), newForumTopics.end(), ForumTopic::lessThan);

        beginInsertRows(QModelIndex(), topics.length(), topics.length() + newForumTopics.length() - 1);
        const int oldSize = this->topics.length();
        this->topics.append(newForumTopics);
        for (int i = 0; i < newForumTopics.length(); i++)
            this->topicIndexMap.insert(newForumTopics.at(i)->id, oldSize + i);
        endInsertRows();

        this->nextOffsetDate = nextOffsetDate;
        this->nextOffsetMessageId = nextOffsetMessageId;
        this->nextOffsetForumTopicId = nextOffsetForumTopicId;

        emit forumTopicsReceived();
    }
}

void ForumTopicsModel::handleForumTopicUpdated(qlonglong chatId, int forumTopicId, const QVariantMap &update) {
    if (this->chatId == chatId && topicIndexMap.contains(forumTopicId)) {
        LOG("Forum topic updated" << chatId << forumTopicId);

        const int topicIndex = topicIndexMap.value(forumTopicId);
        ForumTopic *topic = this->topics.value(topicIndex);
        const QVector<int> changedRoles = topic->updateFromForumTopicUpdate(update);

        if (!changedRoles.isEmpty()) {
            const QModelIndex modelIndex = index(topicIndex);
            emit dataChanged(modelIndex, modelIndex, changedRoles);
            emit forumTopicUpdated(forumTopicId, changedRoles);
        }
    }
}

void ForumTopicsModel::handleForumTopicInfoUpdated(qlonglong chatId, int forumTopicId, const QVariantMap &info) {
    if (this->chatId == chatId && topicIndexMap.contains(forumTopicId)) {
        LOG("Forum topic info updated" << chatId << forumTopicId);

        const int topicIndex = topicIndexMap.value(forumTopicId);
        ForumTopic *topic = this->topics.value(topicIndex);
        const QVector<int> changedRoles = topic->updateForumTopicInfo(info);

        if (!changedRoles.isEmpty()) {
            const QModelIndex modelIndex = index(topicIndex);
            emit dataChanged(modelIndex, modelIndex, changedRoles);
            emit forumTopicUpdated(forumTopicId, changedRoles);
        }
    }
}

void ForumTopicsModel::insertNewTopic(const QVariantMap &topic) {
    ForumTopic* forumTopic = new ForumTopic(tdLibWrapper, utilities, topic);

    // Actually add the topic to list
    const int n = this->topics.size();
    int pos;
    for (pos = 0; pos < n && ForumTopic::lessThan(forumTopic, topics.at(pos)); pos++);
    LOG("Adding topic" << forumTopic->id << "at" << pos);

    beginInsertRows(QModelIndex(), pos, pos);
    topics.insert(pos, forumTopic);
    topicIndexMap.insert(forumTopic->id, pos);
    // Update damaged part of the map
    for (int i = pos + 1; i <= n; i++)
        topicIndexMap.insert(topics.at(i)->id, i);
    endInsertRows();

    //enableRefreshTimer(); // TODO: add refresh timer here as well
}

void ForumTopicsModel::handleNewMessageReceived(qlonglong chatId, const QVariantMap &message) {
    const QVariantMap topicId = message.value(TOPIC_ID).toMap();
    if (this->chatId != message.value(CHAT_ID).toLongLong() || topicId.value(_TYPE).toString() != TYPE_MESSAGE_TOPIC_FORUM)
        return;

    int forumTopicId = topicId.value(FORUM_TOPIC_ID).toInt();

    if (topicIndexMap.contains(forumTopicId)) {
        int forumTopicIndex = topicIndexMap.value(forumTopicId);
        ForumTopic *topic = topics.at(forumTopicIndex);
        const QModelIndex modelIndex = index(forumTopicIndex);
        emit dataChanged(modelIndex, modelIndex, topic->updateLastMessage(message));
        // TODO: update order
    } else
        // Load the topic in case it's not yet loaded but a new message is received, or if it was just created
        tdLibWrapper->getForumTopic(chatId, forumTopicId); // New topic
}

void ForumTopicsModel::handleForumTopicReceived(qlonglong chatId, int forumTopicId, const QVariantMap &topic) {
    if (this->chatId != chatId)
        return;

    if (topicIndexMap.contains(forumTopicId)) {
        int forumTopicIndex = topicIndexMap.value(forumTopicId);
        ForumTopic *forumTopic = topics.at(forumTopicIndex);
        const QModelIndex modelIndex = index(forumTopicIndex);
        emit dataChanged(modelIndex, modelIndex, forumTopic->updateForumTopicData(topic));
        // TODO: update order
    } else
        insertNewTopic(topic);
}
