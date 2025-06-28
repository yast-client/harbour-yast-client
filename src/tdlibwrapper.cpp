/*
    Copyright (C) 2020-22 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/

#include "tdlibwrapper.h"
#include "tdlibsecrets.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QProcess>
#include <QSysInfo>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QRegularExpression>
#include <QRegularExpressionMatch>
#include <QRegularExpressionMatchIterator>

#define DEBUG_MODULE TDLibWrapper
#include "debuglog.h"

#define VERSION_NUMBER(x,y,z) \
    ((((x) & 0x3ff) << 20) | (((y) & 0x3ff) << 10) | ((z) & 0x3ff))

namespace {
    const QString STATUS("status");
    const QString ID("id");
    const QString CHAT_ID("chat_id");
    const QString USER_ID("user_id");
    const QString MESSAGE_ID("message_id");
    const QString TYPE("type");
    const QString LAST_NAME("last_name");
    const QString FIRST_NAME("first_name");
    const QString USERNAME("username");
    const QString USERNAMES("usernames");
    const QString EDITABLE_USERNAME("editable_username");
    const QString THREAD_ID("thread_id");
    const QString VALUE("value");
    const QString CHAT_LIST_TYPE("chat_list_type");
    const QString REPLY_TO_MESSAGE_ID("reply_to_message_id");
    const QString REPLY_TO("reply_to");
    const QString _TYPE("@type");
    const QString _EXTRA("@extra");
    const QString CHAT_LIST_MAIN("chatListMain");
    const QString CHAT_AVAILABLE_REACTIONS("available_reactions");
    const QString CHAT_AVAILABLE_REACTIONS_ALL("chatAvailableReactionsAll");
    const QString CHAT_AVAILABLE_REACTIONS_SOME("chatAvailableReactionsSome");
    const QString REACTIONS("reactions");
    const QString REACTION_TYPE("reaction_type");
    const QString REACTION_TYPE_EMOJI("reactionTypeEmoji");
    const QString EMOJI("emoji");
    const QString TYPE_MESSAGE_REPLY_TO_MESSAGE("messageReplyToMessage");
    const QString TYPE_INPUT_MESSAGE_REPLY_TO_MESSAGE("inputMessageReplyToMessage");
    const QString TEXT("text");
    const QString TRANSLATION("translation");
    const QString CONTACT("contact");
    const QString PHONE_NUMBER("phone_number");
    const QString REMOVE_CONTACTS("removeContacts");
    const QStringList ALL_FILE_TYPES(QStringList()
                                     << "fileTypeAnimation"
                                     << "fileTypeAudio"
                                     << "fileTypeDocument"
                                     << "fileTypeNone"
                                     << "fileTypeNotificationSound"
                                     << "fileTypePhoto"
                                     << "fileTypePhotoStory"
                                     << "fileTypeProfilePhoto"
                                     << "fileTypeSecret"
                                     << "fileTypeSecretThumbnail"
                                     << "fileTypeSecure"
                                     << "fileTypeSelfDestructingPhoto"
                                     << "fileTypeSelfDestructingVideo"
                                     << "fileTypeSelfDestructingVideoNote"
                                     << "fileTypeSelfDestructingVoiceNote"
                                     << "fileTypeSticker"
                                     << "fileTypeThumbnail"
                                     << "fileTypeUnknown"
                                     << "fileTypeVideo"
                                     << "fileTypeVideoNote"
                                     << "fileTypeVideoStory"
                                     << "fileTypeVoiceNote"
                                     << "fileTypeWallpaper"
    );
}

TDLibWrapper::TDLibWrapper(AppSettings *settings, MceInterface *mce, QObject *parent)
    : QObject(parent)
    , tdLibClient(td_json_client_create())
    , manager(new QNetworkAccessManager(this))
    , networkConfigurationManager(new QNetworkConfigurationManager(this))
    , appSettings(settings)
    , mceInterface(mce)
    , authorizationState(AuthorizationState::Closed)
    , versionNumber(0)
    , joinChatRequested(false)
    , isLoggingOut(false)
{
    LOG("Initializing TD Lib...");

    initializeTDLibReceiver();

    QString tdLibDatabaseDirectoryPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/tdlib";
    QDir tdLibDatabaseDirectory(tdLibDatabaseDirectoryPath);
    if (!tdLibDatabaseDirectory.exists()) {
        tdLibDatabaseDirectory.mkpath(tdLibDatabaseDirectoryPath);
    }

    this->dbusInterface = new DBusInterface(this);
    if (appSettings->getUseOpenWith()) {
        initializeOpenWith();
    } else {
        removeOpenWith();
    }

    connect(&emojiSearchWorker, &EmojiSearchWorker::searchCompleted, this, &TDLibWrapper::handleEmojiSearchCompleted);

    connect(appSettings, &AppSettings::useOpenWithChanged, this, &TDLibWrapper::handleOpenWithChanged);
    connect(appSettings, &AppSettings::storageOptimizerChanged, this, &TDLibWrapper::handleStorageOptimizerChanged);

    connect(networkConfigurationManager, &QNetworkConfigurationManager::configurationChanged, this, &TDLibWrapper::handleNetworkConfigurationChanged);

    this->setLogVerbosityLevel();
    this->setOptionInteger("notification_group_count_max", 5);
    this->handleStorageOptimizerChanged(); // set the initial optimizer state
}

TDLibWrapper::~TDLibWrapper()
{
    LOG("Destroying TD Lib...");
    this->tdLibReceiver->setActive(false);
    while (this->tdLibReceiver->isRunning()) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 1000);
    }
    qDeleteAll(basicGroups.values());
    qDeleteAll(superGroups.values());
    td_json_client_destroy(this->tdLibClient);
}

void TDLibWrapper::initializeTDLibReceiver() {
    this->tdLibReceiver = new TDLibReceiver(this->tdLibClient, this);
    connect(this->tdLibReceiver, &TDLibReceiver::versionDetected, this, &TDLibWrapper::handleVersionDetected);
    connect(this->tdLibReceiver, &TDLibReceiver::authorizationStateChanged, this, &TDLibWrapper::handleAuthorizationStateChanged);
    connect(this->tdLibReceiver, &TDLibReceiver::optionUpdated, this, &TDLibWrapper::handleOptionUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::connectionStateChanged, this, &TDLibWrapper::handleConnectionStateChanged);
    connect(this->tdLibReceiver, &TDLibReceiver::userUpdated, this, &TDLibWrapper::handleUserUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::userStatusUpdated, this, &TDLibWrapper::handleUserStatusUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::fileUpdated, this, &TDLibWrapper::handleFileUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::newChatDiscovered, this, &TDLibWrapper::handleNewChatDiscovered);
    connect(this->tdLibReceiver, &TDLibReceiver::unreadMessageCountUpdated, this, &TDLibWrapper::handleUnreadMessageCountUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::unreadChatCountUpdated, this, &TDLibWrapper::handleUnreadChatCountUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatLastMessageUpdated, this, &TDLibWrapper::chatLastMessageUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatOrderUpdated, this, &TDLibWrapper::chatOrderUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatReadInboxUpdated, this, &TDLibWrapper::chatReadInboxUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatReadOutboxUpdated, this, &TDLibWrapper::chatReadOutboxUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatAvailableReactionsUpdated, this, &TDLibWrapper::handleAvailableReactionsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::basicGroupUpdated, this, &TDLibWrapper::handleBasicGroupUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::superGroupUpdated, this, &TDLibWrapper::handleSuperGroupUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatOnlineMemberCountUpdated, this, &TDLibWrapper::chatOnlineMemberCountUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::messagesReceived, this, &TDLibWrapper::messagesReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::sponsoredMessageReceived, this, &TDLibWrapper::handleSponsoredMessage);
    connect(this->tdLibReceiver, &TDLibReceiver::messageLinkInfoReceived, this, &TDLibWrapper::messageLinkInfoReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::newMessageReceived, this, &TDLibWrapper::newMessageReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::messageInformation, this, &TDLibWrapper::handleMessageInformation);
    connect(this->tdLibReceiver, &TDLibReceiver::messageSendSucceeded, this, &TDLibWrapper::messageSendSucceeded);
    connect(this->tdLibReceiver, &TDLibReceiver::activeNotificationsUpdated, this, &TDLibWrapper::activeNotificationsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::notificationGroupUpdated, this, &TDLibWrapper::notificationGroupUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::notificationUpdated, this, &TDLibWrapper::notificationUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatNotificationSettingsUpdated, this, &TDLibWrapper::chatNotificationSettingsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::messageContentUpdated, this, &TDLibWrapper::messageContentUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::messagesDeleted, this, &TDLibWrapper::messagesDeleted);
    connect(this->tdLibReceiver, &TDLibReceiver::chats, this, &TDLibWrapper::chatsReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::chat, this, &TDLibWrapper::handleChatReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::secretChat, this, &TDLibWrapper::handleSecretChatReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::secretChatUpdated, this, &TDLibWrapper::handleSecretChatUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::recentStickersUpdated, this, &TDLibWrapper::recentStickersUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::stickers, this, &TDLibWrapper::stickersReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::installedStickerSetsUpdated, this, &TDLibWrapper::installedStickerSetsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::stickerSets, this, &TDLibWrapper::handleStickerSets);
    connect(this->tdLibReceiver, &TDLibReceiver::stickerSet, this, &TDLibWrapper::stickerSetReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::chatMembers, this, &TDLibWrapper::chatMembersReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::userFullInfo, this, &TDLibWrapper::userFullInfoReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::userFullInfoUpdated, this, &TDLibWrapper::userFullInfoUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::basicGroupFullInfo, this, &TDLibWrapper::basicGroupFullInfoReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::basicGroupFullInfoUpdated, this, &TDLibWrapper::basicGroupFullInfoUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::supergroupFullInfo, this, &TDLibWrapper::supergroupFullInfoReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::supergroupFullInfoUpdated, this, &TDLibWrapper::supergroupFullInfoUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::userProfilePhotos, this, &TDLibWrapper::userProfilePhotosReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::chatPermissionsUpdated, this, &TDLibWrapper::chatPermissionsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatPhotoUpdated, this, &TDLibWrapper::chatPhotoUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatTitleUpdated, this, &TDLibWrapper::chatTitleUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatPinnedUpdated, this, &TDLibWrapper::chatPinnedUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatPinnedMessageUpdated, this, &TDLibWrapper::chatPinnedMessageUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::messageIsPinnedUpdated, this, &TDLibWrapper::handleMessageIsPinnedUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::usersReceived, this, &TDLibWrapper::usersReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::messageSendersReceived, this, &TDLibWrapper::messageSendersReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::errorReceived, this, &TDLibWrapper::handleErrorReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::contactsImported, this, &TDLibWrapper::contactsImported);
    connect(this->tdLibReceiver, &TDLibReceiver::messageEditedUpdated, this, &TDLibWrapper::messageEditedUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatIsMarkedAsUnreadUpdated, this, &TDLibWrapper::chatIsMarkedAsUnreadUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatDraftMessageUpdated, this, &TDLibWrapper::chatDraftMessageUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::inlineQueryResults, this, &TDLibWrapper::inlineQueryResults);
    connect(this->tdLibReceiver, &TDLibReceiver::callbackQueryAnswer, this, &TDLibWrapper::callbackQueryAnswer);
    connect(this->tdLibReceiver, &TDLibReceiver::userPrivacySettingRules, this, &TDLibWrapper::handleUserPrivacySettingRules);
    connect(this->tdLibReceiver, &TDLibReceiver::userPrivacySettingRulesUpdated, this, &TDLibWrapper::handleUpdatedUserPrivacySettingRules);
    connect(this->tdLibReceiver, &TDLibReceiver::messageInteractionInfoUpdated, this, &TDLibWrapper::messageInteractionInfoUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::okReceived, this, &TDLibWrapper::okReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::okMapReceived, this, &TDLibWrapper::okMapReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::sessionsReceived, this, &TDLibWrapper::sessionsReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::availableReactionsReceived, this, &TDLibWrapper::availableReactionsReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::chatUnreadMentionCountUpdated, this, &TDLibWrapper::chatUnreadMentionCountUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::chatUnreadReactionCountUpdated, this, &TDLibWrapper::chatUnreadReactionCountUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::activeEmojiReactionsUpdated, this, &TDLibWrapper::handleActiveEmojiReactionsUpdated);
    connect(this->tdLibReceiver, &TDLibReceiver::messagePropertiesReceived, this, &TDLibWrapper::messagePropertiesReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::storageStatisticsFastReceived, this, &TDLibWrapper::storageStatisticsFastReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::storageStatisticsReceived, this, &TDLibWrapper::storageStatisticsReceived);
    connect(this->tdLibReceiver, &TDLibReceiver::translationResultReceived, this, &TDLibWrapper::translationResultReceived);

    this->tdLibReceiver->start();
}

void TDLibWrapper::sendRequest(const QVariantMap &requestObject)
{
    if (this->isLoggingOut) {
        LOG("Sending request to TD Lib skipped as logging out is in progress, object type name:" << requestObject.value(_TYPE).toString());
        return;
    }
    LOG("Sending request to TD Lib, object type name:" << requestObject.value(_TYPE).toString());
    QJsonDocument requestDocument = QJsonDocument::fromVariant(requestObject);
    VERBOSE(requestDocument.toJson().constData());
    td_json_client_send(this->tdLibClient, requestDocument.toJson().constData());
}

QString TDLibWrapper::getVersion()
{
    return this->versionString;
}

TDLibWrapper::AuthorizationState TDLibWrapper::getAuthorizationState()
{
    return this->authorizationState;
}

QVariantMap TDLibWrapper::getAuthorizationStateData()
{
    return this->authorizationStateData;
}

TDLibWrapper::ConnectionState TDLibWrapper::getConnectionState()
{
    return this->connectionState;
}

void TDLibWrapper::setAuthenticationPhoneNumber(const QString &phoneNumber)
{
    LOG("Set authentication phone number " << phoneNumber);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setAuthenticationPhoneNumber");
    requestObject.insert(PHONE_NUMBER, phoneNumber);
    QVariantMap phoneNumberSettings;
    phoneNumberSettings.insert("allow_flash_call", false);
    phoneNumberSettings.insert("is_current_phone_number", true);
    requestObject.insert("settings", phoneNumberSettings);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setAuthenticationCode(const QString &authenticationCode)
{
    LOG("Set authentication code " << authenticationCode);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "checkAuthenticationCode");
    requestObject.insert("code", authenticationCode);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setAuthenticationPassword(const QString &authenticationPassword)
{
    LOG("Set authentication password " << authenticationPassword);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "checkAuthenticationPassword");
    requestObject.insert("password", authenticationPassword);
    this->sendRequest(requestObject);
}

void TDLibWrapper::registerUser(const QString &firstName, const QString &lastName)
{
    LOG("Register User " << firstName << lastName);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "registerUser");
    requestObject.insert(FIRST_NAME, firstName);
    requestObject.insert(LAST_NAME, lastName);
    this->sendRequest(requestObject);
}

void TDLibWrapper::logout()
{
    LOG("Logging out");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "logOut");
    this->sendRequest(requestObject);
    this->isLoggingOut = true;

}

void TDLibWrapper::getChats()
{
    LOG("Getting chats");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "loadChats");
    requestObject.insert("limit", 5);
    this->sendRequest(requestObject);
}

void TDLibWrapper::downloadFile(int fileId)
{
    LOG("Downloading file " << fileId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "downloadFile");
    requestObject.insert("file_id", fileId);
    requestObject.insert("synchronous", false);
    requestObject.insert("offset", 0);
    requestObject.insert("limit", 0);
    requestObject.insert("priority", 1);
    this->sendRequest(requestObject);
}

void TDLibWrapper::openChat(const QString &chatId)
{
    LOG("Opening chat " << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "openChat");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::closeChat(const QString &chatId)
{
    LOG("Closing chat " << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "closeChat");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::joinChat(const QString &chatId)
{
    LOG("Joining chat " << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "joinChat");
    requestObject.insert(CHAT_ID, chatId);
    this->joinChatRequested = true;
    this->sendRequest(requestObject);
}

void TDLibWrapper::leaveChat(const QString &chatId)
{
    LOG("Leaving chat " << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "leaveChat");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::deleteChat(qlonglong chatId)
{
    LOG("Deleting chat " << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "deleteChat");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getChatHistory(qlonglong chatId, qlonglong fromMessageId, int offset, int limit, bool onlyLocal)
{
    LOG("Retrieving chat history" << chatId << fromMessageId << offset << limit << onlyLocal);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getChatHistory");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("from_message_id", fromMessageId);
    requestObject.insert("offset", offset);
    requestObject.insert("limit", limit);
    requestObject.insert("only_local", onlyLocal);
    this->sendRequest(requestObject);
}

void TDLibWrapper::viewMessage(qlonglong chatId, qlonglong messageId, bool force)
{
    LOG("Mark message as viewed" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "viewMessages");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("force_read", force);
    QVariantList messageIds;
    messageIds.append(messageId);
    requestObject.insert("message_ids", messageIds);
    this->sendRequest(requestObject);
}

void TDLibWrapper::pinMessage(const QString &chatId, const QString &messageId, bool disableNotification)
{
    LOG("Pin message to chat" << chatId << messageId << disableNotification);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "pinChatMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("disable_notification", disableNotification);
    this->sendRequest(requestObject);
}

void TDLibWrapper::unpinMessage(const QString &chatId, const QString &messageId)
{
    LOG("Unpin message from chat" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "unpinChatMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert(_EXTRA, "unpinChatMessage:" + chatId);
    this->sendRequest(requestObject);
}

static bool compareReplacements(const QVariant &replacement1, const QVariant &replacement2)
{
    const QVariantMap replacementMap1 = replacement1.toMap();
    const QVariantMap replacementMap2 = replacement2.toMap();

    if (replacementMap1.value("startIndex").toInt() < replacementMap2.value("startIndex").toInt()) {
        return true;
    } else {
        return false;
    }
}

QVariantMap TDLibWrapper::newSendMessageRequest(qlonglong chatId, qlonglong replyToMessageId)
{
    QVariantMap request;
    request.insert(_TYPE, "sendMessage");
    request.insert(CHAT_ID, chatId);
    if (replyToMessageId) {
        QVariantMap replyTo;
        replyTo.insert(_TYPE, TYPE_INPUT_MESSAGE_REPLY_TO_MESSAGE);
        replyTo.insert(MESSAGE_ID, replyToMessageId);
        request.insert(REPLY_TO, replyTo);
    }
    return request;
}

QVariantMap TDLibWrapper::newFormattedText(const QString &text, const QVariantList entities) {
    QVariantMap formattedText;
    formattedText.insert(_TYPE, "formattedText");
    formattedText.insert("text", text);
    if (entities.length() > 0)
        formattedText.insert("entities", entities);
    return formattedText;
}

void TDLibWrapper::sendTextMessage(qlonglong chatId, const QString &message, qlonglong replyToMessageId)
{
    LOG("Sending text message" << chatId << message << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageText");

    // Postprocess message (e.g. for @-mentioning)
    QString processedMessage = message;
    QVariantList replacements;
    QRegularExpression atMentionIdRegex("\\@(\\d+)\\(([^\\)]+)\\)");
    QRegularExpressionMatchIterator atMentionIdMatchIterator = atMentionIdRegex.globalMatch(processedMessage);
    while (atMentionIdMatchIterator.hasNext()) {
        QRegularExpressionMatch nextAtMentionId = atMentionIdMatchIterator.next();
        LOG("@Mentioning with user ID! Start Index: " << nextAtMentionId.capturedStart(0) << ", length: " << nextAtMentionId.capturedLength(0) << ", user ID: " << nextAtMentionId.captured(1) << ", plain text: " << nextAtMentionId.captured(2));
        QVariantMap replacement;
        replacement.insert("startIndex", nextAtMentionId.capturedStart(0));
        replacement.insert("length", nextAtMentionId.capturedLength(0));
        replacement.insert("userId", nextAtMentionId.captured(1));
        replacement.insert("plainText", nextAtMentionId.captured(2));
        replacements.append(replacement);
    }

    QVariantMap formattedText;

    if (!replacements.isEmpty()) {
        QVariantList entities;
        std::sort(replacements.begin(), replacements.end(), compareReplacements);
        QListIterator<QVariant> replacementsIterator(replacements);
        int offsetCorrection = 0;
        while (replacementsIterator.hasNext()) {
            QVariantMap nextReplacement = replacementsIterator.next().toMap();
            int replacementStartOffset = nextReplacement.value("startIndex").toInt();
            int replacementLength = nextReplacement.value("length").toInt();
            QString replacementPlainText = nextReplacement.value("plainText").toString();
            processedMessage = processedMessage.replace(replacementStartOffset - offsetCorrection, replacementLength, replacementPlainText);
            QVariantMap entity;
            entity.insert("offset", replacementStartOffset - offsetCorrection);
            entity.insert("length", replacementPlainText.length());
            QVariantMap entityType;
            entityType.insert(_TYPE, "textEntityTypeMentionName");
            entityType.insert(USER_ID, nextReplacement.value("userId").toString());
            entity.insert(TYPE, entityType);
            entities.append(entity);
            offsetCorrection += replacementLength - replacementPlainText.length();
        }
        formattedText = newFormattedText(processedMessage, entities);
    } else formattedText = newFormattedText(processedMessage);

    inputMessageContent.insert("text", formattedText);
    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendPhotoMessage(qlonglong chatId, const QString &filePath, const QString &message, qlonglong replyToMessageId)
{
    LOG("Sending photo message" << chatId << filePath << message << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessagePhoto");

    inputMessageContent.insert("caption", newFormattedText(message));
    QVariantMap photoInputFile;
    photoInputFile.insert(_TYPE, "inputFileLocal");
    photoInputFile.insert("path", filePath);
    inputMessageContent.insert("photo", photoInputFile);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendVideoMessage(qlonglong chatId, const QString &filePath, const QString &message, qlonglong replyToMessageId)
{
    LOG("Sending video message" << chatId << filePath << message << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageVideo");

    inputMessageContent.insert("caption", newFormattedText(message));
    QVariantMap videoInputFile;
    videoInputFile.insert(_TYPE, "inputFileLocal");
    videoInputFile.insert("path", filePath);
    inputMessageContent.insert("video", videoInputFile);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendDocumentMessage(qlonglong chatId, const QString &filePath, const QString &message, qlonglong replyToMessageId)
{
    LOG("Sending document message" << chatId << filePath << message << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageDocument");

    inputMessageContent.insert("caption", newFormattedText(message));
    QVariantMap documentInputFile;
    documentInputFile.insert(_TYPE, "inputFileLocal");
    documentInputFile.insert("path", filePath);
    inputMessageContent.insert("document", documentInputFile);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendVoiceNoteMessage(qlonglong chatId, const QString &filePath, const QString &message, qlonglong replyToMessageId)
{
    LOG("Sending voice note message" << chatId << filePath << message << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageVoiceNote");

    inputMessageContent.insert("caption", newFormattedText(message));
    QVariantMap documentInputFile;
    documentInputFile.insert(_TYPE, "inputFileLocal");
    documentInputFile.insert("path", filePath);
    inputMessageContent.insert("voice_note", documentInputFile);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendLocationMessage(qlonglong chatId, double latitude, double longitude, double horizontalAccuracy, qlonglong replyToMessageId)
{
    LOG("Sending location message" << chatId << latitude << longitude << horizontalAccuracy << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageLocation");

    QVariantMap location;
    location.insert("latitude", latitude);
    location.insert("longitude", longitude);
    location.insert("horizontal_accuracy", horizontalAccuracy);
    location.insert(_TYPE, "location");
    inputMessageContent.insert("location", location);
    inputMessageContent.insert("live_period", 0);
    inputMessageContent.insert("heading", 0);
    inputMessageContent.insert("proximity_alert_radius", 0);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendStickerMessage(qlonglong chatId, const QString &fileId, qlonglong replyToMessageId)
{
    LOG("Sending sticker message" << chatId << fileId << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageSticker");

    QVariantMap stickerInputFile;
    stickerInputFile.insert(_TYPE, "inputFileRemote");
    stickerInputFile.insert(ID, fileId);

    inputMessageContent.insert("sticker", stickerInputFile);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::sendPollMessage(qlonglong chatId, const QString &question, const QStringList &options, bool anonymous, int correctOption, bool multiple, const QString &explanation, qlonglong replyToMessageId)
{
    LOG("Sending poll message" << chatId << question << replyToMessageId);
    QVariantMap requestObject(newSendMessageRequest(chatId, replyToMessageId));
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessagePoll");

    QVariantMap pollType;
    if(correctOption > -1) {
        pollType.insert(_TYPE, "pollTypeQuiz");
        pollType.insert("correct_option_id", correctOption);
        if(!explanation.isEmpty())
            pollType.insert("explanation", newFormattedText(explanation));
    } else {
        pollType.insert(_TYPE, "pollTypeRegular");
        pollType.insert("allow_multiple_answers", multiple);
    }

    QVariantList formattedOptions;

    for (QString option : options)
        formattedOptions.append(newFormattedText(option));

    inputMessageContent.insert(TYPE, pollType);
    inputMessageContent.insert("question", newFormattedText(question));
    inputMessageContent.insert("options", formattedOptions);
    inputMessageContent.insert("is_anonymous", anonymous);

    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::forwardMessages(const QString &chatId, const QString &fromChatId, const QVariantList &messageIds, bool sendCopy, bool removeCaption)
{
    LOG("Forwarding messages" << chatId << fromChatId << messageIds);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "forwardMessages");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("from_chat_id", fromChatId);
    requestObject.insert("message_ids", messageIds);
    requestObject.insert("send_copy", sendCopy);
    requestObject.insert("remove_caption", removeCaption);

    this->sendRequest(requestObject);
}

void TDLibWrapper::getMessage(qlonglong chatId, qlonglong messageId)
{
    LOG("Retrieving message" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert(_EXTRA, QString("getMessage:%1:%2").arg(chatId).arg(messageId));
    this->sendRequest(requestObject);
}

void TDLibWrapper::getMessageLinkInfo(const QString &url, const QString &extra)
{
    LOG("Retrieving message link info" << url << extra);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getMessageLinkInfo");
    requestObject.insert("url", url);
    if (extra == "") {
        requestObject.insert(_EXTRA, url);
    } else {
        requestObject.insert(_EXTRA, url + "|" + extra);
    }

    this->sendRequest(requestObject);
}

void TDLibWrapper::getExternalLinkInfo(const QString &url, const QString &extra)
{
    LOG("Retrieving external link info" << url << extra);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getExternalLinkInfo");
    requestObject.insert("url", url);
    if (extra == "") {
        requestObject.insert(_EXTRA, url);
    } else {
        requestObject.insert(_EXTRA, url + "|" + extra);
    }

    this->sendRequest(requestObject);
}

void TDLibWrapper::getCallbackQueryAnswer(const QString &chatId, const QString &messageId, const QVariantMap &payload)
{
    LOG("Getting Callback Query Answer" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getCallbackQueryAnswer");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("payload", payload);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getChatPinnedMessage(qlonglong chatId)
{
    LOG("Retrieving pinned message" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getChatPinnedMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(_EXTRA, "getChatPinnedMessage:" + QString::number(chatId));
    this->sendRequest(requestObject);
}

void TDLibWrapper::getChatSponsoredMessage(qlonglong chatId)
{
    LOG("Retrieving sponsored message" << chatId);
    QVariantMap requestObject;
    // getChatSponsoredMessage has been replaced with getChatSponsoredMessages
    // between 1.8.7 and 1.8.8
    // See https://github.com/tdlib/td/commit/ec1310a
    requestObject.insert(_TYPE, QString((versionNumber > VERSION_NUMBER(1,8,7)) ?
        "getChatSponsoredMessages" : "getChatSponsoredMessage"));
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(_EXTRA, chatId); // see TDLibReceiver::processSponsoredMessage
    this->sendRequest(requestObject);
}

void TDLibWrapper::setOptionInteger(const QString &optionName, int optionValue)
{
    LOG("Setting integer option" << optionName << optionValue);
    setOption(optionName, "optionValueInteger", optionValue);
}

void TDLibWrapper::setOptionBoolean(const QString &optionName, bool optionValue)
{
    LOG("Setting boolean option" << optionName << optionValue);
    setOption(optionName, "optionValueBoolean", optionValue);
}

void TDLibWrapper::setOption(const QString &name, const QString &type, const QVariant &value)
{
    QVariantMap optionValue;
    optionValue.insert(_TYPE, type);
    optionValue.insert(VALUE, value);
    QVariantMap request;
    request.insert(_TYPE, "setOption");
    request.insert("name", name);
    request.insert(VALUE, optionValue);
    sendRequest(request);
}

void TDLibWrapper::setChatNotificationSettings(const QString &chatId, const QVariantMap &notificationSettings)
{
    LOG("Notification settings for chat " << chatId << notificationSettings);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatNotificationSettings");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("notification_settings", notificationSettings);
    this->sendRequest(requestObject);
}

void TDLibWrapper::editMessageText(const QString &chatId, const QString &messageId, const QString &message)
{
    LOG("Editing message text" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "editMessageText");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    QVariantMap inputMessageContent;
    inputMessageContent.insert(_TYPE, "inputMessageText");
    QVariantMap formattedText;
    formattedText.insert("text", message);
    inputMessageContent.insert("text", formattedText);
    requestObject.insert("input_message_content", inputMessageContent);
    this->sendRequest(requestObject);
}

void TDLibWrapper::editMessageCaption(const QString &chatId, const QString &messageId, const QString &caption) {
    LOG("Editing message caption" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "editMessageCaption");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("caption", newFormattedText(caption));
    this->sendRequest(requestObject);
}

void TDLibWrapper::deleteMessages(const QString &chatId, const QVariantList messageIds)
{
    LOG("Deleting some messages" << chatId << messageIds);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "deleteMessages");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("message_ids", messageIds);
    requestObject.insert("revoke", true);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getMapThumbnailFile(const QString &chatId, double latitude, double longitude, int width, int height, const QString &extra)
{
    LOG("Getting Map Thumbnail File" << chatId);
    QVariantMap location;
    location.insert("latitude", latitude);
    location.insert("longitude", longitude);
    // ensure dimensions are in bounds (16 - 1024)
    int boundsWidth = std::min(std::max(width, 16), 1024);
    int boundsHeight = std::min(std::max(height, 16), 1024);

    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getMapThumbnailFile");
    requestObject.insert("location", location);
    requestObject.insert("zoom", 17); //13-20
    requestObject.insert("width", boundsWidth);
    requestObject.insert("height", boundsHeight);
    requestObject.insert("scale", 1); // 1-3
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(_EXTRA, extra);

    this->sendRequest(requestObject);
}

void TDLibWrapper::getRecentStickers()
{
    LOG("Retrieving recent stickers");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getRecentStickers");
    this->sendRequest(requestObject);
}

void TDLibWrapper::getInstalledStickerSets()
{
    LOG("Retrieving installed sticker sets");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getInstalledStickerSets");
    this->sendRequest(requestObject);
}

void TDLibWrapper::getStickerSet(const QString &setId)
{
    LOG("Retrieving sticker set" << setId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getStickerSet");
    requestObject.insert("set_id", setId);
    this->sendRequest(requestObject);
}
void TDLibWrapper::getSupergroupMembers(const QString &groupId, int limit, int offset)
{
    LOG("Retrieving SupergroupMembers");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getSupergroupMembers");
    requestObject.insert(_EXTRA, groupId);
    requestObject.insert("supergroup_id", groupId);
    requestObject.insert("offset", offset);
    requestObject.insert("limit", limit);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getGroupFullInfo(const QString &groupId, bool isSuperGroup)
{
    LOG("Retrieving GroupFullInfo");
    QVariantMap requestObject;
    if(isSuperGroup) {
        requestObject.insert(_TYPE, "getSupergroupFullInfo");
        requestObject.insert("supergroup_id", groupId);
    } else {
        requestObject.insert(_TYPE, "getBasicGroupFullInfo");
        requestObject.insert("basic_group_id", groupId);
    }
    requestObject.insert(_EXTRA, groupId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getUserFullInfo(const QString &userId)
{
    LOG("Retrieving UserFullInfo" << userId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getUserFullInfo");
    requestObject.insert(_EXTRA, userId);
    requestObject.insert(USER_ID, userId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::createPrivateChat(const QString &userId, const QString &extra)
{
    LOG("Creating Private Chat");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "createPrivateChat");
    requestObject.insert(USER_ID, userId);
    requestObject.insert(_EXTRA, extra); //"openDirectly"/"openAndSendStartToBot:[optional parameter]" gets matched in qml
    this->sendRequest(requestObject);
}

void TDLibWrapper::createNewSecretChat(const QString &userId, const QString &extra)
{
    LOG("Creating new secret chat");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "createNewSecretChat");
    requestObject.insert(USER_ID, userId);
    requestObject.insert(_EXTRA, extra); //"openDirectly" gets matched in qml
    this->sendRequest(requestObject);
}

void TDLibWrapper::createSupergroupChat(const QString &supergroupId, const QString &extra)
{
    LOG("Creating Supergroup Chat");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "createSupergroupChat");
    requestObject.insert("supergroup_id", supergroupId);
    requestObject.insert(_EXTRA, extra); //"openDirectly" gets matched in qml
    this->sendRequest(requestObject);
}

void TDLibWrapper::createBasicGroupChat(const QString &basicGroupId, const QString &extra)
{
    LOG("Creating Basic Group Chat");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "createBasicGroupChat");
    requestObject.insert("basic_group_id", basicGroupId);
    requestObject.insert(_EXTRA, extra); //"openDirectly"/"openAndSend:*" gets matched in qml
    this->sendRequest(requestObject);
}

void TDLibWrapper::getGroupsInCommon(const QString &userId, int limit, int offset)
{
    LOG("Retrieving Groups in Common");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getGroupsInCommon");
    requestObject.insert(_EXTRA, userId);
    requestObject.insert(USER_ID, userId);
    requestObject.insert("offset", offset);
    requestObject.insert("limit", limit);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getUserProfilePhotos(const QString &userId, int limit, int offset)
{
    LOG("Retrieving User Profile Photos");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getUserProfilePhotos");
    requestObject.insert(_EXTRA, userId);
    requestObject.insert(USER_ID, userId);
    requestObject.insert("offset", offset);
    requestObject.insert("limit", limit);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setChatPermissions(const QString &chatId, const QVariantMap &chatPermissions)
{
    LOG("Setting Chat Permissions");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatPermissions");
    requestObject.insert(_EXTRA, chatId);
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("permissions", chatPermissions);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setChatSlowModeDelay(const QString &chatId, int delay)
{

    LOG("Setting Chat Slow Mode Delay");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatSlowModeDelay");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("slow_mode_delay", delay);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setChatDescription(const QString &chatId, const QString &description)
{
    LOG("Setting Chat Description");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatDescription");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("description", description);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setChatTitle(const QString &chatId, const QString &title)
{
    LOG("Setting Chat Title");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatTitle");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("title", title);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setBio(const QString &bio)
{
    LOG("Setting Bio");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setBio");
    requestObject.insert("bio", bio);
    this->sendRequest(requestObject);
}

void TDLibWrapper::toggleSupergroupIsAllHistoryAvailable(const QString &groupId, bool isAllHistoryAvailable)
{
    LOG("Toggling SupergroupIsAllHistoryAvailable");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "toggleSupergroupIsAllHistoryAvailable");
    requestObject.insert("supergroup_id", groupId);
    requestObject.insert("is_all_history_available", isAllHistoryAvailable);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setPollAnswer(const QString &chatId, qlonglong messageId, QVariantList optionIds)
{
    LOG("Setting Poll Answer");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setPollAnswer");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("option_ids", optionIds);
    this->sendRequest(requestObject);
}

void TDLibWrapper::stopPoll(const QString &chatId, qlonglong messageId)
{
    LOG("Stopping Poll");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "stopPoll");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getPollVoters(const QString &chatId, qlonglong messageId, int optionId, int limit, int offset, const QString &extra)
{
    LOG("Retrieving Poll Voters");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getPollVoters");
    requestObject.insert(_EXTRA, extra);
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("option_id", optionId);
    requestObject.insert("offset", offset);
    requestObject.insert("limit", limit); //max 50
    this->sendRequest(requestObject);
}

void TDLibWrapper::searchPublicChat(const QString &userName, bool doOpenOnFound)
{
    LOG("Search public chat" << userName);
    if(doOpenOnFound) {
        this->activeChatSearchName = userName;
    }
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "searchPublicChat");
    QVariantMap extraObject = requestObject;
    extraObject.insert(TYPE, "searchPublicChat:"+userName);
    extraObject.insert("doOpenOnFound", doOpenOnFound);
    requestObject.insert(_EXTRA, extraObject);
    requestObject.insert(USERNAME, userName);
    this->sendRequest(requestObject);
}

void TDLibWrapper::joinChatByInviteLink(const QString &inviteLink)
{
    LOG("Join chat by invite link" << inviteLink);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "joinChatByInviteLink");
    requestObject.insert("invite_link", inviteLink);
    this->joinChatRequested = true;
    this->sendRequest(requestObject);
}

void TDLibWrapper::getDeepLinkInfo(const QString &link)
{
    LOG("Resolving TG deep link" << link);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getDeepLinkInfo");
    requestObject.insert("link", link);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getContacts()
{
    LOG("Retrieving contacts");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getContacts");
    requestObject.insert(_EXTRA, "contactsRequested");
    this->sendRequest(requestObject);
}

void TDLibWrapper::getSecretChat(qlonglong secretChatId)
{
    LOG("Getting detailed information about secret chat" << secretChatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getSecretChat");
    requestObject.insert("secret_chat_id", secretChatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::closeSecretChat(qlonglong secretChatId)
{
    LOG("Closing secret chat" << secretChatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "closeSecretChat");
    requestObject.insert("secret_chat_id", secretChatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::importContacts(const QVariantList &contacts, bool single) {
    LOG("Importing contacts");
    this->sendRequest(QVariantMap{{_TYPE, "importContacts"}, {"contacts", contacts}, {_EXTRA, single}});
}

void TDLibWrapper::addContact(qlonglong userId, const QString &firstName, const QString &lastName, const QString &phone, bool sharePhoneNumber) {
    LOG("Adding contact" << userId << firstName);
    sendRequest(QVariantMap{
                          {_TYPE, "addContact"},
                          {CONTACT, QVariantMap{
                               {_TYPE, CONTACT},
                               {PHONE_NUMBER, phone},
                               {FIRST_NAME, firstName},
                               {LAST_NAME, lastName},
                               {USER_ID, userId}
                           }},
                          {"share_phone_number", sharePhoneNumber}
                      });
}

void TDLibWrapper::removeContacts(QStringList userIds) {
    LOG("Removing" << userIds.size() << "contacts");
    const QVariantMap extra{{_TYPE, REMOVE_CONTACTS}, {"user_ids", userIds}};
    QVariantMap requestObject = extra;
    requestObject.insert(_EXTRA, extra);
    sendRequest(requestObject);
}

void TDLibWrapper::removeContact(QString userId) {
    LOG("Removing contact" << userId);
    removeContacts(QStringList{userId});
}

void TDLibWrapper::searchChatMessages(qlonglong chatId, const QString &query, qlonglong fromMessageId)
{
    LOG("Searching for messages" << chatId << query << fromMessageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "searchChatMessages");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("query", query);
    requestObject.insert("from_message_id", fromMessageId);
    requestObject.insert("offset", 0);
    requestObject.insert("limit", 50);
    requestObject.insert(_EXTRA, "searchChatMessages");
    this->sendRequest(requestObject);
}

void TDLibWrapper::searchPublicChats(const QString &query)
{
    LOG("Searching public chats" << query);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "searchPublicChats");
    requestObject.insert("query", query);
    requestObject.insert(_EXTRA, "searchPublicChats");
    this->sendRequest(requestObject);
}

void TDLibWrapper::readAllChatMentions(qlonglong chatId)
{
    LOG("Read all chat mentions" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "readAllChatMentions");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::readAllChatReactions(qlonglong chatId)
{
    LOG("Read all chat reactions" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "readAllChatReactions");
    requestObject.insert(CHAT_ID, chatId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::toggleChatIsMarkedAsUnread(qlonglong chatId, bool isMarkedAsUnread)
{
    LOG("Toggle chat is marked as unread" << chatId << isMarkedAsUnread);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "toggleChatIsMarkedAsUnread");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("is_marked_as_unread", isMarkedAsUnread);
    this->sendRequest(requestObject);
}

void TDLibWrapper::toggleChatIsPinned(qlonglong chatId, bool isPinned)
{
    LOG("Toggle chat is pinned" << chatId << isPinned);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "toggleChatIsPinned");
    QVariantMap chatListMap;
    chatListMap.insert(_TYPE, CHAT_LIST_MAIN);
    requestObject.insert("chat_list", chatListMap);
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("is_pinned", isPinned);
    requestObject.insert("is_marked_as_unread", isPinned);
    this->sendRequest(requestObject);
}

void TDLibWrapper::setChatDraftMessage(qlonglong chatId, qlonglong threadId, qlonglong replyToMessageId, const QString &draft)
{
    LOG("Set Draft Message" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setChatDraftMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(THREAD_ID, threadId);
    QVariantMap draftMessage;
    QVariantMap inputMessageContent;
    QVariantMap formattedText = newFormattedText(draft);

    formattedText.insert("clear_draft", draft.isEmpty());
    inputMessageContent.insert(_TYPE, "inputMessageText");
    inputMessageContent.insert("text", formattedText);
    draftMessage.insert(_TYPE, "draftMessage");
    draftMessage.insert("input_message_text", inputMessageContent);

    if (versionNumber > VERSION_NUMBER(1,8,20)) {
        QVariantMap replyTo;
        replyTo.insert(_TYPE, TYPE_INPUT_MESSAGE_REPLY_TO_MESSAGE);
        replyTo.insert(CHAT_ID, chatId);
        replyTo.insert(MESSAGE_ID, replyToMessageId);
        draftMessage.insert(REPLY_TO, replyTo);
    } else {
        draftMessage.insert(REPLY_TO_MESSAGE_ID, replyToMessageId);
    }

    requestObject.insert("draft_message", draftMessage);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getInlineQueryResults(qlonglong botUserId, qlonglong chatId, const QVariantMap &userLocation, const QString &query, const QString &offset, const QString &extra)
{

    LOG("Get Inline Query Results" << chatId << query);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getInlineQueryResults");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("bot_user_id", botUserId);
    if(!userLocation.isEmpty()) {
        requestObject.insert("user_location", userLocation);
    }
    requestObject.insert("query", query);
    requestObject.insert("offset", offset);
    requestObject.insert(_EXTRA, extra);

    this->sendRequest(requestObject);
}

void TDLibWrapper::sendInlineQueryResultMessage(qlonglong chatId, qlonglong threadId, qlonglong replyToMessageId, const QString &queryId, const QString &resultId)
{

    LOG("Send Inline Query Result Message" << chatId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "sendInlineQueryResultMessage");
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("message_thread_id", threadId);
    requestObject.insert("reply_to_message_id", replyToMessageId);
    requestObject.insert("query_id", queryId);
    requestObject.insert("result_id", resultId);

    this->sendRequest(requestObject);
}

void TDLibWrapper::sendBotStartMessage(qlonglong botUserId, qlonglong chatId, const QString &parameter, const QString &extra)
{

    LOG("Send Bot Start Message" << botUserId << chatId << parameter << extra);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "sendBotStartMessage");
    requestObject.insert("bot_user_id", botUserId);
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert("parameter", parameter);
    requestObject.insert(_EXTRA, extra);

    this->sendRequest(requestObject);
}

void TDLibWrapper::cancelDownloadFile(int fileId)
{
    LOG("Cancel Download File" << fileId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "cancelDownloadFile");
    requestObject.insert("file_id", fileId);
    requestObject.insert("only_if_pending", false);

    this->sendRequest(requestObject);
}

void TDLibWrapper::cancelUploadFile(int fileId)
{
    LOG("Cancel Upload File" << fileId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "cancelUploadFile");
    requestObject.insert("file_id", fileId);

    this->sendRequest(requestObject);
}

void TDLibWrapper::deleteFile(int fileId)
{
    LOG("Delete cached File" << fileId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "deleteFile");
    requestObject.insert("file_id", fileId);

    this->sendRequest(requestObject);
}

void TDLibWrapper::setName(const QString &firstName, const QString &lastName)
{
    LOG("Set name of current user" << firstName << lastName);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setName");
    requestObject.insert(FIRST_NAME, firstName);
    requestObject.insert(LAST_NAME, lastName);

    this->sendRequest(requestObject);
}

void TDLibWrapper::setUsername(const QString &userName)
{
    LOG("Set username of current user" << userName);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setUsername");
    requestObject.insert("username", userName);

    this->sendRequest(requestObject);
}

void TDLibWrapper::setUserPrivacySettingRule(TDLibWrapper::UserPrivacySetting setting, TDLibWrapper::UserPrivacySettingRule rule)
{
    LOG("Set user privacy setting rule of current user" << setting << rule);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setUserPrivacySettingRules");

    QVariantMap settingMap;
    switch (setting) {
    case SettingShowStatus:
        settingMap.insert(_TYPE, "userPrivacySettingShowStatus");
        break;
    case SettingShowPhoneNumber:
        settingMap.insert(_TYPE, "userPrivacySettingShowPhoneNumber");
        break;
    case SettingAllowChatInvites:
        settingMap.insert(_TYPE, "userPrivacySettingAllowChatInvites");
        break;
    case SettingShowProfilePhoto:
        settingMap.insert(_TYPE, "userPrivacySettingShowProfilePhoto");
        break;
    case SettingAllowFindingByPhoneNumber:
        settingMap.insert(_TYPE, "userPrivacySettingAllowFindingByPhoneNumber");
        break;
    case SettingShowLinkInForwardedMessages:
        settingMap.insert(_TYPE, "userPrivacySettingShowLinkInForwardedMessages");
        break;
    case SettingUnknown:
        return;
    }
    requestObject.insert("setting", settingMap);


    QVariantMap ruleMap;
    switch (rule) {
    case RuleAllowAll:
        ruleMap.insert(_TYPE, "userPrivacySettingRuleAllowAll");
        break;
    case RuleAllowContacts:
        ruleMap.insert(_TYPE, "userPrivacySettingRuleAllowContacts");
        break;
    case RuleRestrictAll:
        ruleMap.insert(_TYPE, "userPrivacySettingRuleRestrictAll");
        break;
    }
    QVariantList ruleMaps;
    ruleMaps.append(ruleMap);
    QVariantMap encapsulatedRules;
    encapsulatedRules.insert(_TYPE, "userPrivacySettingRules");
    encapsulatedRules.insert("rules", ruleMaps);
    requestObject.insert("rules", encapsulatedRules);

    this->sendRequest(requestObject);
}

void TDLibWrapper::getUserPrivacySettingRules(TDLibWrapper::UserPrivacySetting setting)
{
    LOG("Getting user privacy setting rules of current user" << setting);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getUserPrivacySettingRules");
    requestObject.insert(_EXTRA, setting);

    QVariantMap settingMap;
    switch (setting) {
    case SettingShowStatus:
        settingMap.insert(_TYPE, "userPrivacySettingShowStatus");
        break;
    case SettingShowPhoneNumber:
        settingMap.insert(_TYPE, "userPrivacySettingShowPhoneNumber");
        break;
    case SettingAllowChatInvites:
        settingMap.insert(_TYPE, "userPrivacySettingAllowChatInvites");
        break;
    case SettingShowProfilePhoto:
        settingMap.insert(_TYPE, "userPrivacySettingShowProfilePhoto");
        break;
    case SettingAllowFindingByPhoneNumber:
        settingMap.insert(_TYPE, "userPrivacySettingAllowFindingByPhoneNumber");
        break;
    case SettingShowLinkInForwardedMessages:
        settingMap.insert(_TYPE, "userPrivacySettingShowLinkInForwardedMessages");
        break;
    case SettingUnknown:
        return;
    }
    requestObject.insert("setting", settingMap);

    this->sendRequest(requestObject);
}

void TDLibWrapper::setProfilePhoto(const QString &filePath)
{
    LOG("Set a profile photo" << filePath);

    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setProfilePhoto");
    requestObject.insert(_EXTRA, "setProfilePhoto");
    QVariantMap inputChatPhoto;
    inputChatPhoto.insert(_TYPE, "inputChatPhotoStatic");
    QVariantMap inputFile;
    inputFile.insert(_TYPE, "inputFileLocal");
    inputFile.insert("path", filePath);
    inputChatPhoto.insert("photo", inputFile);
    requestObject.insert("photo", inputChatPhoto);

    this->sendRequest(requestObject);
}

void TDLibWrapper::deleteProfilePhoto(const QString &profilePhotoId)
{
    LOG("Delete a profile photo" << profilePhotoId);

    QVariantMap requestObject;
    requestObject.insert(_TYPE, "deleteProfilePhoto");
    requestObject.insert(_EXTRA, "deleteProfilePhoto");
    requestObject.insert("profile_photo_id", profilePhotoId);

    this->sendRequest(requestObject);
}

void TDLibWrapper::changeStickerSet(const QString &stickerSetId, bool isInstalled)
{
    LOG("Change sticker set" << stickerSetId << isInstalled);

    QVariantMap requestObject;
    requestObject.insert(_TYPE, "changeStickerSet");
    requestObject.insert(_EXTRA, isInstalled ? "installStickerSet" : "removeStickerSet");
    requestObject.insert("set_id", stickerSetId);
    requestObject.insert("is_installed", isInstalled);

    this->sendRequest(requestObject);
}

void TDLibWrapper::getActiveSessions()
{
    LOG("Get active sessions");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getActiveSessions");
    this->sendRequest(requestObject);
}

void TDLibWrapper::terminateSession(const QString &sessionId)
{
    LOG("Terminate session" << sessionId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "terminateSession");
    requestObject.insert(_EXTRA, "terminateSession");
    requestObject.insert("session_id", sessionId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getMessageAvailableReactions(qlonglong chatId, qlonglong messageId)
{
    LOG("Get available reactions for message" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getMessageAvailableReactions");
    requestObject.insert(_EXTRA, QString::number(messageId));
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getPageSource(const QString &address)
{
    QUrl url = QUrl(address);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
    request.setHeader(QNetworkRequest::UserAgentHeader, "Ferniegram Bot (Sailfish OS)");
    request.setRawHeader(QByteArray("Accept"), QByteArray("text/html,application/xhtml+xml"));
    request.setRawHeader(QByteArray("Accept-Charset"), QByteArray("utf-8"));
    request.setRawHeader(QByteArray("Connection"), QByteArray("close"));
    request.setRawHeader(QByteArray("Cache-Control"), QByteArray("max-age=0"));
    QNetworkReply *reply = manager->get(request);

    connect(reply, SIGNAL(finished()), this, SLOT(handleGetPageSourceFinished()));
}

void TDLibWrapper::addMessageReaction(qlonglong chatId, qlonglong messageId, const QString &reaction)
{
    QVariantMap requestObject;
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    requestObject.insert("is_big", false);
    if (versionNumber > VERSION_NUMBER(1,8,5)) {
        // "reaction_type": {
        //     "@type": "reactionTypeEmoji",
        //     "emoji": "..."
        // }
        QVariantMap reactionType;
        reactionType.insert(_TYPE, REACTION_TYPE_EMOJI);
        reactionType.insert(EMOJI, reaction);
        requestObject.insert(REACTION_TYPE, reactionType);
        requestObject.insert(_TYPE, "addMessageReaction");
        LOG("Add message reaction" << chatId << messageId << reaction);
    } else {
        requestObject.insert("reaction", reaction);
        requestObject.insert(_TYPE, "setMessageReaction");
        LOG("Toggle message reaction" << chatId << messageId << reaction);
    }
    this->sendRequest(requestObject);
}

void TDLibWrapper::removeMessageReaction(qlonglong chatId, qlonglong messageId, const QString &reaction)
{
    QVariantMap requestObject;
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    if (versionNumber > VERSION_NUMBER(1,8,5)) {
        // "reaction_type": {
        //     "@type": "reactionTypeEmoji",
        //     "emoji": "..."
        // }
        QVariantMap reactionType;
        reactionType.insert(_TYPE, REACTION_TYPE_EMOJI);
        reactionType.insert(EMOJI, reaction);
        requestObject.insert(REACTION_TYPE, reactionType);
        requestObject.insert(_TYPE, "removeMessageReaction");
        LOG("Remove message reaction" << chatId << messageId << reaction);
    } else {
        requestObject.insert("reaction", reaction);
        requestObject.insert(_TYPE, "setMessageReaction");
        LOG("Toggle message reaction" << chatId << messageId << reaction);
    }
    this->sendRequest(requestObject);
}

void TDLibWrapper::setNetworkType(NetworkType networkType)
{
    LOG("Set network type" << networkType);

    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setNetworkType");
    requestObject.insert(_EXTRA, "setNetworkType");
    QVariantMap networkTypeObject;
    switch (networkType) {
    case Mobile:
        networkTypeObject.insert(_TYPE, "networkTypeMobile");
        break;
    case MobileRoaming:
        networkTypeObject.insert(_TYPE, "networkTypeMobileRoaming");
        break;
    case None:
        networkTypeObject.insert(_TYPE, "networkTypeNone");
        break;
    case Other:
        networkTypeObject.insert(_TYPE, "networkTypeOther");
        break;
    case WiFi:
        networkTypeObject.insert(_TYPE, "networkTypeWiFi");
        break;
    default:
        networkTypeObject.insert(_TYPE, "networkTypeOther");
        break;
    }

    requestObject.insert(TYPE, networkTypeObject);

    this->sendRequest(requestObject);
}

void TDLibWrapper::setInactiveSessionTtl(int days)
{
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setInactiveSessionTtl");
    requestObject.insert("inactive_session_ttl_days", days);
    this->sendRequest(requestObject);
}

void TDLibWrapper::searchEmoji(const QString &queryString)
{
    LOG("Searching emoji" << queryString);
    while (this->emojiSearchWorker.isRunning()) {
        this->emojiSearchWorker.requestInterruption();
    }
    this->emojiSearchWorker.setParameters(queryString);
    this->emojiSearchWorker.start();
}

QVariantMap TDLibWrapper::getUserInformation()
{
    return this->userInformation;
}

QVariantMap TDLibWrapper::getUserInformation(const QString &userId)
{
    // LOG("Returning user information for ID" << userId);
    return this->usersById.value(userId).toMap();
}

bool TDLibWrapper::hasUserInformation(const QString &userId) {
    return this->usersById.contains(userId);
}

bool TDLibWrapper::hasUserNameInformation(const QString &userName) {
    return this->usersByName.contains(userName);
}

QVariantMap TDLibWrapper::getUserInformationByName(const QString &userName) {
    return this->usersByName.value(userName.toLower()).toMap();
}

bool TDLibWrapper::hasSuperGroupNameInformation(const QString &name) {
    return this->superGroupsByName.contains(name);
}

QVariantMap TDLibWrapper::getSupergroupInformationByName(const QString &name) {
    return this->superGroupsByName.value(name.toLower()).toMap();
}

TDLibWrapper::UserPrivacySettingRule TDLibWrapper::getUserPrivacySettingRule(TDLibWrapper::UserPrivacySetting userPrivacySetting)
{
    return this->userPrivacySettingRules.value(userPrivacySetting, UserPrivacySettingRule::RuleAllowAll);
}

QVariantMap TDLibWrapper::getUnreadMessageInformation()
{
    return this->unreadMessageInformation;
}

QVariantMap TDLibWrapper::getUnreadChatInformation()
{
    return this->unreadChatInformation;
}

QVariantMap TDLibWrapper::getBasicGroup(qlonglong groupId) const
{
    const Group* group = basicGroups.value(groupId);
    if (group) {
        LOG("Returning basic group information for ID" << groupId);
        return group->groupInfo;
    } else {
        LOG("No super group information for ID" << groupId);
        return QVariantMap();
    }
}

QVariantMap TDLibWrapper::getSuperGroup(qlonglong groupId) const
{
    const Group* group = superGroups.value(groupId);
    if (group) {
        LOG("Returning super group information for ID" << groupId);
        return group->groupInfo;
    } else {
        LOG("No super group information for ID" << groupId);
        return QVariantMap();
    }
}

QVariantMap TDLibWrapper::getChat(const QString &chatId)
{
    LOG("Returning chat information for ID" << chatId);
    return this->chats.value(chatId).toMap();
}

QStringList TDLibWrapper::getChatReactions(const QString &chatId)
{
    LOG("Obtaining chat reactions for chat" << chatId);
    const QVariant available_reactions(chats.value(chatId).toMap().value(CHAT_AVAILABLE_REACTIONS));
    const QVariantMap map(available_reactions.toMap());
    const QString reactions_type(map.value(_TYPE).toString());
    if (reactions_type == CHAT_AVAILABLE_REACTIONS_ALL) {
        LOG("Chat uses all available reactions, currently available number" << activeEmojiReactions.size());
        return activeEmojiReactions;
    } else if (reactions_type == CHAT_AVAILABLE_REACTIONS_SOME) {
        LOG("Chat uses reduced set of reactions");
        const QVariantList reactions(map.value(REACTIONS).toList());
        const int n = reactions.count();
        QStringList emojis;

        // "available_reactions": {
        //     "@type": "chatAvailableReactionsSome",
        //     "reactions": [
        //         {
        //             "@type": "reactionTypeEmoji",
        //             "emoji": "..."
        //         },
        emojis.reserve(n);
        for (int i = 0; i < n; i++) {
            const QVariantMap reaction(reactions.at(i).toMap());
            if (reaction.value(_TYPE).toString() == REACTION_TYPE_EMOJI) {
                const QString emoji(reaction.value(EMOJI).toString());
                if (!emoji.isEmpty()) {
                    emojis.append(emoji);
                }
            }
        }
        LOG("Found emojis for this chat" << emojis.size());
        return emojis;
    } else if (reactions_type.isEmpty()) {
        LOG("No chat reaction type specified, using all reactions");
        return available_reactions.toStringList();
    } else {
        LOG("Unknown chat reaction type" << reactions_type);
        return QStringList();
    }
}

QVariantMap TDLibWrapper::getSecretChatFromCache(qlonglong secretChatId)
{
    return this->secretChats.value(secretChatId);
}

QString TDLibWrapper::getOptionString(const QString &optionName)
{
    return this->options.value(optionName).toString();
}

void TDLibWrapper::copyFileToDownloads(const QString &filePath, bool openAfterCopy)
{
    LOG("Copy file to downloads" << filePath << openAfterCopy);
    QFileInfo fileInfo(filePath);
    if (fileInfo.exists()) {
        QString downloadFilePath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/" + fileInfo.fileName();
        if (QFile::exists(downloadFilePath)) {
            if (openAfterCopy) {
                this->openFileOnDevice(downloadFilePath);
            } else {
                emit copyToDownloadsSuccessful(fileInfo.fileName(), downloadFilePath);
            }
        } else {
            if (QFile::copy(filePath, downloadFilePath)) {
                if (openAfterCopy) {
                    this->openFileOnDevice(downloadFilePath);
                } else {
                    emit copyToDownloadsSuccessful(fileInfo.fileName(), downloadFilePath);
                }
            } else {
                emit copyToDownloadsError(fileInfo.fileName(), downloadFilePath);
            }
        }
    } else {
        emit copyToDownloadsError(fileInfo.fileName(), filePath);
    }
}

void TDLibWrapper::openFileOnDevice(const QString &filePath)
{
    LOG("Open file on device:" << filePath);
    emit openFileExternally(filePath);
}

bool TDLibWrapper::getJoinChatRequested()
{
    return this->joinChatRequested;
}

void TDLibWrapper::registerJoinChat()
{
    this->joinChatRequested = false;
}

DBusAdaptor *TDLibWrapper::getDBusAdaptor()
{
    return this->dbusInterface->getDBusAdaptor();
}

void TDLibWrapper::handleVersionDetected(const QString &version)
{
    this->versionString = version;
    const QStringList parts(version.split('.'));
    uint major, minor, release;
    bool ok;
    if (parts.count() >= 3 &&
       (major = parts.at(0).toInt(&ok), ok) &&
       (minor = parts.at(1).toInt(&ok), ok) &&
       (release = parts.at(2).toInt(&ok), ok)) {
        versionNumber = VERSION_NUMBER(major, minor, release);
    }
    emit versionDetected(version);
}

void TDLibWrapper::handleAuthorizationStateChanged(const QString &authorizationState, const QVariantMap authorizationStateData)
{
    if (authorizationState == "authorizationStateClosed") {
        this->authorizationState = AuthorizationState::Closed;
    }

    if (authorizationState == "authorizationStateClosing") {
        this->authorizationState = AuthorizationState::Closing;
    }

    if (authorizationState == "authorizationStateLoggingOut") {
        this->authorizationState = AuthorizationState::LoggingOut;
    }

    if (authorizationState == "authorizationStateReady") {
        this->authorizationState = AuthorizationState::AuthorizationReady;
    }

    if (authorizationState == "authorizationStateWaitCode") {
        this->authorizationState = AuthorizationState::WaitCode;
    }

    if (authorizationState == "authorizationStateWaitEncryptionKey") {
        this->setEncryptionKey();
        this->authorizationState = AuthorizationState::WaitEncryptionKey;
    }

    if (authorizationState == "authorizationStateWaitOtherDeviceConfirmation") {
        this->authorizationState = AuthorizationState::WaitOtherDeviceConfirmation;
    }

    if (authorizationState == "authorizationStateWaitPassword") {
        this->authorizationState = AuthorizationState::WaitPassword;
    }

    if (authorizationState == "authorizationStateWaitPhoneNumber") {
        this->authorizationState = AuthorizationState::WaitPhoneNumber;
    }

    if (authorizationState == "authorizationStateWaitRegistration") {
        this->authorizationState = AuthorizationState::WaitRegistration;
    }

    if (authorizationState == "authorizationStateWaitTdlibParameters") {
        this->setInitialParameters();
        this->authorizationState = AuthorizationState::WaitTdlibParameters;
    }
    if (authorizationState == "authorizationStateLoggingOut") {
        this->authorizationState = AuthorizationState::AuthorizationStateLoggingOut;
    }
    if (authorizationState == "authorizationStateClosed") {
        this->authorizationState = AuthorizationState::AuthorizationStateClosed;
        LOG("Reloading TD Lib...");
        this->basicGroups.clear();
        this->superGroups.clear();
        this->usersById.clear();
        this->usersByName.clear();
        this->tdLibReceiver->setActive(false);
        while (this->tdLibReceiver->isRunning()) {
            QCoreApplication::processEvents(QEventLoop::AllEvents, 1000);
        }
        td_json_client_destroy(this->tdLibClient);
        this->tdLibReceiver->terminate();
        QDir appPath(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
        appPath.removeRecursively();
        this->tdLibClient = td_json_client_create();
        initializeTDLibReceiver();
        this->isLoggingOut = false;
    }
    this->authorizationStateData = authorizationStateData;
    emit authorizationStateChanged(this->authorizationState, this->authorizationStateData);

}

void TDLibWrapper::handleOptionUpdated(const QString &optionName, const QVariant &optionValue)
{
    this->options.insert(optionName, optionValue);
    emit optionUpdated(optionName, optionValue);
    if (optionName == "my_id") {
        QString ownUserId = optionValue.toString();
        this->userInformation = this->getUserInformation(ownUserId);
        emit ownUserIdFound(ownUserId);

    }
}

void TDLibWrapper::handleConnectionStateChanged(const QString &connectionState)
{
    if (connectionState == "connectionStateConnecting") {
        this->connectionState = ConnectionState::Connecting;
    }
    if (connectionState == "connectionStateConnectingToProxy") {
        this->connectionState = ConnectionState::ConnectingToProxy;
    }
    if (connectionState == "connectionStateReady") {
        this->connectionState = ConnectionState::ConnectionReady;
    }
    if (connectionState == "connectionStateUpdating") {
        this->connectionState = ConnectionState::Updating;
    }
    if (connectionState == "connectionStateWaitingForNetwork") {
        this->connectionState = ConnectionState::WaitingForNetwork;
    }

    emit connectionStateChanged(this->connectionState);
}

void TDLibWrapper::handleUserUpdated(const QVariantMap &updatedUserInformation)
{
    QString updatedUserId = updatedUserInformation.value(ID).toString();
    if (updatedUserId == this->options.value("my_id").toString()) {
        LOG("Own user information updated :)");
        this->userInformation = updatedUserInformation;
        emit ownUserUpdated(updatedUserInformation);
    }
    LOG("User information updated:" << updatedUserInformation.value(USERNAMES).toMap().value(EDITABLE_USERNAME).toString() << updatedUserInformation.value(FIRST_NAME).toString() << updatedUserInformation.value(LAST_NAME).toString());
    updateUserInformation(updatedUserId, updatedUserInformation);
    emit userUpdated(updatedUserId, updatedUserInformation);
}

void TDLibWrapper::handleUserStatusUpdated(const QString &userId, const QVariantMap &userStatusInformation)
{
    if (userId == this->options.value("my_id").toString()) {
        LOG("Own user status information updated :)");
        this->userInformation.insert(STATUS, userStatusInformation);
    }
    QVariantMap updatedUserInformation = this->usersById.value(userId).toMap();
    if(updatedUserInformation.value(STATUS) == userStatusInformation) {
        return;
    }
    LOG("User status information updated:" << userId << userStatusInformation.value(_TYPE).toString());
    updatedUserInformation.insert(STATUS, userStatusInformation);
    updateUserInformation(userId, updatedUserInformation);
    emit userUpdated(userId, updatedUserInformation);
}

void TDLibWrapper::updateUserInformation(const QString &userId, const QVariantMap &userInformation)
{
    this->usersById.insert(userId, userInformation);
    this->usersByName.insert(userInformation.value(USERNAMES).toMap().value(EDITABLE_USERNAME).toString().toLower(), userInformation);
}

void TDLibWrapper::handleFileUpdated(const QVariantMap &fileInformation)
{
    emit fileUpdated(fileInformation.value(ID).toInt(), fileInformation);
}

void TDLibWrapper::handleNewChatDiscovered(const QVariantMap &chatInformation)
{
    QString chatId = chatInformation.value(ID).toString();
    this->chats.insert(chatId, chatInformation);
    emit newChatDiscovered(chatId, chatInformation);
}

void TDLibWrapper::handleChatReceived(const QVariantMap &chatInformation)
{
    emit chatReceived(chatInformation);
    if (!this->activeChatSearchName.isEmpty()) {
        QVariantMap chatType = chatInformation.value(TYPE).toMap();
        ChatType receivedChatType = chatTypeFromString(chatType.value(_TYPE).toString());
        if (receivedChatType == ChatTypeBasicGroup) {
            LOG("Found basic group for active search" << this->activeChatSearchName);
            this->activeChatSearchName.clear();
            this->createBasicGroupChat(chatType.value("basic_group_id").toString(), "openDirectly");
        } else if (receivedChatType == ChatTypeSupergroup) {
            LOG("Found supergroup for active search" << this->activeChatSearchName);
            this->activeChatSearchName.clear();
            this->createSupergroupChat(chatType.value("supergroup_id").toString(), "openDirectly");
        } else if (receivedChatType == ChatTypePrivate) {
            LOG("Found private chat for active search" << this->activeChatSearchName);
            this->activeChatSearchName.clear();
            this->createPrivateChat(chatType.value(USER_ID).toString(), "openDirectly");
        }
    }
}

void TDLibWrapper::handleUnreadMessageCountUpdated(const QVariantMap &messageCountInformation)
{
    if (messageCountInformation.value(CHAT_LIST_TYPE).toString() == CHAT_LIST_MAIN) {
        this->unreadMessageInformation = messageCountInformation;
        emit unreadMessageCountUpdated(messageCountInformation);
    }
}

void TDLibWrapper::handleUnreadChatCountUpdated(const QVariantMap &chatCountInformation)
{
    if (chatCountInformation.value(CHAT_LIST_TYPE).toString() == CHAT_LIST_MAIN) {
        this->unreadChatInformation = chatCountInformation;
        emit unreadChatCountUpdated(chatCountInformation);
    }
}

void TDLibWrapper::handleAvailableReactionsUpdated(qlonglong chatId, const QVariantMap &availableReactions)
{
    LOG("Updating available reactions for chat" << chatId << availableReactions);
    QString chatIdString = QString::number(chatId);
    QVariantMap chatInformation = this->getChat(chatIdString);
    chatInformation.insert(CHAT_AVAILABLE_REACTIONS, availableReactions);
    this->chats.insert(chatIdString, chatInformation);
    emit chatAvailableReactionsUpdated(chatId, availableReactions);

}

void TDLibWrapper::handleBasicGroupUpdated(qlonglong groupId, const QVariantMap &groupInformation)
{
    emit basicGroupUpdated(updateGroup(groupId, groupInformation, &basicGroups)->groupId);
    if (!this->activeChatSearchName.isEmpty() && this->activeChatSearchName == groupInformation.value(USERNAME).toString()) {
        LOG("Found basic group for active search" << this->activeChatSearchName);
        this->activeChatSearchName.clear();
        this->createBasicGroupChat(groupInformation.value(ID).toString(), "openDirectly");
    }
}

void TDLibWrapper::handleSuperGroupUpdated(qlonglong groupId, const QVariantMap &groupInformation) {
    superGroupsByName.insert(groupInformation.value(USERNAMES).toMap().value(EDITABLE_USERNAME).toString().toLower(), groupInformation);
    emit superGroupUpdated(updateGroup(groupId, groupInformation, &superGroups)->groupId);
    if (!this->activeChatSearchName.isEmpty() && this->activeChatSearchName == groupInformation.value(USERNAME).toString()) {
        LOG("Found supergroup for active search" << this->activeChatSearchName);
        this->activeChatSearchName.clear();
        this->createSupergroupChat(groupInformation.value(ID).toString(), "openDirectly");
    }
}

void TDLibWrapper::handleStickerSets(const QVariantList &stickerSets)
{
    QListIterator<QVariant> stickerSetIterator(stickerSets);
    while (stickerSetIterator.hasNext()) {
        QVariantMap stickerSet = stickerSetIterator.next().toMap();
        this->getStickerSet(stickerSet.value(ID).toString());
    }
    emit this->stickerSetsReceived(stickerSets);
}

void TDLibWrapper::handleEmojiSearchCompleted(const QString &queryString, const QVariantList &resultList)
{
    LOG("Emoji search completed" << queryString);
    emit emojiSearchSuccessful(resultList);
}

void TDLibWrapper::handleOpenWithChanged()
{
    if (this->appSettings->getUseOpenWith()) {
        this->initializeOpenWith();
    } else {
        this->removeOpenWith();
    }
}

void TDLibWrapper::handleSecretChatReceived(qlonglong secretChatId, const QVariantMap &secretChat)
{
    this->secretChats.insert(secretChatId, secretChat);
    emit secretChatReceived(secretChatId, secretChat);
}

void TDLibWrapper::handleSecretChatUpdated(qlonglong secretChatId, const QVariantMap &secretChat)
{
    this->secretChats.insert(secretChatId, secretChat);
    emit secretChatUpdated(secretChatId, secretChat);
}

void TDLibWrapper::handleStorageOptimizerChanged()
{
    setOptionBoolean("use_storage_optimizer", appSettings->storageOptimizer());
}

void TDLibWrapper::handleErrorReceived(int code, const QString &message, const QVariant &extra) {
    if (extra.userType() == QMetaType::QString && !extra.toString().isEmpty()) {
        QStringList parts(extra.toString().split(':'));
        if (parts.size() == 3 && parts.at(0) == QStringLiteral("getMessage")) {
            emit messageNotFound(parts.at(1).toLongLong(), parts.at(2).toLongLong());
        }
    }
    emit errorReceived(code, message, extra);
}

void TDLibWrapper::handleMessageInformation(qlonglong chatId, qlonglong messageId, const QVariantMap &receivedInformation)
{
    QString extraInformation = receivedInformation.value(_EXTRA).toString();
    if (extraInformation.startsWith("getChatPinnedMessage:")) {
        emit chatPinnedMessageUpdated(chatId, messageId);
    }
    emit receivedMessage(chatId, messageId, receivedInformation);
}

void TDLibWrapper::handleMessageIsPinnedUpdated(qlonglong chatId, qlonglong messageId, bool isPinned)
{
    if (isPinned) {
        emit chatPinnedMessageUpdated(chatId, messageId);
    } else {
        emit chatPinnedMessageUpdated(chatId, 0);
        this->getChatPinnedMessage(chatId);
    }
}

void TDLibWrapper::handleUserPrivacySettingRules(const QVariantMap &rules)
{
    QVariantList newGivenRules = rules.value("rules").toList();
    // If nothing (or something unsupported is sent out) it is considered to be restricted completely
    UserPrivacySettingRule newAppliedRule = UserPrivacySettingRule::RuleRestrictAll;
    QListIterator<QVariant> givenRulesIterator(newGivenRules);
    while (givenRulesIterator.hasNext()) {
        QString givenRule = givenRulesIterator.next().toMap().value(_TYPE).toString();
        if (givenRule == "userPrivacySettingRuleAllowContacts") {
            newAppliedRule = UserPrivacySettingRule::RuleAllowContacts;
        }
        if (givenRule == "userPrivacySettingRuleAllowAll") {
            newAppliedRule = UserPrivacySettingRule::RuleAllowAll;
        }
    }
    UserPrivacySetting usedSetting = static_cast<UserPrivacySetting>(rules.value(_EXTRA).toInt());
    this->userPrivacySettingRules.insert(usedSetting, newAppliedRule);
    emit userPrivacySettingUpdated(usedSetting, newAppliedRule);
}

void TDLibWrapper::handleUpdatedUserPrivacySettingRules(const QVariantMap &updatedRules)
{
    QString rawSetting = updatedRules.value("setting").toMap().value(_TYPE).toString();
    UserPrivacySetting usedSetting = UserPrivacySetting::SettingUnknown;
    if (rawSetting == "userPrivacySettingAllowChatInvites") {
        usedSetting = UserPrivacySetting::SettingAllowChatInvites;
    }
    if (rawSetting == "userPrivacySettingAllowFindingByPhoneNumber") {
        usedSetting = UserPrivacySetting::SettingAllowFindingByPhoneNumber;
    }
    if (rawSetting == "userPrivacySettingShowLinkInForwardedMessages") {
        usedSetting = UserPrivacySetting::SettingShowLinkInForwardedMessages;
    }
    if (rawSetting == "userPrivacySettingShowPhoneNumber") {
        usedSetting = UserPrivacySetting::SettingShowPhoneNumber;
    }
    if (rawSetting == "userPrivacySettingShowProfilePhoto") {
        usedSetting = UserPrivacySetting::SettingShowProfilePhoto;
    }
    if (rawSetting == "userPrivacySettingShowStatus") {
        usedSetting = UserPrivacySetting::SettingShowStatus;
    }
    if (usedSetting != UserPrivacySetting::SettingUnknown) {
        QVariantMap rawRules = updatedRules.value("rules").toMap();
        rawRules.insert(_EXTRA, usedSetting);
        this->handleUserPrivacySettingRules(rawRules);
    }
}

void TDLibWrapper::handleSponsoredMessage(qlonglong chatId, const QVariantMap &message)
{
    switch (appSettings->getSponsoredMess()) {
    case AppSettings::SponsoredMessHandle:
        emit sponsoredMessageReceived(chatId, message);
        break;
    case AppSettings::SponsoredMessAutoView:
        LOG("Auto-viewing sponsored message");
        viewMessage(chatId, message.value(MESSAGE_ID).toULongLong(), false);
        break;
    case AppSettings::SponsoredMessIgnore:
        LOG("Ignoring sponsored message");
        break;
    }
}

void TDLibWrapper::handleActiveEmojiReactionsUpdated(const QStringList& emojis)
{
    if (activeEmojiReactions != emojis) {
        activeEmojiReactions = emojis;
        LOG(emojis.count() << "reaction(s) available");
        emit reactionsUpdated();
    }
}

void TDLibWrapper::handleNetworkConfigurationChanged(const QNetworkConfiguration &config)
{
    LOG("A network configuration changed: " << config.bearerTypeName() << config.state());
    LOG("Checking overall network state...");

    bool wifiFound = false;
    bool mobileFound = false;

    QList<QNetworkConfiguration> activeConfigurations = networkConfigurationManager->allConfigurations(QNetworkConfiguration::Active);
    QListIterator<QNetworkConfiguration> configurationIterator(activeConfigurations);
    while (configurationIterator.hasNext()) {
        QNetworkConfiguration activeConfiguration = configurationIterator.next();
        if (activeConfiguration.bearerType() == QNetworkConfiguration::BearerWLAN
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerEthernet) {
            LOG("Active WiFi found...");
            wifiFound = true;
        }
        if (activeConfiguration.bearerType() == QNetworkConfiguration::Bearer2G
                || activeConfiguration.bearerType() == QNetworkConfiguration::Bearer3G
                || activeConfiguration.bearerType() == QNetworkConfiguration::Bearer4G
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerCDMA2000
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerEVDO
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerHSPA
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerLTE
                || activeConfiguration.bearerType() == QNetworkConfiguration::BearerWCDMA) {
            LOG("Active mobile connection found...");
            mobileFound = true;
        }
    }
    if (wifiFound) {
        this->setNetworkType(NetworkType::WiFi);
    } else if (mobileFound) {
        this->setNetworkType(NetworkType::Mobile);
    } else {
        this->setNetworkType(NetworkType::None);
    }
}

void TDLibWrapper::handleGetPageSourceFinished()
{
    LOG("TDLibWrapper::handleGetPageSourceFinished");
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        return;
    }

    QString requestAddress = reply->request().url().toString();

    QVariant contentTypeHeader = reply->header(QNetworkRequest::ContentTypeHeader);
    if (!contentTypeHeader.isValid()) {
        return;
    }
    LOG("Page source content type header: " + contentTypeHeader.toString());
    if (contentTypeHeader.toString().indexOf("text/html", 0, Qt::CaseInsensitive) == -1) {
        LOG(requestAddress + " is not HTML, not searching for TG URL...");
        return;
    }

    QString charset = "UTF-8";
    QRegularExpression charsetRegularExpression("charset\\s*\\=[\\s\\\"\\\']*([^\\s\\\"\\\'\\,>]*)");
    QRegularExpressionMatchIterator matchIterator = charsetRegularExpression.globalMatch(contentTypeHeader.toString());
    QStringList availableCharsets;
    while (matchIterator.hasNext()) {
        QRegularExpressionMatch nextMatch = matchIterator.next();
        QString currentCharset = nextMatch.captured(1).toUpper();
        LOG("Available page source charset: " << currentCharset);
        availableCharsets.append(currentCharset);
    }
    if (availableCharsets.size() > 0 && !availableCharsets.contains("UTF-8")) {
        // If we haven't received the requested UTF-8, we simply use the last one which we received in the header
        charset = availableCharsets.last();
    }
    LOG("Charset for " << requestAddress << ": " << charset);

    QByteArray rawDocument = reply->readAll();
    QTextCodec *codec = QTextCodec::codecForName(charset.toUtf8());
    if (codec == nullptr){
      return;
    }
    QString resultDocument = codec->toUnicode(rawDocument);
    QRegExp urlRegex("href\\=\"(tg\\:[^\"]+)\\\"");
    if (urlRegex.indexIn(resultDocument) != -1) {
        LOG("TG URL found: " + urlRegex.cap(1));
        emit tgUrlFound(urlRegex.cap(1));
    }
}

QVariantMap& TDLibWrapper::fillTdlibParameters(QVariantMap& parameters)
{
    parameters.insert("api_id", TDLIB_API_ID);
    parameters.insert("api_hash", TDLIB_API_HASH);
    parameters.insert("database_directory", QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/tdlib");
    bool onlineOnlyMode = this->appSettings->onlineOnlyMode();
    parameters.insert("use_file_database", !onlineOnlyMode);
    parameters.insert("use_chat_info_database", !onlineOnlyMode);
    parameters.insert("use_message_database", !onlineOnlyMode);
    parameters.insert("use_secret_chats", true);
    parameters.insert("system_language_code", QLocale::system().name());
    QSettings hardwareSettings("/etc/hw-release", QSettings::NativeFormat);
    parameters.insert("device_model", hardwareSettings.value("NAME", "Unknown Mobile Device").toString());
    parameters.insert("system_version", QSysInfo::prettyProductName());
    parameters.insert("application_version", "0.17");
    // parameters.insert("use_test_dc", true);
    return parameters;
}

void TDLibWrapper::setInitialParameters()
{
    LOG("Sending initial parameters to TD Lib");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setTdlibParameters");
    // tdlibParameters were inlined between 1.8.5 and 1.8.6
    // See https://github.com/tdlib/td/commit/f6a2ecd
    if (versionNumber > VERSION_NUMBER(1,8,5)) {
        fillTdlibParameters(requestObject);
    } else {
        QVariantMap initialParameters;
        fillTdlibParameters(initialParameters);
        requestObject.insert("parameters", initialParameters);
    }
    this->sendRequest(requestObject);
}

void TDLibWrapper::setEncryptionKey()
{
    LOG("Setting database encryption key");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "checkDatabaseEncryptionKey");
    // see https://github.com/tdlib/td/issues/188#issuecomment-379536139
    requestObject.insert("encryption_key", "");
    this->sendRequest(requestObject);
}

void TDLibWrapper::setLogVerbosityLevel()
{
    LOG("Setting log verbosity level to something less chatty");
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "setLogVerbosityLevel");
    requestObject.insert("new_verbosity_level", 2);
    this->sendRequest(requestObject);
}

void TDLibWrapper::initializeOpenWith()
{
    LOG("Initialize open-with");LOG("Checking standard open URL file...");

    const QStringList sailfishOSVersion = QSysInfo::productVersion().split(".");
    int sailfishOSMajorVersion = sailfishOSVersion.value(0).toInt();
    int sailfishOSMinorVersion = sailfishOSVersion.value(1).toInt();

    const QString applicationsLocation(QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation));
    const QString openUrlFilePath(applicationsLocation + "/open-url.desktop");
    if (sailfishOSMajorVersion < 4 || ( sailfishOSMajorVersion == 4 && sailfishOSMinorVersion < 2 )) {
        if (QFile::exists(openUrlFilePath)) {
            LOG("Standard open URL file exists, good!");
        } else {
            LOG("Copying standard open URL file to " << openUrlFilePath);
            QFile::copy("/usr/share/applications/open-url.desktop", openUrlFilePath);
            QProcess::startDetached("update-desktop-database " + applicationsLocation);
        }
    } else {
        const QString sailfishBrowserFilePath(applicationsLocation + "/sailfish-browser.desktop");
        if (QFile::exists(sailfishBrowserFilePath)) {
            LOG("Removing existing local Sailfish browser file, that was not working as expected in 0.10...!");
            QFile::remove(sailfishBrowserFilePath);
            QProcess::startDetached("update-desktop-database " + applicationsLocation);
        }
        if (QFile::exists(openUrlFilePath)) {
            LOG("Old open URL file exists, that needs to go away...!");
            QFile::remove(openUrlFilePath);
            QProcess::startDetached("update-desktop-database " + applicationsLocation);
        }
        // Something special for Verla...
        if (sailfishOSMajorVersion == 4 && sailfishOSMinorVersion == 2) {
            LOG("Creating open URL file at " << openUrlFilePath);
            QFile openUrlFile(openUrlFilePath);
            if (openUrlFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QTextStream fileOut(&openUrlFile);
                fileOut.setCodec("UTF-8");
                fileOut << QString("[Desktop Entry]").toUtf8() << "\n";
                fileOut << QString("Type=Application").toUtf8() << "\n";
                fileOut << QString("Name=Browser").toUtf8() << "\n";
                fileOut << QString("Icon=icon-launcher-browser").toUtf8() << "\n";
                fileOut << QString("NoDisplay=true").toUtf8() << "\n";
                fileOut << QString("X-MeeGo-Logical-Id=sailfish-browser-ap-name").toUtf8() << "\n";
                fileOut << QString("X-MeeGo-Translation-Catalog=sailfish-browser").toUtf8() << "\n";
                fileOut << QString("MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;").toUtf8() << "\n";
                fileOut << QString("X-Maemo-Service=org.sailfishos.browser.ui").toUtf8() << "\n";
                fileOut << QString("X-Maemo-Object-Path=/ui").toUtf8() << "\n";
                fileOut << QString("X-Maemo-Method=org.sailfishos.browser.ui.openUrl").toUtf8() << "\n";
                fileOut.flush();
                openUrlFile.close();
                QProcess::startDetached("update-desktop-database " + applicationsLocation);
            }
        }
    }

    const QString desktopFilePath(applicationsLocation + "/harbour-fernschreiber2-open-url.desktop");
    QFile desktopFile(desktopFilePath);
    if (desktopFile.exists()) {
        LOG("Fernschreiber open-with file existing, removing...");
        desktopFile.remove();
        QProcess::startDetached("update-desktop-database " + applicationsLocation);
    }
    LOG("Creating Fernschreiber open-with file at " << desktopFile.fileName());
    if (desktopFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream fileOut(&desktopFile);
        fileOut.setCodec("UTF-8");
        fileOut << QString("[Desktop Entry]").toUtf8() << "\n";
        fileOut << QString("Type=Application").toUtf8() << "\n";
        fileOut << QString("Name=Ferniegram").toUtf8() << "\n";
        fileOut << QString("Icon=harbour-fernschreiber2").toUtf8() << "\n";
        fileOut << QString("NotShowIn=X-MeeGo;").toUtf8() << "\n";
        if (sailfishOSMajorVersion < 4 || ( sailfishOSMajorVersion == 4 && sailfishOSMinorVersion < 1 )) {
            fileOut << QString("MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/tg;").toUtf8() << "\n";
        } else {
            fileOut << QString("MimeType=x-url-handler/t.me;x-scheme-handler/tg;").toUtf8() << "\n";
        }
        fileOut << QString("X-Maemo-Service=io.github.roundedrectangle.fernschreiber2").toUtf8() << "\n";
        fileOut << QString("X-Maemo-Object-Path=/io/github/roundedrectangle/fernschreiber2").toUtf8() << "\n";
        fileOut << QString("X-Maemo-Method=io.github.roundedrectangle.fernschreiber2.openUrl").toUtf8() << "\n";
        fileOut << QString("Hidden=true;").toUtf8() << "\n";
        fileOut.flush();
        desktopFile.close();
        QProcess::startDetached("update-desktop-database " + applicationsLocation);
    }

    QString dbusPathName = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/dbus-1/services";
    QDir dbusPath(dbusPathName);
    if (!dbusPath.exists()) {
        LOG("Creating D-Bus directory" << dbusPathName);
        dbusPath.mkpath(dbusPathName);
    }
    QString dbusServiceFileName = dbusPathName + "/io.github.roundedrectangle.fernschreiber2.service";
    QFile dbusServiceFile(dbusServiceFileName);
    if (dbusServiceFile.exists()) {
        LOG("D-BUS service file existing, removing to ensure proper re-creation...");
        dbusServiceFile.remove();
    }
    LOG("Creating D-Bus service file at" << dbusServiceFile.fileName());
    if (dbusServiceFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream fileOut(&dbusServiceFile);
        fileOut.setCodec("UTF-8");
        fileOut << QString("[D-BUS Service]").toUtf8() << "\n";
        fileOut << QString("Name=io.github.roundedrectangle.fernschreiber2").toUtf8() << "\n";
        fileOut << QString("Exec=/usr/bin/sailjail -- /usr/bin/harbour-fernschreiber2").toUtf8() << "\n";
        fileOut.flush();
        dbusServiceFile.close();
    }
}

void TDLibWrapper::removeOpenWith()
{
    LOG("Remove open-with");
    QFile::remove(QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation) + "/harbour-fernschreiber2-open-url.desktop");
    QProcess::startDetached("update-desktop-database " + QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation));
}

const TDLibWrapper::Group *TDLibWrapper::updateGroup(qlonglong groupId, const QVariantMap &groupInfo, QHash<qlonglong,Group*> *groups)
{
    Group* group = groups->value(groupId);
    if (!group) {
        group = new Group(groupId);
        groups->insert(groupId, group);
    }
    group->groupInfo = groupInfo;
    return group;
}

const TDLibWrapper::Group* TDLibWrapper::getGroup(qlonglong groupId) const
{
    if (groupId) {
        const Group* group = superGroups.value(groupId);
        return group ? group : basicGroups.value(groupId);
    }
    return Q_NULLPTR;
}

TDLibWrapper::ChatType TDLibWrapper::chatTypeFromString(const QString &type)
{
    return (type == QStringLiteral("chatTypePrivate")) ? ChatTypePrivate :
        (type == QStringLiteral("chatTypeBasicGroup")) ? ChatTypeBasicGroup :
        (type == QStringLiteral("chatTypeSupergroup")) ? ChatTypeSupergroup :
        (type == QStringLiteral("chatTypeSecret")) ?  ChatTypeSecret :
        ChatTypeUnknown;
}

TDLibWrapper::ChatMemberStatus TDLibWrapper::chatMemberStatusFromString(const QString &status)
{
    // Most common ones first
    return (status == QStringLiteral("chatMemberStatusMember")) ? ChatMemberStatusMember :
        (status == QStringLiteral("chatMemberStatusLeft")) ? ChatMemberStatusLeft :
        (status == QStringLiteral("chatMemberStatusCreator")) ? ChatMemberStatusCreator :
        (status == QStringLiteral("chatMemberStatusAdministrator")) ?  ChatMemberStatusAdministrator :
        (status == QStringLiteral("chatMemberStatusRestricted")) ? ChatMemberStatusRestricted :
        (status == QStringLiteral("chatMemberStatusBanned")) ?  ChatMemberStatusBanned :
                                                                ChatMemberStatusUnknown;
}

TDLibWrapper::SecretChatState TDLibWrapper::secretChatStateFromString(const QString &state)
{
    return (state == QStringLiteral("secretChatStateClosed")) ? SecretChatStateClosed :
        (state == QStringLiteral("secretChatStatePending")) ? SecretChatStatePending :
        (state == QStringLiteral("secretChatStateReady")) ? SecretChatStateReady :
        SecretChatStateUnknown;
}

TDLibWrapper::ChatMemberStatus TDLibWrapper::Group::chatMemberStatus() const
{
    const QString statusType(groupInfo.value(STATUS).toMap().value(_TYPE).toString());
    return statusType.isEmpty() ? ChatMemberStatusUnknown : chatMemberStatusFromString(statusType);
}

void TDLibWrapper::getMessageProperties(qlonglong chatId, qlonglong messageId) {
    LOG("Retrieving message properties" << chatId << messageId);
    QVariantMap requestObject;
    requestObject.insert(CHAT_ID, chatId);
    requestObject.insert(MESSAGE_ID, messageId);
    QVariantMap extra(requestObject);
    requestObject.insert(_TYPE, "getMessageProperties");
    requestObject.insert(_EXTRA, extra);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getCustomEmojiStickers(QStringList ids) {
    LOG("Receiving stickers for custom emojis" << ids);
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getCustomEmojiStickers");
    requestObject.insert("custom_emoji_ids", ids);
    this->sendRequest(requestObject);
}

void TDLibWrapper::getCustomEmojiStickers(QString id) {
    LOG("Receiving sticker for custom emoji" << id);
    QStringList ids;
    ids.append(id);
    getCustomEmojiStickers(ids);
}

void TDLibWrapper::getStorageStatisticsFast() {
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "getStorageStatisticsFast");
    this->sendRequest(requestObject);
}

void TDLibWrapper::optimizeStorage(bool entire) {
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "optimizeStorage");
    if (entire) {
        requestObject.insert("size", 0);
        QVariantList fileTypesObject;
        for (QString type : ALL_FILE_TYPES) {
            QVariantMap fileType;
            fileType.insert(_TYPE, type);
            fileTypesObject.append(fileType);
        }
        requestObject.insert("file_types", fileTypesObject);
    }
    this->sendRequest(requestObject);
}

void TDLibWrapper::translateText(const QVariantMap &text, const QString &languageCode, qlonglong extraId) {
    QVariantMap requestObject;
    requestObject.insert(_TYPE, "translateText");
    requestObject.insert(TEXT, text);
    requestObject.insert("to_language_code", languageCode);
    requestObject.insert(_EXTRA, TRANSLATION + QString::number(extraId));
    this->sendRequest(requestObject);
}
