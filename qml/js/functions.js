//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

.pragma library
.import "debug.js" as Debug
.import "twemoji.js" as Emoji
.import Sailfish.Silica 1.0 as Silica
.import io.yaqtlib 1.0 as Logic

var tdLibWrapper, appNotification, utilities
function setGlobals(globals) {
    tdLibWrapper = globals.tdLibWrapper
    appNotification = globals.appNotification
    utilities = globals.utilities
}
function formatUnreadCount(value) {
    if(value < 1000) {
        return value;
    } else if(value > 9000) {
        return '9k+';
    }
    return ''+Math.floor(value / 1000)+'k'+((value % 1000)>0 ? '+' : '');
}

function getMessageText(message, simple, currentUserId, ignoreEntities, asFormattedText, emojiSize) {
    return utilities.getMessageText(message, simple ? Logic.Utilities.MessageTextSimple : Logic.Utilities.MessageTextDefault, ignoreEntities)
}

function getChatPartnerStatusText(statusType, wasOnline, isSupport, userId, asTimepoint) {
    if (isSupport) return userId == tdLibWrapper.options.telegram_service_notifications_chat_id
                   ? qsTr("service notifications", "used as a status for the service notifications chat")
                   : qsTr("support", "used as a status for support chats, excluding the service notifications chat")
    switch(statusType) {
    case "userStatusEmpty":
        return qsTr("was never online");
    case "userStatusLastMonth":
        return qsTr("last online: last month");
    case "userStatusLastWeek":
        return qsTr("last online: last week");
    case "userStatusOffline":
        return qsTr("last online: %1").arg(asTimepoint ? getDateTimeTimepoint(wasOnline) : getDateTimeElapsed(wasOnline));
    case "userStatusOnline":
        return qsTr("online");
    case "userStatusRecently":
        return qsTr("was recently online");
    }
}

function getSecretChatStatus(secretChatDetails) {
    switch (secretChatDetails.state["@type"]) {
    case "secretChatStateClosed":
        return "<b>" + qsTr("Closed!") + "</b>"
    case "secretChatStatePending":
        return qsTr("Pending acknowledgement")
    }
    return '' // secretChatStateReady
}

function getChatMemberStatusText(statusType) {
    switch(statusType) {
    case "chatMemberStatusAdministrator":
        return qsTr("Admin", "channel user role");
    case "chatMemberStatusBanned":
        return qsTr("Banned", "channel user role");
    case "chatMemberStatusCreator":
        return qsTr("Owner", "channel user role");
    case "chatMemberStatusRestricted":
        return qsTr("Restricted", "channel user role");
    case "chatMemberStatusLeft":
    case "chatMemberStatusMember":
        return ""
    }
    return statusType || "";
}

function getGroupStatusText(memberCount, isChannel, onlineCount, emptyIfNoMembers) {
    // FIXME: we've also used the following member count formatting techniques:
    // - .arg(Number(memberCount).toLocaleString(Qt.locale(), "f", 0))
    // - %Ln instead of %1
    // Now we only use this function, but is always using getShortenedCount really correct?
    if (onlineCount)
        return qsTr("%1, %2", "combination of '[x members], [y online]', which are separate translations")
            .arg(qsTr("%1 members", "", memberCount)
                .arg(getShortenedCount(memberCount)))
            .arg(qsTr("%1 online", "", onlineCount)
                .arg(getShortenedCount(onlineCount)))
    if (memberCount == 0)
        return emptyIfNoMembers ? '' : (isChannel ? qsTr("Channel") : qsTr("Group"))
    return (isChannel ? qsTr("%1 subscribers", "", memberCount) : qsTr("%1 members", "", memberCount))
        .arg(getShortenedCount(memberCount))
}

function getShortenedCount(count) {
    if (count >= 1000000)
        return qsTr("%1M").arg((count / 1000000).toLocaleString(Qt.locale(), 'f', 0))
    if (count >= 1000)
        return qsTr("%1K").arg((count / 1000).toLocaleString(Qt.locale(), 'f', 0))
    return count
}

function formatDate(timestamp, formatType) {
    return Silica.Format.formatDate(new Date(timestamp * 1000), formatType)
}

function getDateTimeElapsed(timestamp) {
    return formatDate(timestamp, Silica.Formatter.DurationElapsed)
}

function getDateTimeTranslated(timestamp) {
    return new Date(timestamp * 1000).toLocaleString()
}

function getDateTimeTimepoint(timestamp) {
    return formatDate(timestamp, Silica.Formatter.Timepoint)
}

function getDateTimeTimepointRelative(timestamp) {
    return formatDate(timestamp, Silica.Formatter.TimepointRelative)
}

function formatDurationToFuture(timestamp) {
    var diff = timestamp - new Date().getTime() / 1000
    if (diff <= 0)
        return ''
    return Silica.Format.formatDuration(diff)
}


function enhanceMessageText(formattedText, ignoreEntities, emojiSize, reloader) {
    if (typeof formattedText === 'undefined') return ''
    return utilities.enhanceMessageText(formattedText, ignoreEntities)
}

function getVideoHeight(videoWidth, videoData) {
    if (typeof videoData !== "undefined") {
        if (videoData.height === 0) {
            return videoWidth;
        } else {
            var aspectRatio = videoData.height / videoData.width;
            return Math.round(videoWidth * aspectRatio);
        }
    } else {
        return 1;
    }
}

function replaceUrlsWithLinks(string) {
    return string.replace(/((\w+):\/\/[\w?=&.\/-;#~%-]+(?![\w\s?&.\/;#~%"=-]*>))/g, "<a href=\"$1\">$1</a>");
}

function sortMessagesArrayByDate(messages) {
    messages.sort(function(a, b) {
      return a.date - b.date;
    });
}

function getMessagesArrayIds(messages) {
    sortMessagesArrayByDate(messages);
    return messages.map(function(message){return message.id.toString()});
}

function getMessagesArrayText(messages) {
    sortMessagesArrayByDate(messages);
    var lastSenderName = "";
    var lines = [];
    for(var i = 0; i < messages.length; i += 1) {
        var senderName = getUserName(tdLibWrapper.getUserInformation(messages[i].sender_id.user_id));
        if(senderName !== lastSenderName) {
            lines.push(senderName);
        }
        lastSenderName = senderName;
        lines.push(utilities.getMessageText(messages[i], Logic.Utilities.MessageTextSimple));
        lines.push("");
    }
    return lines.join("\n");
}

function handleErrorMessage(code, message, extra) {
    // if code is 406, next updateServiceNotification will replace this message; in case it will not be received this message will not be replaced and will be shown
    Debug.log("TDLib Error:", code, message, JSON.stringify(extra))
    if (code === 404 ||
            (code === 400 &&
             (message === "USERNAME_INVALID" || message === "USERNAME_NOT_OCCUPIED" || (extra === "getInstalledStickerSets" && message === "File not found")))) {
        // Silently ignore
        // - 404 Not Found messages (occur sometimes, without clear context...)
        // - searchPublicChat messages for "invalid" inline queries
        // - File not found errors when downloading sticker files
        if (extra && extra['@type'] === 'searchPublicChat' && extra.openDirectly)
            appNotification.show(qsTr("Unable to find user %1").arg(extra.type.substring(17)))
        return
    }
    switch (message) {
    case 'USER_ALREADY_PARTICIPANT':
        appNotification.show(qsTr("You are already a member of this chat."))
        break
    default:
        appNotification.show(message)
    }

    if (message === "USER_ALREADY_PARTICIPANT") {
        appNotification.show(qsTr("You are already a member of this chat."));
    } else {
        appNotification.show(message);
    }
}

function getMessagesNeededForwardPermissions(messages) {
    var neededPermissions = ["can_send_basic_messages"]

    var mediaMessageTypes = ["messageAudio", "messageDocument", "messagePhoto", "messageVideo", "messageVideoNote", "messageVoiceNote"]
    var otherMessageTypes = ["messageAnimation", "messageGame", "messageSticker"]
    for(var i = 0; i < messages.length && neededPermissions.length < 3; i += 1) {
        var type = messages[i]["content"]["@type"]
        var permission = ""
        if(type === "messageText") {
            continue
        } else if(type === "messagePoll") {
            permission = "can_send_polls"
        } else if(mediaMessageTypes.indexOf(type) > -1) {
            permission = "can_send_media_messages"
        } else if(otherMessageTypes.indexOf(type) > -1) {
            permission = "can_send_other_messages"
        }

        if(permission !== "" && neededPermissions.indexOf(permission) === -1) {
            neededPermissions.push(permission)
        }
    }
    return neededPermissions
}

function isWidescreen(appWindow) {
    return (appWindow.deviceOrientation & Silica.Orientation.LandscapeMask) || Silica.Screen.sizeCategory === Silica.Screen.Large || Silica.Screen.sizeCategory === Silica.Screen.ExtraLarge
}

function errorString(text) {
    return '<font color="' + Silica.Theme.errorColor + '">' + text + '</font>'
}

function getProxyPingDescription(ping) {
    switch (ping) {
    case -1:
        return ''
    case -2:
        return errorString(qsTr("Unavailable", "Indicates that the proxy is unavailable"))
    default:
        return ping ? qsTr("Available (ping: %Ln ms)", "Indicates that the proxy is available", Math.round(ping * 1000))
                    : qsTr("Available", "Indicates that the proxy is available")
    }
}

function getMuteButtonTitle(muted, settings, highlighted) {
    // TODO: save current time every time notification settings are received/updated for keeping the mute duration up to date
    return muted ? qsTr("Unmute") + (settings.use_default_mute_for || settings.mute_for > 31622400
                                     ? '' : ' <font color="'+(highlighted ? Silica.Theme.secondaryHighlightColor : Silica.Theme.secondaryColor) + '">' + Silica.Format.formatDuration(settings.mute_for) + '</font>')
                 : qsTr("Mute notifications")
}

function setChatIsMuted(chatId, notificationSettings, doMute) {
    // If chat is muted for more than 366 days, it's considered muted forever

    var newNotificationSettings = JSON.parse(JSON.stringify(notificationSettings))
    var scopeMuteFor = tdLibWrapper.getChatScopeNotificationSettings(chatId).mute_for

    if (doMute ? (scopeMuteFor > 31622400) : (scopeMuteFor === 0))
        newNotificationSettings.use_default_mute_for = true
    else {
        newNotificationSettings.use_default_mute_for = false
        newNotificationSettings.mute_for = doMute ? 31622401 : 0
    }

    tdLibWrapper.setChatNotificationSettings(chatId, newNotificationSettings)
}

function toggleChatIsMuted(chatId, notificationSettings) {
    setChatIsMuted(chatId, notificationSettings, !tdLibWrapper.chatIsMuted(chatId, notificationSettings))
}

function formatMessageSendingState(messageId, lastReadOutboxMessageId, sendingState, fontSize) {
    var emoji
    if (lastReadOutboxMessageId >= messageId)
        emoji = "✅" // Read by other party
    // Not yet read by other party
    else if (sendingState) {
        if (sendingState['@type'] === "messageSendingStatePending")
            emoji = "🕙"
        else
            emoji = "❌" // Sending failed
    } else
        emoji = "☑️"

    return "&nbsp;&nbsp;" + Emoji.emojify(emoji, fontSize)
}

function getMessageSendingStateIcon(messageId, lastReadOutboxMessageId, sendingState) {
    if (lastReadOutboxMessageId >= messageId)
        return Qt.resolvedUrl('../../images/icon-s-message-read.svg')
    else if (sendingState) {
        if (sendingState['@type'] === "messageSendingStatePending")
            return 'image://theme/icon-s-time'
        else // Sending failed
            return 'image://theme/icon-s-filled-warning'
    } else
        return Qt.resolvedUrl('../../images/icon-s-message-sent.svg')
}

function getVideoFile(video) {
    // Returns the file for video, animation or videoNote TDLib object
    return videoData['@type'] === 'videoNote' ? video.video : video[video['@type']]
}
