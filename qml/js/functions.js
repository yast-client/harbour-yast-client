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
.import WerkWolf.Fernschreiber 1.0 as Fernschreiber

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
    return utilities.getMessageText(message, simple, ignoreEntities)
}

function getChatPartnerStatusText(statusType, was_online, asTimepoint) {
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
        return "<b>" + qsTr("Closed!") + "</b>";
    case "secretChatStatePending":
        return qsTr("Pending acknowledgement");
    case "secretChatStateReady":
        return "";
    }
}

function getChatMemberStatusText(statusType) {
    switch(statusType) {
    case "chatMemberStatusAdministrator":
        return qsTr("Admin", "channel user role");
    case "chatMemberStatusBanned":
        return qsTr("Banned", "channel user role");
    case "chatMemberStatusCreator":
        return qsTr("Creator", "channel user role");
    case "chatMemberStatusRestricted":
        return qsTr("Restricted", "channel user role");
    case "chatMemberStatusLeft":
    case "chatMemberStatusMember":
        return ""
    }
    return statusType || "";
}

function getShortenedCount(count) {
    if (count >= 1000000) {
        return qsTr("%1M").arg((count / 1000000).toLocaleString(Qt.locale(), 'f', 0));
    } else if (count >= 1000 ) {
        return qsTr("%1K").arg((count / 1000).toLocaleString(Qt.locale(), 'f', 0));
    } else {
        return count;
    }
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

function handleHtmlEntity(messageText, messageInsertions, originalString, replacementString) {
    var nextIndex = -1;
    while ((nextIndex = messageText.indexOf(originalString, nextIndex + 1)) > -1) {
        messageInsertions.push({ offset: nextIndex, insertionString: replacementString, removeLength: originalString.length });
    }
}

var rawNewLineRegExp = /\r?\n/g;
var ampRegExp = /&/g;
var ltRegExp = /</g;
var gtRegExp = />/g;


function messageInsertionSorter(a, b) {
    if ((b.offset + b.removeLength) > (a.offset + a.removeLength)) {
        return 1;
    }
    if ((b.offset + b.removeLength) < (a.offset + a.removeLength)) {
        return -1;
    }
    return b.offset - a.offset;
}

function enhanceMessageText(formattedText, ignoreEntities, emojiSize, reloader) {
    if (typeof formattedText === 'undefined') return ''
    return utilities.enhanceMessageText(formattedText, ignoreEntities)
}

function handleTMeLink(link, usedPrefix) {
    if (link.indexOf("joinchat") !== -1) {
        Debug.log("Joining Chat: ", link);
        tdLibWrapper.joinChatByInviteLink(link);
        // Do the necessary stuff to open the chat if successful
        // Fail with nice error message if it doesn't work
    } else if (link.indexOf("/+") !== -1) {
        // Can't handle t.me/+... links directly, try to parse the Telegram page...
        tdLibWrapper.getPageSource(link);
    } else {
        Debug.log("Search public chat: ", link.substring(usedPrefix.length));
        tdLibWrapper.searchPublicChat(link.substring(usedPrefix.length), true);
        // Check responses for updateBasicGroup or updateSupergroup
        // Fire createBasicGroupChat or createSupergroupChat
        // Do the necessary stuff to open the chat
        // Fail with nice error message if chat can't be found
    }
}

function isDirectMessageLink(link) {
    var tMePrefix = tdLibWrapper.getOptionString("t_me_url");
    var tMePrefixHttp = tMePrefix.replace('https', 'http');

    return (link.indexOf(tMePrefix) === 0 && link.substring(tMePrefix.length).indexOf("/") > 0) ||
           (link.indexOf(tMePrefixHttp) === 0 && link.substring(tMePrefixHttp.length).indexOf("/") > 0) ||
           link.indexOf("tg://privatepost") === 0 ||
           (link.indexOf("tg://resolve") === 0 && link.indexOf("post") > 0)
}

function handleLink(link) {
    var tMePrefix = tdLibWrapper.getOptionString("t_me_url");
    var tMePrefixHttp = tMePrefix.replace('https', 'http');

    // Checking if we have a direct message link...
    Debug.log("URL open requested: " + link);
    if (isDirectMessageLink(link)) {
        Debug.log("Using message link info for: " + link);
        tdLibWrapper.getMessageLinkInfo(link, "openDirectly");
        return;
    }

    Debug.log("Trying to parse link ourselves: " + link);
    if (link.indexOf("user://") === 0) {
        var userName = link.substring(8)
        var userInformation = tdLibWrapper.getUserInformationByName(userName)
        if (typeof userInformation.id !== "undefined")
            tdLibWrapper.createPrivateChat(userInformation.id, 'openDirectly')
        else {
            userInformation = tdLibWrapper.getSupergroupInformationByName(userName)
            if (typeof userInformation.id !== "undefined")
                tdLibWrapper.createSupergroupChat(userInformation.id, 'openDirectly')
            else tdLibWrapper.searchPublicChat(userName, true)
        }
    } else if (link.indexOf("userId://") === 0) {
        tdLibWrapper.createPrivateChat(link.substring(9), "openDirectly");
    } else if (link.indexOf("tg://") === 0) {
        Debug.log("Special TG link: ", link);
        if (link.indexOf("tg://join?invite=") === 0) {
            tdLibWrapper.joinChatByInviteLink(tMePrefix + "joinchat/" + link.substring(17));
        } else if (link.indexOf("tg://resolve?domain=") === 0) {
            tdLibWrapper.searchPublicChat(link.substring(20), true);
        }
    } else if (link.indexOf("botCommand://") === 0) { // this gets returned to send on ChatPage
        return link.substring(13);
    } else {
        if (link.indexOf(tMePrefix) === 0) {
            handleTMeLink(link, tMePrefix);
        } else if (link.indexOf(tMePrefixHttp) === 0) {
            handleTMeLink(link, tMePrefixHttp);
        } else {
            Debug.log("Trying to open URL externally: " + link)
            if (link.indexOf("://") === -1) {
                Qt.openUrlExternally("https://" + link)
            } else {
                Qt.openUrlExternally(link);
            }
        }
    }
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

// See doc/development.md
var ALL_ERRORS = {
    // TODO
}

function handleErrorMessage(code, message, extra) {
    //if (code === 406) return // handle using updateServiceNotification instead (for now both are used for testing)
    if (code === 404 ||
            (code === 400 &&
             (message === "USERNAME_INVALID" || message === "USERNAME_NOT_OCCUPIED"))) {
        // Silently ignore
        // - 404 Not Found messages (occur sometimes, without clear context...)
        // - searchPublicChat messages for "invalid" inline queries
        if (extra && extra['@type'] === 'searchPublicChat' && extra.doOpenOnFound)
            appNotification.show(qsTr("Unable to find user %1").arg(extra.type.substring(17)))
        return
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
