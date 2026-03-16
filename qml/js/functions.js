/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

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

.pragma library
.import "debug.js" as Debug
.import "twemoji.js" as Emoji
.import Sailfish.Silica 1.0 as Silica
.import App.Logic 1.0 as Logic

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

function getUserName(userInformation) {
    return ((userInformation.first_name || "") + " " + (userInformation.last_name || "")).trim();
}

function getMessageText(message, simple, currentUserId, ignoreEntities, asFormattedText, emojiSize) {
    return utilities.getMessageText(message, simple ? Logic.Utilities.MessageTextSimple : Logic.Utilities.MessageTextDefault, ignoreEntities)
}

function getChatPartnerStatusText(statusType, was_online, isSupport, userId, asTimepoint) {
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
        return qsTr("last online: %1").arg(asTimepoint ? getDateTimeTimepoint(was_online) : getDateTimeElapsed(was_online));
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

function getChatActionText(action, privateOrSecretChat, single) {
    switch (action) {
    case "chatActionTyping":
        return privateOrSecretChat ? qsTr("typing") : (single ? qsTr("%1 is typing") : qsTr("%1 are typing"))
    case "chatActionChoosingContact":
        return privateOrSecretChat ? qsTr("choosing a contact") : (single ? qsTr("%1 is choosing a contact") : qsTr("%1 are choosing a contact"))
    case "chatActionChoosingLocation":
        return privateOrSecretChat ? qsTr("choosing a location") : (single ? qsTr("%1 is choosing a location") : qsTr("%1 are choosing a location"))
    case "chatActionChoosingSticker":
        return privateOrSecretChat ? qsTr("choosing a sticker") : (single ? qsTr("%1 is choosing a sticker") : qsTr("%1 are choosing a sticker"))
    case "chatActionRecordingVideo":
        return privateOrSecretChat ? qsTr("recording a video") : (single ? qsTr("%1 is recording a video") : qsTr("%1 are recording a video"))
    case "chatActionRecordingVideoNote":
        return privateOrSecretChat ? qsTr("recording a video message") : (single ? qsTr("%1 is recording a video message") : qsTr("%1 are recording a video message"))
    case "chatActionRecordingVoiceNote":
        return privateOrSecretChat ? qsTr("recording a voice message") : (single ? qsTr("%1 is recording a voice message") : qsTr("%1 are recording a voice message"))
    case "chatActionStartPlayingGame":
        return privateOrSecretChat ? qsTr("playing a game") : (single ? qsTr("%1 is playing a game") : qsTr("%1 are playing a game"))
    case "chatActionUploadingDocument":
        return privateOrSecretChat ? qsTr("sending a file") : (single ? qsTr("%1 is sending a file") : qsTr("%1 are sending a file"))
    case "chatActionUploadingPhoto":
        return privateOrSecretChat ? qsTr("sending a photo") : (single ? qsTr("%1 is sending a photo") : qsTr("%1 are sending a photo"))
    case "chatActionUploadingVideo":
        return privateOrSecretChat ? qsTr("sending a video") : (single ? qsTr("%1 is sending a video") : qsTr("%1 are is sending a video"))
    case "chatActionUploadingVideoNote":
        return privateOrSecretChat ? qsTr("sending a video message") : (single ? qsTr("%1 is sending a video message") : qsTr("%1 are sending a video message"))
    case "chatActionUploadingVoiceNote":
        return privateOrSecretChat ? qsTr("sending a voice message") : (single ? qsTr("%1 is sending a voice message") : qsTr("%1 are sending a voice message"))
    //case "chatActionWatchingAnimations":
    //    return single ? qsTr("%1 is watching animations") : qsTr("%1 are watching animations")
    }
    return ''
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

function getChatActionsObject(chatActionsByChats, chatActionsByUsers) {
    var result = {}
    for (var chatId in chatActionsByChats) {
        if (!(chatActionsByChats[chatId] in result))
            result[chatActionsByChats[chatId]] = []
        result[chatActionsByChats[chatId]].push(tdLibWrapper.getChat(chatId).title);
    }
    for (var userId in chatActionsByUsers) {
        if (!(chatActionsByUsers[userId] in result))
            result[chatActionsByUsers[userId]] = []
        result[chatActionsByUsers[userId]].push(getUserName(tdLibWrapper.getUserInformation(userId)))
    }

    return result
}

function getChatActionsText(chatActionsByChats, chatActionsByUsers, privateOrSecretChat) {
    var result = ''
    var actions = getChatActionsObject(chatActionsByChats, chatActionsByUsers)
    for (var action in actions) {
        var senders = ''
        for (var i=0; i < actions[action].length; i++)
            senders += actions[action][i] + ', '
        senders = senders.slice(0, -2)
        var text = getChatActionText(action, privateOrSecretChat, actions[action].length <= 1)
        if (text) result += text.arg(senders)
    }

    return result
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

function getDurationToFuture(timestamp) {
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
        lines.push(getMessageText(messages[i], true, tdLibWrapper.getUserInformation().id, false));
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
    case 'INVITE_REQUEST_SENT':
        appNotification.show(extra.isChannel ? qsTr("Request to join sent", "channel") : qsTr("Request to join sent", "group"))
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
