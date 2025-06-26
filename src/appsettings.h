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

#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool sendByEnter READ getSendByEnter WRITE setSendByEnter NOTIFY sendByEnterChanged)
    Q_PROPERTY(bool focusTextAreaAfterSend READ getFocusTextAreaAfterSend WRITE setFocusTextAreaAfterSend NOTIFY focusTextAreaAfterSendChanged)
    Q_PROPERTY(bool useOpenWith READ getUseOpenWith WRITE setUseOpenWith NOTIFY useOpenWithChanged)
    Q_PROPERTY(bool showStickersAsEmojis READ showStickersAsEmojis WRITE setShowStickersAsEmojis NOTIFY showStickersAsEmojisChanged)
    Q_PROPERTY(bool showStickersAsImages READ showStickersAsImages WRITE setShowStickersAsImages NOTIFY showStickersAsImagesChanged)
    Q_PROPERTY(bool animateStickers READ animateStickers WRITE setAnimateStickers NOTIFY animateStickersChanged)
    Q_PROPERTY(bool notificationTurnsDisplayOn READ notificationTurnsDisplayOn WRITE setNotificationTurnsDisplayOn NOTIFY notificationTurnsDisplayOnChanged)
    Q_PROPERTY(bool notificationSoundsEnabled READ notificationSoundsEnabled WRITE setNotificationSoundsEnabled NOTIFY notificationSoundsEnabledChanged)
    Q_PROPERTY(bool notificationSuppressContent READ notificationSuppressContent WRITE setNotificationSuppressContent NOTIFY notificationSuppressContentChanged)
    Q_PROPERTY(NotificationFeedback notificationFeedback READ notificationFeedback WRITE setNotificationFeedback NOTIFY notificationFeedbackChanged)
    Q_PROPERTY(bool notificationAlwaysShowPreview READ notificationAlwaysShowPreview WRITE setNotificationAlwaysShowPreview NOTIFY notificationAlwaysShowPreviewChanged)
    Q_PROPERTY(bool goToQuotedMessage READ goToQuotedMessage WRITE setGoToQuotedMessage NOTIFY goToQuotedMessageChanged)
    Q_PROPERTY(bool storageOptimizer READ storageOptimizer WRITE setStorageOptimizer NOTIFY storageOptimizerChanged)
    Q_PROPERTY(bool allowInlineBotLocationAccess READ allowInlineBotLocationAccess WRITE setAllowInlineBotLocationAccess NOTIFY allowInlineBotLocationAccessChanged)
    Q_PROPERTY(int remainingInteractionHints READ remainingInteractionHints WRITE setRemainingInteractionHints NOTIFY remainingInteractionHintsChanged) // "Tap on the title bar to filter your chats"
    Q_PROPERTY(int remainingDoubleTapHints READ remainingDoubleTapHints WRITE setRemainingDoubleTapHints NOTIFY remainingDoubleTapHintsChanged) // "Double-tap on a message to choose a reaction" (currently disabled)
    Q_PROPERTY(bool onlineOnlyMode READ onlineOnlyMode WRITE setOnlineOnlyMode NOTIFY onlineOnlyModeChanged)
    Q_PROPERTY(bool delayMessageRead READ delayMessageRead WRITE setDelayMessageRead NOTIFY delayMessageReadChanged)
    Q_PROPERTY(bool focusTextAreaOnChatOpen READ getFocusTextAreaOnChatOpen WRITE setFocusTextAreaOnChatOpen NOTIFY focusTextAreaOnChatOpenChanged)
    Q_PROPERTY(SponsoredMess sponsoredMess READ getSponsoredMess WRITE setSponsoredMess NOTIFY sponsoredMessChanged)
    Q_PROPERTY(bool highlightUnreadConversations READ highlightUnreadConversations WRITE setHighlightUnreadConversations NOTIFY highlightUnreadConversationsChanged)
    Q_PROPERTY(bool sendAttachmentByEnter READ sendAttachmentByEnter WRITE setSendAttachmentByEnter NOTIFY sendAttachmentByEnterChanged)
    Q_PROPERTY(bool superCompactMessageMenu READ superCompactMessageMenu WRITE setSuperCompactMessageMenu NOTIFY superCompactMessageMenuChanged)
    Q_PROPERTY(qreal voiceNoteVolume READ voiceNoteVolume WRITE setVoiceNoteVolume NOTIFY voiceNoteVolumeChanged)
    Q_PROPERTY(bool showTranslateOption READ showTranslateOption WRITE setShowTranslateOption NOTIFY showTranslateOptionChanged)
    Q_PROPERTY(bool formattedTranslate READ formattedTranslate WRITE setFormattedTranslate NOTIFY formattedTranslateChanged)
    Q_PROPERTY(bool videoStickers READ videoStickers WRITE setVideoStickers NOTIFY videoStickersChanged)
public:
    enum SponsoredMess {
        SponsoredMessHandle,
        SponsoredMessAutoView,
        SponsoredMessIgnore
    };
    Q_ENUM(SponsoredMess)

    enum NotificationFeedback {
        NotificationFeedbackNone,
        NotificationFeedbackNew,
        NotificationFeedbackAll
    };
    Q_ENUM(NotificationFeedback)

public:
    AppSettings(QObject *parent = Q_NULLPTR);

    bool getSendByEnter() const;
    void setSendByEnter(bool sendByEnter);

    bool getFocusTextAreaAfterSend() const;
    void setFocusTextAreaAfterSend(bool focusTextAreaAfterSend);

    bool getUseOpenWith() const;
    void setUseOpenWith(bool useOpenWith);

    bool showStickersAsEmojis() const;
    void setShowStickersAsEmojis(bool showAsEmojis);

    bool showStickersAsImages() const;
    void setShowStickersAsImages(bool showAsImages);

    bool animateStickers() const;
    void setAnimateStickers(bool animate);

    bool notificationTurnsDisplayOn() const;
    void setNotificationTurnsDisplayOn(bool turnOn);

    bool notificationSoundsEnabled() const;
    void setNotificationSoundsEnabled(bool enable);

    bool notificationSuppressContent() const;
    void setNotificationSuppressContent(bool enable);

    NotificationFeedback notificationFeedback() const;
    void setNotificationFeedback(NotificationFeedback feedback);

    bool notificationAlwaysShowPreview() const;
    void setNotificationAlwaysShowPreview(bool enable);

    bool goToQuotedMessage() const;
    void setGoToQuotedMessage(bool enable);

    bool storageOptimizer() const;
    void setStorageOptimizer(bool enable);

    bool allowInlineBotLocationAccess() const;
    void setAllowInlineBotLocationAccess(bool enable);

    int remainingInteractionHints() const;
    void setRemainingInteractionHints(int remainingHints);

    int remainingDoubleTapHints() const;
    void setRemainingDoubleTapHints(int remainingHints);

    bool onlineOnlyMode() const;
    void setOnlineOnlyMode(bool enable);

    bool delayMessageRead() const;
    void setDelayMessageRead(bool enable);

    bool getFocusTextAreaOnChatOpen() const;
    void setFocusTextAreaOnChatOpen(bool focusTextAreaOnChatOpen);

    SponsoredMess getSponsoredMess() const;
    void setSponsoredMess(SponsoredMess sponsoredMess);

    bool highlightUnreadConversations() const;
    void setHighlightUnreadConversations(bool enable);

    bool sendAttachmentByEnter() const;
    void setSendAttachmentByEnter(bool enable);

    bool superCompactMessageMenu() const;
    void setSuperCompactMessageMenu(bool enable);

    qreal voiceNoteVolume() const;
    void setVoiceNoteVolume(qreal value);

    bool showTranslateOption() const;
    void setShowTranslateOption(bool value);

    bool formattedTranslate() const;
    void setFormattedTranslate(bool value);

    bool videoStickers() const;
    void setVideoStickers(bool value);

signals:
    void sendByEnterChanged();
    void focusTextAreaAfterSendChanged();
    void useOpenWithChanged();
    void showStickersAsEmojisChanged();
    void showStickersAsImagesChanged();
    void animateStickersChanged();
    void notificationTurnsDisplayOnChanged();
    void notificationSoundsEnabledChanged();
    void notificationSuppressContentChanged();
    void notificationFeedbackChanged();
    void notificationAlwaysShowPreviewChanged();
    void goToQuotedMessageChanged();
    void storageOptimizerChanged();
    void allowInlineBotLocationAccessChanged();
    void remainingInteractionHintsChanged();
    void remainingDoubleTapHintsChanged();
    void onlineOnlyModeChanged();
    void delayMessageReadChanged();
    void focusTextAreaOnChatOpenChanged();
    void sponsoredMessChanged();
    void highlightUnreadConversationsChanged();
    void sendAttachmentByEnterChanged();
    void superCompactMessageMenuChanged();
    void voiceNoteVolumeChanged();
    void showTranslateOptionChanged();
    void videoStickersChanged();
    void formattedTranslateChanged();

private:
    QSettings settings;
};

#endif // APPSETTINGS_H
