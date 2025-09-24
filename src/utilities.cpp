/*
    Copyright (C) 2020-21 Sebastian J. Wolf and other contributors

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

#include "utilities.h"
#include <QMap>
#include <QVariant>
#include <QAudioEncoderSettings>
#include <QStandardPaths>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QUrl>
#include <QUrlQuery>
#include <QDateTime>
#include <QGeoCoordinate>
#include <QGeoLocation>
#include <QSysInfo>
#include <QNetworkRequest>
#include <QNetworkReply>

#define DEBUG_MODULE Utilities
#include "debuglog.h"

namespace {
    const QString _TYPE("@type");
    const QString ID("id");
    const QString TYPE("type");
    const QString TEXT("text");
    const QString EMOJI("emoji");
    const QString ANIMATED_EMOJI("animated_emoji");
    const QString STICKER("sticker");
    const QString USER_ID("user_id");

    const QString MESSAGE_SENDER_TYPE_USER("messageSenderUser");
    const QString MESSAGE_SENDER_TYPE_CHAT("messageSenderChat");

    const QString MESSAGE_CONTENT_TYPE_TEXT("messageText");
    const QString MESSAGE_CONTENT_TYPE_STICKER("messageSticker");
    const QString MESSAGE_CONTENT_TYPE_DICE("messageDice");
    const QString MESSAGE_CONTENT_TYPE_ANIMATED_EMOJI("messageAnimatedEmoji");
    const QString MESSAGE_CONTENT_TYPE_PHOTO("messagePhoto");
    const QString MESSAGE_CONTENT_TYPE_VIDEO("messageVideo");
    const QString MESSAGE_CONTENT_TYPE_VIDEO_NOTE("messageVideoNote");
    const QString MESSAGE_CONTENT_TYPE_ANIMATION("messageAnimation");
    const QString MESSAGE_CONTENT_TYPE_AUDIO("messageAudio");
    const QString MESSAGE_CONTENT_TYPE_VOICE_NOTE("messageVoiceNote");
    const QString MESSAGE_CONTENT_TYPE_DOCUMENT("messageDocument");
    const QString MESSAGE_CONTENT_TYPE_LOCATION("messageLocation");
    const QString MESSAGE_CONTENT_TYPE_VENUE("messageVenue");

    const QString ENTITIES("entities");
    const QString TYPE_PLAIN_TEXT("plainText");
    const QString TEXT_ENTITY("textEntity");
    const QString OFFSET("offset");
    const QString LENGTH("length");
    const QString URL("url");
    const QString REMOVE_LENGTH("removeLength");
    const QString INSERTION_STRING("insertionString");
    const QString SCORE("score");

    const QString SPONSORED_MESSAGE("sponsoredMessage");
    const QString MESSAGE_SENDER_USER("messageSenderUser");
    const QString SENDER_ID("sender_id");
    const QString CONTENT("content");
    const QString CAPTION("caption");
    const QString VENUE("venue");
    const QString TITLE("title");
    const QString ADDRESS("address");

    const QString AMP("&");
    const QString HTML_AMP("&amp;");
    const QString LT("<");
    const QString HTML_LT("&lt;");
    const QString GT(">");
    const QString HTML_GT("&gt;");
    const QRegularExpression RAW_NEW_LINE_RE("\r?\n");
    const QString HTML_BR_TAG("<br>");

    const QRegularExpression AT_METION_ID_RE("\\@(?<type>\\d+)\\((?<text>[^\\)]+)\\)");
}

Utilities::Utilities(AppSettings *settings, TDLibWrapper *tdLibWrapper, QObject *parent)
    : QObject(parent)
    , appSettings(settings)
    , tdLibWrapper(tdLibWrapper)
    , manager(new QNetworkAccessManager(this))
{
    LOG("Initializing audio recorder...");

    QString temporaryDirectoryPath = this->getTemporaryDirectoryPath();
    QDir temporaryDirectory(temporaryDirectoryPath);
    if (!temporaryDirectory.exists()) {
        temporaryDirectory.mkpath(temporaryDirectoryPath);
    }

    QAudioEncoderSettings encoderSettings;
    encoderSettings.setCodec("audio/vorbis");
    encoderSettings.setChannelCount(1);
    encoderSettings.setQuality(QMultimedia::LowQuality);
    this->audioRecorder.setEncodingSettings(encoderSettings);
    this->audioRecorder.setContainerFormat("ogg");

    connect(&audioRecorder, &QAudioRecorder::durationChanged, this, &Utilities::voiceNoteDurationChanged);
    connect(&audioRecorder, &QAudioRecorder::statusChanged, this, &Utilities::voiceNoteRecordingStateChanged);

    this->geoPositionInfoSource = QGeoPositionInfoSource::createDefaultSource(this);
    if (this->geoPositionInfoSource) {
        LOG("Geolocation successfully initialized...");
        this->geoPositionInfoSource->setUpdateInterval(5000);
        connect(geoPositionInfoSource, SIGNAL(positionUpdated(QGeoPositionInfo)), this, SLOT(handleGeoPositionUpdated(QGeoPositionInfo)));
    } else {
        LOG("Unable to initialize geolocation!");
    }
}

Utilities::~Utilities() {
    if (this->geoPositionInfoSource)
        this->geoPositionInfoSource->stopUpdates();
    QString temporaryDirectoryPath = this->getTemporaryDirectoryPath();
    QDirIterator temporaryDirectoryIterator(temporaryDirectoryPath, QDir::Files | QDir::NoDotAndDotDot | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (temporaryDirectoryIterator.hasNext()) {
        QString nextFilePath = temporaryDirectoryIterator.next();
        if (QFile::remove(nextFilePath))
            LOG("Temporary file removed " << nextFilePath);
        else LOG("Error removing temporary file " << nextFilePath);
    }
}

QString Utilities::fixReservedHtmlCharacters(const QString &text) {
    return QString(text).replace(LT, HTML_LT).replace(GT, HTML_GT).replace(RAW_NEW_LINE_RE, HTML_BR_TAG);
}

// FIXME: (possibly) Use a custom class instead of QVariantMap for messageInstertions
void Utilities::handleHtmlEntity(const QString &messageText, QList<QVariantMap> &messageInsertions, const QString &originalString, const QString &replacementString) {
    int nextIndex = -1;
    while ((nextIndex = messageText.indexOf(originalString, nextIndex + 1)) > -1) {
        const QVariantMap insertion{
            {OFFSET, nextIndex},
            {INSERTION_STRING, replacementString},
            {REMOVE_LENGTH, originalString.length()},
        };
        messageInsertions.append(insertion);
    }
}

bool messageInsertionSorter(const QVariantMap &a, const QVariantMap &b) {
    // Sort in reverse order (so offset indexes are valid)
    return b.value(OFFSET).toInt() + b.value(REMOVE_LENGTH).toInt() < a.value(OFFSET).toInt() + a.value(REMOVE_LENGTH).toInt();
}

QVariantMap Utilities::newFormattedText(const QString &text, const QVariantList &entities) {
    QVariantMap formattedText{{_TYPE, "formattedText"}, {TEXT, text}};
    if (entities.length() > 0)
        formattedText.insert("entities", entities);
    return formattedText;
}

static bool compareReplacements(const QVariant &replacement1, const QVariant &replacement2) {
    return replacement1.toMap().value("startIndex").toInt() < replacement2.toMap().value("startIndex").toInt();
}

QList<QVariantMap> Utilities::findFormattedTextReplacements(const QRegularExpression &re, const QString &text, const QString &entityType, const QString &typeParameter) {
    QList<QVariantMap> replacements;

    QRegularExpressionMatchIterator iterator = re.globalMatch(text);
    while (iterator.hasNext()) {
        QRegularExpressionMatch match = iterator.next();
        LOG("Found match for formatted text replacements");
        QVariantMap type{{_TYPE, entityType}};
        if (!typeParameter.isEmpty()) {
            const QString typeParameterValue = match.captured(TYPE);
            if (!typeParameterValue.isEmpty()) type.insert(typeParameter, typeParameterValue);
        }
        replacements.append(QVariantMap{
                                {"startIndex", match.capturedStart(0)},
                                {"length", match.capturedLength(0)},
                                {TYPE, type},
                                {TYPE_PLAIN_TEXT, match.captured(TEXT)}
                            });
    }
    return replacements;
}

QVariantList Utilities::formattedTextEntitiesFromReplacements(QList<QVariantMap> &replacements, QString &text) {
    QVariantList entities;
    if (!replacements.isEmpty()) {
        std::sort(replacements.begin(), replacements.end(), compareReplacements);
        int offsetCorrection = 0;
        for (const QVariantMap &replacement : replacements) {
            int replacementStartOffset = replacement.value("startIndex").toInt();
            int replacementLength = replacement.value("length").toInt();
            const QString replacementPlainText = replacement.value(TYPE_PLAIN_TEXT).toString();
            text.replace(replacementStartOffset - offsetCorrection, replacementLength, replacementPlainText);
            entities.append(QVariantMap{
                {"offset", replacementStartOffset - offsetCorrection},
                {"length", replacementPlainText.length()},
                {TYPE, replacement.value(TYPE).toMap()}
            });
            offsetCorrection += replacementLength - replacementPlainText.length();
        }
    }
    return entities;
}

QVariantMap Utilities::enhanceInputText(const QString &originalText) {
    // Postprocess message (e.g. for @-mentioning)
    QString text = originalText;

    QList<QVariantMap> replacements;
    replacements += findFormattedTextReplacements(AT_METION_ID_RE, text, "textEntityTypeMentionName", USER_ID);

    const QVariantList entities = Utilities::formattedTextEntitiesFromReplacements(replacements, text);
    return newFormattedText(text, entities);
}

QString Utilities::enhanceMessageText(const QVariantMap &formattedText, bool ignoreEntities, bool escapeReserved) {
    if (formattedText.isEmpty()) return "";

    QString messageText = formattedText.value(TEXT).toString();
    if (ignoreEntities) return messageText;

    const QVariantList entities = formattedText.value(ENTITIES).toList();
    if(entities.isEmpty())
        return escapeReserved ? fixReservedHtmlCharacters(messageText) : messageText;

    QList<QVariantMap> messageInsertions;

    //emojiSize = Math.round((typeof emojiSize === 'undefined' ? Silica.Theme.fontSizeSmall : emojiSize) * 1.15)
    for (const QVariant &entityVariant : entities) {
        const QVariantMap entity = entityVariant.toMap();
        if (entity.value(_TYPE) != TEXT_ENTITY)
            continue;
        const QString entityType = entity.value(TYPE).toMap().value(_TYPE).toString();

        QString start, end;
        // int startRemove, endRemove; // possibly unit? probably not because it can also remove length in the opposite direction in theory (at least it (probably) could in JS); unused for now

        if (entityType == "textEntityTypeBold") {
            start = "<b>";
            end = "</b>";
        } else if (entityType == "textEntityTypeUrl") {
            start = "<a href=\"" + messageText.mid(entity.value(OFFSET).toInt(), entity.value(LENGTH).toInt()) + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypeCode") {
            start = "<pre>";
            end = "</pre>";
        } else if (entityType == "textEntityTypeEmailAddress") {
            start = "<a href=\"mailto:" + messageText.mid(entity.value(OFFSET).toInt(), entity.value(LENGTH).toInt()) + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypeItalic") {
            start = "<i>";
            end = "</i>";
        } else if (entityType == "textEntityTypeStrikethrough") {
            start = "<s>";
            end = "</s>";
        } else if (entityType == "textEntityTypeMention") {
            start = "<a href=\"user://" + messageText.mid(entity.value(OFFSET).toInt(), entity.value(LENGTH).toInt()) + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypeMentionName") {
            start = "<a href=\"userId://" + entity.value(TYPE).toMap().value(USER_ID).toString() + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypePhoneNumber") {
            start = "<a href=\"tel:" + messageText.mid(entity.value(OFFSET).toInt(), entity.value(LENGTH).toInt()) + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypePre" || entityType == "textEntityTypePreCode") {
            start = "<pre>";
            end = "</pre>";
        } else if (entityType == "textEntityTypeTextUrl") {
            start = "<a href=\"" + entity.value(TYPE).toMap().value(URL).toString() + "\">";
            end = "</a>";
        } else if (entityType == "textEntityTypeUnderline") {
            start = "<u>";
            end = "</u>";
        } else if (entityType == "textEntityTypeBotCommand") {
            start = "<a href=\"botCommand://" + messageText.mid(entity.value(OFFSET).toInt(), entity.value(LENGTH).toInt()) + "\">";
            end = "</a>";
        }

        /*case 'textEntityTypeCustomEmoji': // disabled for now
            // FIXME as it works terribly; maybe do a global TDLibFile object?; maybe in StickerManager even though it was not created for exactly this?
            // + this doesn't work at all with online only mode
            var emoji = entity.type.custom_emoji_id
            if (stickerManager.hasCustomEmoji(emoji)) {
                var sticker = stickerManager.getCustomEmojiSticker(emoji)
                if (sticker.format['@type'] === 'stickerFormatWebm') break
                var file = createTdlibFile(sticker.sticker)
                if (!file.isDownloadingCompleted || !file.path) {
                    file.downloadingCompletedChanged.connect(function(){ if(file.isDownloadingCompleted) {
                        file.destroy() // Should we do it or is it happening automatically?
                        reloader(true)
                    }})
                    break
                }
                messageInsertions.push({offset: entity.offset, insertionString: Emoji.getEmojiTag(file.path, emojiSize), removeLength: entity.length})
                file.destroy() // Should we do it or is it happening automatically?
            } else {
                tdLibWrapper.getCustomEmojiStickers(emoji)
                if (typeof reloader !== 'undefined')
                    stickerManager.customEmojiReceived.connect(function(emojiId) {
                        if (emojiId == emoji) reloader(true)
                    })
            }
        break*/

        const QVariantMap entityResultStart{
            {OFFSET, entity.value(OFFSET).toInt()},
            {INSERTION_STRING, start},
            {REMOVE_LENGTH, 0}, // startRemove
        };
        const QVariantMap entityResultEnd{
            {OFFSET, entity.value(OFFSET).toInt() + entity.value(LENGTH).toInt()},
            {INSERTION_STRING, end},
            {REMOVE_LENGTH, 0}, // endRemove
        };
        messageInsertions.append(entityResultStart);
        messageInsertions.append(entityResultEnd);
    }

    if(messageInsertions.isEmpty())
        return escapeReserved ? fixReservedHtmlCharacters(messageText) : messageText;

    if (escapeReserved) {
        handleHtmlEntity(messageText, messageInsertions, AMP, HTML_AMP);
        handleHtmlEntity(messageText, messageInsertions, LT, HTML_LT);
        handleHtmlEntity(messageText, messageInsertions, GT, HTML_GT);
    }

    std::sort(messageInsertions.begin(), messageInsertions.end(), messageInsertionSorter);
    for (QVariantMap insertion : messageInsertions)
        messageText.replace(insertion.value(OFFSET).toInt(), insertion.value(REMOVE_LENGTH).toInt(), insertion.value(INSERTION_STRING).toString());

    if (escapeReserved)
        messageText.replace(RAW_NEW_LINE_RE, HTML_BR_TAG);

    return messageText;
}

QVariant Utilities::getMaybeFormattedMessageText(const QVariantMap &messageContent, const QString &messageSenderType, qlonglong messageSenderUserId, bool isSponsored, bool simple) const {
    const QString contentType = messageContent.value(_TYPE).toString();
    const bool myself = !isSponsored
            && messageSenderType == MESSAGE_SENDER_USER
            && messageSenderUserId == this->tdLibWrapper->getUserInformation().value(ID).toLongLong();

    auto getCaption = [&](QString text) -> const QVariant {
        // should we convert it to string/map and then back to qvariant?
        const QVariantMap caption = messageContent.value(CAPTION).toMap();
        const QString captionText = caption.value(TEXT).toString();
        if (captionText.isEmpty() && caption.value(ENTITIES).toList().isEmpty())
            return QVariant();

        if (simple) return text.arg(captionText);
        return caption;
    };

    if (contentType == MESSAGE_CONTENT_TYPE_TEXT)
        return simple ? messageContent.value(TEXT).toMap().value(TEXT)
                      : messageContent.value(TEXT);
    if (contentType == MESSAGE_CONTENT_TYPE_STICKER)
        return simple ? messageContent.value(STICKER).toMap().value(EMOJI).toString() : "";
    if (contentType == MESSAGE_CONTENT_TYPE_DICE)
        return simple ? messageContent.value(EMOJI).toString() : "";
    if (contentType == MESSAGE_CONTENT_TYPE_ANIMATED_EMOJI)
        return simple ? messageContent.value(ANIMATED_EMOJI).toMap().value(STICKER).toMap().value(EMOJI).toString() : "";
    if (contentType == MESSAGE_CONTENT_TYPE_PHOTO) {
        if (const QVariant caption = getCaption(tr("Picture: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent a picture", "myself") : tr("sent a picture")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_VIDEO) {
        if (const QVariant caption = getCaption(tr("Video: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent a video", "myself") : tr("sent a video")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_VIDEO_NOTE)
        return simple ? (myself ? tr("sent a video message", "myself") : tr("sent a video message")) : "";
    if (contentType == MESSAGE_CONTENT_TYPE_ANIMATION) {
        if (const QVariant caption = getCaption(tr("Animation: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent an animation", "myself") : tr("sent an animation")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_AUDIO) {
        if (const QVariant caption = getCaption(tr("Audio: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent an audio", "myself") : tr("sent an audio")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_DOCUMENT) {
        if (const QVariant caption = getCaption(tr("Document: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent a document", "myself") : tr("sent a document")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_VOICE_NOTE) {
        if (const QVariant caption = getCaption(tr("Voice message: %1")); caption.isValid())
            return caption;
        else return simple ? (myself ? tr("sent a voice message", "myself") : tr("sent a voice message")) : "";
    }
    if (contentType == MESSAGE_CONTENT_TYPE_LOCATION)
        return simple ? (myself ? tr("sent a location", "myself") : tr("sent a location")) : "";
    if (contentType == MESSAGE_CONTENT_TYPE_VENUE)
        return simple ? (myself ? tr("sent a venue", "myself") : tr("sent a venue")) : ("<b>" + messageContent.value(VENUE).toMap().value(TITLE).toString() + "</b>, " + messageContent.value(VENUE).toMap().value(ADDRESS).toString());
    if (contentType == "messageContactRegistered")
        return myself ? tr("have registered with Telegram", "myself") : tr("has registered with Telegram");
    if (contentType == "messageChatJoinByLink")
        return myself ? tr("joined this chat", "myself") : tr("joined this chat");
    if (contentType == "messageChatAddMembers") {
        if (messageSenderType == MESSAGE_SENDER_TYPE_USER && messageSenderUserId == messageContent.value("member_user_ids").toList().at(0).toLongLong()) {
            return myself ? tr("were added to this chat", "myself") : tr("was added to this chat");
        } else {
            QVariantList memberUserIds = messageContent.value("member_user_ids").toList();
            QString addedUserNames;
            for (int i = 0; i < memberUserIds.size(); i++) {
                if (i > 0) {
                    addedUserNames += ", ";
                }
                addedUserNames += getUserName(this->tdLibWrapper->getUserInformation(memberUserIds.at(i).toLongLong()));
            }
            return myself ? tr("have added %1 to the chat", "myself").arg(addedUserNames) : tr("has added %1 to the chat").arg(addedUserNames);
        }
    }
    if (contentType == "messageChatDeleteMember") {
        if (messageSenderType == MESSAGE_SENDER_TYPE_USER && messageSenderUserId == messageContent.value(USER_ID).toLongLong()) {
            return myself ? tr("left this chat", "myself") : tr("left this chat");
        } else {
            return myself ? tr("have removed %1 from the chat", "myself").arg(getUserName(this->tdLibWrapper->getUserInformation(messageContent.value("user_id").toLongLong()))) : tr("has removed %1 from the chat").arg(getUserName(this->tdLibWrapper->getUserInformation(messageContent.value("user_id").toLongLong())));
        }
    }
    if (contentType == "messageChatChangeTitle")
        return myself ? tr("changed the chat title to %1", "myself").arg(messageContent.value(TITLE).toString()) : tr("changed the chat title to %1").arg(messageContent.value(TITLE).toString());
    if (contentType == "messagePoll") {
        const QVariantMap poll = messageContent.value("poll").toMap();
        const bool anonymnous = poll.value("is_anonymous").toBool();
        if (poll.value(TYPE).toMap().value(_TYPE).toString() == "pollTypeQuiz") {
            if (anonymnous)
                return simple ? (myself ? tr("sent an anonymous quiz", "myself") : tr("sent an anonymous quiz")) : ("<b>" + tr("Anonymous Quiz") + "</b>");
            return simple ? (myself ? tr("sent a quiz", "myself") : tr("sent a quiz")) : ("<b>" + tr("Quiz") + "</b>");
        }
        if (anonymnous)
            return simple ? (myself ? tr("sent an anonymous poll", "myself") : tr("sent an anonymous poll")) : ("<b>" + tr("Anonymous Poll") + "</b>");
        return simple ? (myself ? tr("sent a poll", "myself") : tr("sent a poll")) : ("<b>" + tr("Poll") + "</b>");
    }
    if (contentType == "messageBasicGroupChatCreate" || contentType == "messageSupergroupChatCreate")
        return myself ? tr("created this group", "myself") : tr("created this group");
    if (contentType == "messageChatChangePhoto")
        return myself ? tr("changed the chat photo", "myself") : tr("changed the chat photo");
    if (contentType == "messageChatDeletePhoto")
        return myself ? tr("deleted the chat photo", "myself") : tr("deleted the chat photo");
    if (contentType == "messageChatSetTtl" || contentType == "messageChatSetMessageAutoDeleteTime")
        // TODO: removed & actual auto delete time/period/duration...
        return myself ? tr("changed the secret chat TTL setting", "myself; TTL = Time To Live") : tr("changed the secret chat TTL setting", "TTL = Time To Live");
    if (contentType == "messageChatUpgradeFrom" || contentType == "messageChatUpgradeTo")
        return myself ? tr("upgraded this group to a supergroup", "myself") : tr("upgraded this group to a supergroup");
    if (contentType == "messageCustomServiceAction")
        return messageContent.value(TEXT).toString();
    if (contentType == "messagePinMessage")
        // TODO: show actual pinned message (and go to it when clicked); requires proper message jumping implementation
        return myself ? tr("pinned a message", "myself") : tr("pinned a message");
    if (contentType == "messageExpiredPhoto")
        return myself ? tr("sent a self-destructing photo that is expired", "myself") : tr("sent a self-destructing photo that is expired");
    if (contentType == "messageExpiredVideo")
        return myself ? tr("sent a self-destructing video that is expired", "myself") : tr("sent a self-destructing video that is expired");
    if (contentType == "messageExpiredVoiceNote")
        return myself ? tr("sent a self-destructing voice message that is expired", "myself") : tr("sent a self-destructing voice message that is expired");
    if (contentType == "messageExpiredVideoNote")
        return myself ? tr("sent a self-destructing video message that is expired", "myself") : tr("sent a self-destructing video message that is expired");
    if (contentType == "messageScreenshotTaken")
        return myself ? tr("created a screenshot in this chat", "myself") : tr("created a screenshot in this chat");
    if (contentType == "messageGame")
        return simple ? (myself ? tr("sent a game", "myself") : tr("sent a game")) : "";
    if (contentType == "messageGameScore") {
        qint32 score = messageContent.value("score").toInt();
        return myself ? tr("scored %Ln points", "myself", score) : tr("scored %Ln points", "", score);
    }
    if (contentType == "messageBotWriteAccessAllowed") {
        QVariantMap reason = messageContent.value("reason").toMap();
        QString reasonType = reason.value(_TYPE).toString();
        if (reasonType == "botWriteAccessAllowReasonAddedToAttachmentMenu")
            return tr("you allowed this bot to message you when you added it to your attachment menu");
        if (reasonType == "botWriteAccessAllowReasonConnectedWebsite")
            return tr("you allowed this bot to message you when you logged in on %1").arg(reason.value("domain_name").toString());
        if (reasonType == "botWriteAccessAllowReasonLaunchedWebApp")
            return tr("you allowed this bot to message you in its web-app");
        return tr("you allowed this bot to message you"); // botWriteAccessAllowReasonAcceptedRequest
    }
    if (contentType == "messageChatBoost")
        return myself ? tr("boosted this chat %Ln times", "myself", messageContent.value("boost_count").toInt())
                      : tr("boosted this chat %Ln times", "", messageContent.value("boost_count").toInt());
    if (contentType == "messageGift")
        // TODO: make this only for simple and add an actual message for gift
        return myself ? tr("sent a gift", "myself") : tr("sent a gift");
    if (contentType == "messageGiveawayCreated")
        // TODO: same as for gift
        return myself ? tr("started a giveaway", "myself") : tr("started a giveaway");
    if (contentType == "messageGiveawayCompleted")
        return myself ? tr("a giveaway was completed", "myself") : tr("a giveaway was completed");
    if (contentType == "messageUnsupported")
        return myself ? tr("sent an unsupported message", "myself") : tr("sent an unsupported message");

    return myself
            ? tr("sent an unsupported message: %1", "myself; %1 is message type").arg(contentType.mid(7))
            : tr("sent an unsupported message: %1", "%1 is message type").arg(contentType.mid(7));
}

QVariant Utilities::getMaybeFormattedMessageText(const QVariantMap &message, bool simple) const {
    const QVariantMap messageSender = message.value(SENDER_ID).toMap();
    return getMaybeFormattedMessageText(
                message.value(CONTENT).toMap(),
                messageSender.value(_TYPE).toString(),
                messageSender.value(USER_ID).toLongLong(),
                message.value(_TYPE).toString() == SPONSORED_MESSAGE,
                simple
                );
}

QString Utilities::getMessageText(const QVariantMap &message, bool simple, bool ignoreEntities, bool escapeReserved) const {
    const QVariant text = getMaybeFormattedMessageText(message, simple);
    if (text.userType() == QMetaType::QVariantMap)
        return enhanceMessageText(text.toMap(), ignoreEntities, escapeReserved);
    return text.toString();
}

QVariantMap Utilities::getFormattedMessageText(const QVariantMap &message, bool simple) const {
    const QVariant text = getMaybeFormattedMessageText(message, simple);
    if (text.userType() == QMetaType::QString)
        return newFormattedText(text.toString());
    return text.toMap();
}

QString Utilities::getMessageContentText(const QVariantMap messageContent, bool simple, bool ignoreEntities, bool escapeReserved) const {
    const QVariant text = getMaybeFormattedMessageText(
                messageContent,
                MESSAGE_SENDER_TYPE_CHAT, // Skips all user-related checks
                0,
                false,
                simple
                );
    if (text.userType() == QMetaType::QVariantMap)
        return enhanceMessageText(text.toMap(), ignoreEntities, escapeReserved);
    return text.toString();
}

QString Utilities::getUserName(const QVariantMap &userInformation) {
    const QString firstName = userInformation.value("first_name").toString();
    const QString lastName = userInformation.value("last_name").toString();
    return QString(firstName + " " + lastName).trimmed();
}

void Utilities::startRecordingVoiceNote() {
    LOG("Start recording voice note...");
    this->audioRecorder.setOutputLocation(QUrl::fromLocalFile(this->getTemporaryDirectoryPath() + "/voicenote-" + QDateTime::currentDateTime().toString("yyyy-MM-dd-HH-mm-ss") + ".ogg"));
    this->audioRecorder.setVolume(appSettings->voiceNoteVolume());
    this->audioRecorder.record();
}

void Utilities::stopRecordingVoiceNote() {
    LOG("Stop recording voice note...");
    this->audioRecorder.stop();
}

void Utilities::startGeoLocationUpdates() {
    if (this->geoPositionInfoSource)
        this->geoPositionInfoSource->startUpdates();
}

void Utilities::stopGeoLocationUpdates() {
    if (this->geoPositionInfoSource)
        this->geoPositionInfoSource->stopUpdates();
}

void Utilities::initiateReverseGeocode(double latitude, double longitude)
{
    LOG("Initiating reverse geocode:" << latitude << longitude);
    QUrl url = QUrl("https://nominatim.openstreetmap.org/reverse");
    QUrlQuery urlQuery;
    urlQuery.addQueryItem("lat", QString::number(latitude));
    urlQuery.addQueryItem("lon", QString::number(longitude));
    urlQuery.addQueryItem("format", "json");
    url.setQuery(urlQuery);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "Ferniegram (Sailfish OS)");
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("Accept-Charset", "utf-8");
    request.setRawHeader("Connection", "close");
    request.setRawHeader("Cache-Control", "max-age=0");
    QNetworkReply *reply = manager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(handleReverseGeocodeFinished()));
}

Utilities::VoiceNoteRecordingState Utilities::getVoiceNoteRecordingState() const {
    switch (this->audioRecorder.status()) {
    case QMediaRecorder::LoadedStatus:
    case QMediaRecorder::PausedStatus:
        return VoiceNoteRecordingState::Ready;
    case QMediaRecorder::StartingStatus:
        return VoiceNoteRecordingState::Starting;
    case QMediaRecorder::FinalizingStatus:
        return VoiceNoteRecordingState::Stopping;
    case QMediaRecorder::RecordingStatus:
        return VoiceNoteRecordingState::Recording;
    default:
        return VoiceNoteRecordingState::Unavailable;
    }
}

void Utilities::handleGeoPositionUpdated(const QGeoPositionInfo &info)
{
    LOG("Geo position was updated");
    QVariantMap positionInformation;
    if (info.hasAttribute(QGeoPositionInfo::HorizontalAccuracy)) {
        positionInformation.insert("horizontalAccuracy", info.attribute(QGeoPositionInfo::HorizontalAccuracy));
    } else {
        positionInformation.insert("horizontalAccuracy", 0);
    }
    if (info.hasAttribute(QGeoPositionInfo::VerticalAccuracy)) {
        positionInformation.insert("verticalAccuracy", info.attribute(QGeoPositionInfo::VerticalAccuracy));
    } else {
        positionInformation.insert("verticalAccuracy", 0);
    }
    QGeoCoordinate geoCoordinate = info.coordinate();
    positionInformation.insert("latitude", geoCoordinate.latitude());
    positionInformation.insert("longitude", geoCoordinate.longitude());

    this->initiateReverseGeocode(geoCoordinate.latitude(), geoCoordinate.longitude());

    emit newPositionInformation(positionInformation);
}

void Utilities::handleReverseGeocodeFinished()
{
    qDebug() << "Utilities::handleReverseGeocodeFinished";
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        return;
    }

    QJsonDocument jsonDocument = QJsonDocument::fromJson(reply->readAll());
    qDebug().noquote() << jsonDocument.toJson(QJsonDocument::Indented);
    if (jsonDocument.isObject()) {
        QJsonObject responseObject = jsonDocument.object();
        emit newGeocodedAddress(responseObject.value("display_name").toString());
    }
}

QString Utilities::getTemporaryDirectoryPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::TempLocation) +  + "/harbour-fernschreiber2";
}

QVariantList Utilities::decodeWaveform(QString encodedData) {
    QByteArray waveform = QByteArray::fromBase64(encodedData.toUtf8());

    QVariantList result;
    for (int i=0; i < (waveform.length() * 8 / 5); i++) {
        int j = (i * 5) / 8, shift = (i * 5) % 8;
        result.insert(i, ((waveform[j] | ((j + 1 < waveform.size() ? waveform[j + 1] : 0) << 8)) >> shift & 0x1F) / 31.0);
    }

    return result.mid(0, 100);
}

QString Utilities::encodeWaveform(QVariantList waveform) {
    // idk how some parts work in this but it works

    const int numBits = waveform.length() * 5;
    QByteArray result((numBits + 7) / 8 + 1, 0);

    char *data = result.data();
    for (int i=0; i < waveform.length(); i++) {
        const int bitOffset = i * 5;
        const int value = static_cast<int>(waveform[i].toDouble() * 31.0) & 31;

        char* bytes = data + (bitOffset / 8);
        const int bitInByte = bitOffset % 8;

        // Cast to uint32_t pointer for 4-byte aligned write
        uint32_t* ptr = reinterpret_cast<uint32_t*>(bytes);
        *ptr |= static_cast<uint32_t>(value) << bitInByte;
    }

    return QString::fromUtf8(result.toBase64());
}

QVariantList Utilities::getWaveformData(QString encodedData, int count) {
    if (count < 1) return QVariantList();
    QVariantList waveform = decodeWaveform(encodedData);
    if (waveform.size() == count) return waveform;

    QVariantList result;

    if (waveform.size() > count) {
        auto sumQVariantDoubles = [](double a, const QVariant &b) { return a + b.toDouble(); };
        const int chunk = waveform.size() / count,
                remainder = waveform.size() % count;

        for (int i = 0; i < count - 1; i++) {
            const double sum = std::accumulate(waveform.begin() + i*chunk, waveform.begin() + (i+1)*chunk, 0.0, sumQVariantDoubles);
            result.append(((sum / chunk) + 0.06) / 1.06); // make 0 visible
            LOG(((sum / chunk) + 0.06) / 1.06);
        }

        const double sum = std::accumulate(waveform.end() - 1 - remainder, waveform.end(), 0.0, sumQVariantDoubles);
        result.append(((sum / (chunk + remainder)) + 0.06) / 1.06); // make 0 visible
    } else {
        for (int i=0; i < waveform.size(); i++)
            result.append(waveform[i]);
        for (int i=0; i < count - waveform.size(); i++)
            result.append(0.06 / 1.06);
    }

    return result;
}
