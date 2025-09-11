/*
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

#include "appsettings.h"

#define DEBUG_MODULE AppSettings
#include "debuglog.h"

namespace {
    const QString SEND_BY_ENTER("sendByEnter");
    const QString FOCUS_TEXTAREA_AFTER_SEND("focusTextAreaAfterSend");
    const QString USE_OPEN_WITH("useOpenWith");
    const QString SHOW_STICKERS_AS_EMOJIS("showStickersAsEmojis");
    const QString SHOW_STICKERS_AS_IMAGES("showStickersAsImages");
    const QString ANIMATE_STICKERS("animateStickers");
    const QString VIDEO_STICKERS("videoStickers");
    const QString NOTIFICATION_TURNS_DISPLAY_ON("notificationTurnsDisplayOn");
    const QString NOTIFICATION_SOUNDS_ENABLED("notificationSoundsEnabled");
    const QString NOTIFICATION_SUPPRESS_ENABLED("notificationSuppressContent");
    const QString NOTIFICATION_FEEDBACK("notificationFeedback");
    const QString NOTIFICATION_ALWAYS_SHOW_PREVIEW("notificationAlwaysShowPreview");
    const QString GO_TO_QUOTED_MESSAGE("goToQuotedMessage");
    const QString STORAGE_OPTIMIZER("useStorageOptimizer");
    const QString INLINEBOT_LOCATION_ACCESS("allowInlineBotLocationAccess");
    const QString REMAINING_INTERACTION_HINTS("remainingInteractionHints");
    const QString REMAINING_DOUBLE_TAP_HINTS("remainingDoubleTapHints");
    const QString ONLINE_ONLY_MODE("onlineOnlyMode");
    const QString DELAY_MESSAGE_READ("delayMessageRead");
    const QString FOCUS_TEXTAREA_ON_CHAT_OPEN("focusTextAreaOnChatOpen");
    const QString SPONSORED_MESS("sponsoredMess");
    const QString HIGHLIGHT_UNREADCONVS("highlightUnreadConversations");
    const QString SEND_ATTACHMENT_BY_ENTER("sendAttachmentByEnter");
    const QString VOICE_NOTE_VOLUME("voiceNoteVolumne");
    const QString SHOW_TRANSLATE_OPTION("showTranslateOption");
    const QString FORMATTED_TRANSLATE("formattedTranslate");
    const QString SEND_MARKDOWN("sendMarkdown");
    const QString UNREAD_COUNT_INCLUDE_MUTED("unreadCountIncludeMuted");
    const QString SHOW_FOLDER_UNREAD_COUNT("showFolderUnreadCount");
    const QString FOLDERS_UNREAD_COUNT_INCLUDE_MUTED("foldersUnreadCountIncludeMuted");
    const QString ARCHIVE_CHAT_LIST_HINT_COMPLETED("archiveChatListHintCompleted");
    const QString CHAT_FOLDERS_TABS_ON_BOTTOM("chatFoldersTabsOnBottom");
}

AppSettings::AppSettings(QObject *parent) :
    QObject(parent),
    settings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/io.github.roundedrectangle/fernschreiber2/settings.conf", QSettings::NativeFormat)
{}

bool AppSettings::getSendByEnter() const
{
    return settings.value(SEND_BY_ENTER, false).toBool();
}

void AppSettings::setSendByEnter(bool sendByEnter)
{
    if (getSendByEnter() != sendByEnter) {
        LOG(SEND_BY_ENTER << sendByEnter);
        settings.setValue(SEND_BY_ENTER, sendByEnter);
        emit sendByEnterChanged();
    }
}

bool AppSettings::getFocusTextAreaAfterSend() const
{
    return settings.value(FOCUS_TEXTAREA_AFTER_SEND, false).toBool();
}

void AppSettings::setFocusTextAreaAfterSend(bool focusTextAreaAfterSend)
{
    if (getFocusTextAreaAfterSend() != focusTextAreaAfterSend) {
        LOG(FOCUS_TEXTAREA_AFTER_SEND << focusTextAreaAfterSend);
        settings.setValue(FOCUS_TEXTAREA_AFTER_SEND, focusTextAreaAfterSend);
        emit focusTextAreaAfterSendChanged();
    }
}

bool AppSettings::getUseOpenWith() const
{
    return settings.value(USE_OPEN_WITH, true).toBool();
}

void AppSettings::setUseOpenWith(bool useOpenWith)
{
    if (getUseOpenWith() != useOpenWith) {
        LOG(USE_OPEN_WITH << useOpenWith);
        settings.setValue(USE_OPEN_WITH, useOpenWith);
        emit useOpenWithChanged();
    }
}

bool AppSettings::showStickersAsEmojis() const
{
    return settings.value(SHOW_STICKERS_AS_EMOJIS, false).toBool();
}

void AppSettings::setShowStickersAsEmojis(bool showAsEmojis)
{
    if (showStickersAsEmojis() != showAsEmojis) {
        LOG(SHOW_STICKERS_AS_EMOJIS << showAsEmojis);
        settings.setValue(SHOW_STICKERS_AS_EMOJIS, showAsEmojis);
        emit showStickersAsEmojisChanged();
    }
}

bool AppSettings::showStickersAsImages() const
{
    return settings.value(SHOW_STICKERS_AS_IMAGES, false).toBool();
}

void AppSettings::setShowStickersAsImages(bool showAsImages)
{
    if (showStickersAsImages() != showAsImages) {
        LOG(SHOW_STICKERS_AS_IMAGES << showAsImages);
        settings.setValue(SHOW_STICKERS_AS_IMAGES, showAsImages);
        emit showStickersAsImagesChanged();
    }
}

bool AppSettings::animateStickers() const
{
    return settings.value(ANIMATE_STICKERS, true).toBool();
}

void AppSettings::setAnimateStickers(bool animate)
{
    if (animateStickers() != animate) {
        LOG(ANIMATE_STICKERS << animate);
        settings.setValue(ANIMATE_STICKERS, animate);
        emit animateStickersChanged();
    }
}

bool AppSettings::videoStickers() const {
    return settings.value(VIDEO_STICKERS, true).toBool();
}
void AppSettings::setVideoStickers(bool value) {
    if (videoStickers() != value) {
        LOG(VIDEO_STICKERS << value);
        settings.setValue(VIDEO_STICKERS, value);
        emit videoStickersChanged();
    }
}

bool AppSettings::notificationTurnsDisplayOn() const
{
    return settings.value(NOTIFICATION_TURNS_DISPLAY_ON, false).toBool();
}

void AppSettings::setNotificationTurnsDisplayOn(bool turnOn)
{
    if (notificationTurnsDisplayOn() != turnOn) {
        LOG(NOTIFICATION_TURNS_DISPLAY_ON << turnOn);
        settings.setValue(NOTIFICATION_TURNS_DISPLAY_ON, turnOn);
        emit notificationTurnsDisplayOnChanged();
    }
}

bool AppSettings::notificationSoundsEnabled() const
{
    return settings.value(NOTIFICATION_SOUNDS_ENABLED, true).toBool();
}

void AppSettings::setNotificationSoundsEnabled(bool enable)
{
    if (notificationSoundsEnabled() != enable) {
        LOG(NOTIFICATION_SOUNDS_ENABLED << enable);
        settings.setValue(NOTIFICATION_SOUNDS_ENABLED, enable);
        emit notificationSoundsEnabledChanged();
    }
}

bool AppSettings::notificationSuppressContent() const
{
    return settings.value(NOTIFICATION_SUPPRESS_ENABLED, false).toBool();
}

void AppSettings::setNotificationSuppressContent(bool enable)
{
    if (notificationSuppressContent() != enable) {
        LOG(NOTIFICATION_SUPPRESS_ENABLED << enable);
        settings.setValue(NOTIFICATION_SUPPRESS_ENABLED, enable);
        emit notificationSuppressContentChanged();
    }
}

AppSettings::NotificationFeedback AppSettings::notificationFeedback() const
{
    return (NotificationFeedback) settings.value(NOTIFICATION_FEEDBACK, (int) NotificationFeedbackAll).toInt();
}

void AppSettings::setNotificationFeedback(NotificationFeedback feedback)
{
    if (notificationFeedback() != feedback) {
        LOG(NOTIFICATION_FEEDBACK << feedback);
        settings.setValue(NOTIFICATION_FEEDBACK, (int) feedback);
        emit notificationFeedbackChanged();
    }
}

bool AppSettings::notificationAlwaysShowPreview() const
{
    return settings.value(NOTIFICATION_ALWAYS_SHOW_PREVIEW, false).toBool();
}

void AppSettings::setNotificationAlwaysShowPreview(bool enable)
{
    if (notificationAlwaysShowPreview() != enable) {
        LOG(NOTIFICATION_ALWAYS_SHOW_PREVIEW << enable);
        settings.setValue(NOTIFICATION_ALWAYS_SHOW_PREVIEW, enable);
        emit notificationAlwaysShowPreviewChanged();
    }
}

bool AppSettings::goToQuotedMessage() const
{
    return settings.value(GO_TO_QUOTED_MESSAGE, false).toBool();
}

void AppSettings::setGoToQuotedMessage(bool enable)
{
    if (goToQuotedMessage() != enable) {
        LOG(GO_TO_QUOTED_MESSAGE << enable);
        settings.setValue(GO_TO_QUOTED_MESSAGE, enable);
        emit goToQuotedMessageChanged();
    }
}

bool AppSettings::storageOptimizer() const
{
    return settings.value(STORAGE_OPTIMIZER, true).toBool();
}

void AppSettings::setStorageOptimizer(bool enable)
{
    if (storageOptimizer() != enable) {
        LOG(STORAGE_OPTIMIZER << enable);
        settings.setValue(STORAGE_OPTIMIZER, enable);
        emit storageOptimizerChanged();
    }
}

bool AppSettings::allowInlineBotLocationAccess() const
{
    return settings.value(INLINEBOT_LOCATION_ACCESS, false).toBool();
}

void AppSettings::setAllowInlineBotLocationAccess(bool enable)
{

    if (allowInlineBotLocationAccess() != enable) {
        LOG(INLINEBOT_LOCATION_ACCESS << enable);
        settings.setValue(INLINEBOT_LOCATION_ACCESS, enable);
        emit allowInlineBotLocationAccessChanged();
    }
}

int AppSettings::remainingInteractionHints() const
{
    return settings.value(REMAINING_INTERACTION_HINTS, 3).toInt();
}

void AppSettings::setRemainingInteractionHints(int remainingHints)
{
    if (remainingInteractionHints() != remainingHints) {
        LOG(REMAINING_INTERACTION_HINTS << remainingHints);
        settings.setValue(REMAINING_INTERACTION_HINTS, remainingHints);
        emit remainingInteractionHintsChanged();
    }
}

int AppSettings::remainingDoubleTapHints() const
{
    return settings.value(REMAINING_DOUBLE_TAP_HINTS, 3).toInt();
}

void AppSettings::setRemainingDoubleTapHints(int remainingHints)
{
    if (remainingDoubleTapHints() != remainingHints) {
        LOG(REMAINING_DOUBLE_TAP_HINTS << remainingHints);
        settings.setValue(REMAINING_DOUBLE_TAP_HINTS, remainingHints);
        emit remainingDoubleTapHintsChanged();
    }
}

bool AppSettings::onlineOnlyMode() const
{
    return settings.value(ONLINE_ONLY_MODE, false).toBool();
}

void AppSettings::setOnlineOnlyMode(bool enable)
{
    if (onlineOnlyMode() != enable) {
        LOG(ONLINE_ONLY_MODE << enable);
        settings.setValue(ONLINE_ONLY_MODE, enable);
        emit onlineOnlyModeChanged();
    }
}

bool AppSettings::delayMessageRead() const
{
    return settings.value(DELAY_MESSAGE_READ, true).toBool();
}

void AppSettings::setDelayMessageRead(bool enable)
{
    if (delayMessageRead() != enable) {
        LOG(DELAY_MESSAGE_READ << enable);
        settings.setValue(DELAY_MESSAGE_READ, enable);
        emit delayMessageReadChanged();
    }
}

bool AppSettings::highlightUnreadConversations() const
{
    return settings.value(HIGHLIGHT_UNREADCONVS, false).toBool();
}

void AppSettings::setHighlightUnreadConversations(bool enable)
{
    if (highlightUnreadConversations() != enable) {
        LOG(HIGHLIGHT_UNREADCONVS << enable);
        settings.setValue(HIGHLIGHT_UNREADCONVS, enable);
        emit highlightUnreadConversationsChanged();
    }
}

bool AppSettings::getFocusTextAreaOnChatOpen() const
{
    return settings.value(FOCUS_TEXTAREA_ON_CHAT_OPEN, false).toBool();
}

void AppSettings::setFocusTextAreaOnChatOpen(bool focusTextAreaOnChatOpen)
{
    if (getFocusTextAreaOnChatOpen() != focusTextAreaOnChatOpen) {
        LOG(FOCUS_TEXTAREA_ON_CHAT_OPEN << focusTextAreaOnChatOpen);
        settings.setValue(FOCUS_TEXTAREA_ON_CHAT_OPEN, focusTextAreaOnChatOpen);
        emit focusTextAreaOnChatOpenChanged();
    }
}

AppSettings::SponsoredMess AppSettings::getSponsoredMess() const
{
    return (SponsoredMess) settings.value(SPONSORED_MESS, (int)
        AppSettings::SponsoredMessHandle).toInt();
}

void AppSettings::setSponsoredMess(SponsoredMess sponsoredMess)
{
    if (getSponsoredMess() != sponsoredMess) {
        LOG(SPONSORED_MESS << sponsoredMess);
        settings.setValue(SPONSORED_MESS, sponsoredMess);
        emit sponsoredMessChanged();
    }
}

bool AppSettings::sendAttachmentByEnter() const {
    return //getSendByEnter() &&
            settings.value(SEND_ATTACHMENT_BY_ENTER).toBool();
}
void AppSettings::setSendAttachmentByEnter(bool enable) {
    if (sendAttachmentByEnter() != enable) {
        LOG(SEND_ATTACHMENT_BY_ENTER << enable);
        settings.setValue(SEND_ATTACHMENT_BY_ENTER, enable);
        emit sendAttachmentByEnterChanged();
    }
}

qreal AppSettings::voiceNoteVolume() const {
    return settings.value(VOICE_NOTE_VOLUME, 1).toReal();
}
void AppSettings::setVoiceNoteVolume(qreal value) {
    if (voiceNoteVolume() != value) {
        LOG(VOICE_NOTE_VOLUME << value);
        settings.setValue(VOICE_NOTE_VOLUME, value);
        emit voiceNoteVolumeChanged();
    }
}

bool AppSettings::showTranslateOption() const {
    return settings.value(SHOW_TRANSLATE_OPTION).toBool();
}
void AppSettings::setShowTranslateOption(bool value) {
    if (showTranslateOption() != value) {
        LOG(SHOW_TRANSLATE_OPTION << value);
        settings.setValue(SHOW_TRANSLATE_OPTION, value);
        emit showTranslateOptionChanged();
    }
}

bool AppSettings::formattedTranslate() const {
    return settings.value(FORMATTED_TRANSLATE).toBool();
}
void AppSettings::setFormattedTranslate(bool value) {
    if (formattedTranslate() != value) {
        LOG(FORMATTED_TRANSLATE << value);
        settings.setValue(FORMATTED_TRANSLATE, value);
        emit formattedTranslateChanged();
    }
}

bool AppSettings::sendMarkdown() const {
    return settings.value(SEND_MARKDOWN, true).toBool();
}
void AppSettings::setSendMarkdown(bool value) {
    if (sendMarkdown() != value) {
        LOG(SEND_MARKDOWN << value);
        settings.setValue(SEND_MARKDOWN, value);
        emit sendMarkdownChanged();
    }
}

bool AppSettings::unreadCountIncludeMuted() const {
    return settings.value(UNREAD_COUNT_INCLUDE_MUTED).toBool();
}
void AppSettings::setUnreadCountIncludeMuted(bool value) {
    if (unreadCountIncludeMuted() != value) {
        LOG(UNREAD_COUNT_INCLUDE_MUTED << value);
        settings.setValue(UNREAD_COUNT_INCLUDE_MUTED, value);
        emit unreadCountIncludeMutedChanged();
    }
}

bool AppSettings::showFolderUnreadCount() const {
    return settings.value(SHOW_FOLDER_UNREAD_COUNT, true).toBool();
}
void AppSettings::setShowFolderUnreadCount(bool value) {
    if (showFolderUnreadCount() != value) {
        LOG(SHOW_FOLDER_UNREAD_COUNT << value);
        settings.setValue(SHOW_FOLDER_UNREAD_COUNT, value);
        emit showFolderUnreadCountChanged();
    }
}

bool AppSettings::foldersUnreadCountIncludeMuted() const {
    return settings.value(FOLDERS_UNREAD_COUNT_INCLUDE_MUTED, true).toBool();
}
void AppSettings::setFoldersUnreadCountIncludeMuted(bool value) {
    if (foldersUnreadCountIncludeMuted() != value) {
        LOG(FOLDERS_UNREAD_COUNT_INCLUDE_MUTED << value);
        settings.setValue(FOLDERS_UNREAD_COUNT_INCLUDE_MUTED, value);
        emit foldersUnreadCountIncludeMutedChanged();
    }
}

bool AppSettings::archiveChatListHintCompleted() const {
    return settings.value(ARCHIVE_CHAT_LIST_HINT_COMPLETED).toBool();
}
void AppSettings::setArchiveChatListHintCompleted(bool value) {
    if (archiveChatListHintCompleted() != value) {
        LOG(ARCHIVE_CHAT_LIST_HINT_COMPLETED << value);
        settings.setValue(ARCHIVE_CHAT_LIST_HINT_COMPLETED, value);
        emit archiveChatListHintCompletedChanged();
    }
}

bool AppSettings::chatFoldersTabsOnBottom() const {
    return settings.value(CHAT_FOLDERS_TABS_ON_BOTTOM).toBool();
}
void AppSettings::setChatFoldersTabsOnBottom(bool value) {
    if (chatFoldersTabsOnBottom() != value) {
        LOG(CHAT_FOLDERS_TABS_ON_BOTTOM << value);
        settings.setValue(CHAT_FOLDERS_TABS_ON_BOTTOM, value);
        emit chatFoldersTabsOnBottomChanged();
    }
}
