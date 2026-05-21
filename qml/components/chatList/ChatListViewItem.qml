import QtQuick 2.6
import Sailfish.Silica 1.0
import io.libfernie 1.0

import ".."
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

PhotoTextsListItem {
    id: listItem
    pictureThumbnail {
        photoData: photo_data.small || ({})
        minithumbnail: photo_data.minithumbnail
        highlighted: listItem.highlighted && !listItem.menuOpen
    }
    property bool showDraft: !!draft_message_text && draft_message_date > last_message_date
    property string previewText: chat_actions_text || (showDraft ? draft_message_text : last_message_text)
    property int chatListType: ChatFoldersModel.FolderMain
    property int folderId

    // chat title
    primaryText.text: title ? Emoji.emojify(utilities.fixReservedHtmlCharacters(title), Theme.fontSizeMedium) : qsTr("Unknown")
    // last user
    prologSecondaryText.text: chat_actions_text ? '' : showDraft ? "<i>"+qsTr("Draft")+"</i>" : (is_channel || ((chat_type == TDLibAPI.ChatTypePrivate || chat_type == TDLibAPI.ChatTypeSecret) && !last_message_is_service) ? "" : ( last_message_sender_id ? ( last_message_sender_id !== tdLibWrapper.myUserId ? Emoji.emojify(utilities.getUserName(tdLibWrapper.getUserInformation(last_message_sender_id)), Theme.fontSizeExtraSmall) : qsTr("You") ) : "" ))
    // last message
    secondaryText.text: previewText ? Emoji.emojify(utilities.fixReservedHtmlCharacters(previewText), Theme.fontSizeExtraSmall) : "<i>" + qsTr("No message in this chat.") + "</i>"
    secondaryText.highlighted: listItem.highlighted || !!chat_actions_text
    minithumbnail: showDraft || chat_actions_text ? null : last_message_minithumbnail
    chatActionIcon {
        type: chat_main_action_type
        actionProgress: chat_actions_progress
    }
    // message date
    Binding {
        target: appSettings.compactChatList ? additionalPrimaryText : tertiaryText
        property: 'text'
        value: {
            var dateFormatter = appSettings.compactChatList ? Functions.getDateTimeTimepointRelative : Functions.getDateTimeElapsed

            if (showDraft)
                return dateFormatter(draft_message_date)
            if (!last_message_date)
                return ''

            var date = dateFormatter(last_message_date)
            var status = Emoji.emojify(last_message_status, tertiaryText.font.pixelSize)
            return appSettings.compactChatList ? status + date : date + status
        }
    }
    Binding {
        target: appSettings.compactChatList ? tertiaryText : additionalPrimaryText
        property: 'text'
        value: ''
    }

    unreadCount: unread_count
    unreadReactionCount: unread_reaction_count
    unreadMentionCount: unread_mention_count
    isSecret: chat_type === TDLibAPI.ChatTypeSecret
    isMarkedAsUnread: is_marked_as_unread
    isPinned: is_pinned
    muted: tdLibWrapper.chatIsMuted(chat_id, notification_settings) //notification_settings.mute_for > 0
    verificationStatus: verification_status

    showSeparator: !appSettings.compactChatList
    contentHeight: appSettings.compactChatList ? Theme.itemSizeLarge : Theme.itemSizeExtraLarge
    pictureThumbnailItem.height: appSettings.compactChatList ? Theme.itemSizeMedium : Theme.itemSizeLarge

    onPressAndHold:
        if (menu && menu.isMain)
            openMenu()
        else {
            contextMenuLoader.sourceComponent = defaultContextMenu
            contextMenuLoader.active = true
        }

    Loader {
        id: contextMenuLoader
        active: false
        asynchronous: true
        onStatusChanged:
            if (status === Loader.Ready) {
                listItem.menu = item
                listItem.openMenu()
            }
        sourceComponent: defaultContextMenu

        Component {
            id: defaultContextMenu
            ContextMenu {
                readonly property bool isMain: true

                property bool canArchive: true
                Connections {
                    target: tdLibWrapper
                    onChatListsReceived: if (chatId == chat_id) {
                                             for (var i=0; i < chatLists.length; i++) {
                                                 switch (chatLists[i]['@type']) {
                                                 case 'chatListArchive':
                                                     canArchive = true
                                                     toggleArchiveMenuItem.visible = true
                                                     return // for now, don't check anything else
                                                 case 'chatListMain':
                                                     canArchive = false
                                                     toggleArchiveMenuItem.visible = true
                                                     return
                                                 }
                                             }
                                         }
                }
                onActiveChanged: if (active) tdLibWrapper.getChatListsToAddChat(chat_id)
                onClosed: toggleArchiveMenuItem.visible = false

                MenuItem {
                    visible: unread_count > 0 || unread_reaction_count > 0 || unread_mention_count > 0
                    onClicked: {
                        tdLibWrapper.viewMessage(chat_id, display.last_message.id, true)
                        tdLibWrapper.readAllChatMentions(chat_id)
                        tdLibWrapper.readAllChatReactions(chat_id)
                        tdLibWrapper.readAllChatPollVotes(chat_id)
                        tdLibWrapper.toggleChatIsMarkedAsUnread(chat_id, false)
                    }
                    text: qsTr("Mark all messages as read")
                }

                MenuItem {
                    visible: unread_count === 0 && unread_reaction_count === 0 && unread_mention_count === 0
                    onClicked: {
                        tdLibWrapper.toggleChatIsMarkedAsUnread(chat_id, !is_marked_as_unread);
                    }
                    text: is_marked_as_unread ? qsTr("Mark chat as read") : qsTr("Mark chat as unread")
                }

                MenuItem {
                    text: is_pinned ? qsTr("Unpin chat") : qsTr("Pin chat")
                    onClicked:
                        if (chatListType == ChatFoldersModel.FolderFolder)
                            tdLibWrapper.toggleChatIsPinnedForFolder(chat_id, !is_pinned, folderId)
                        else
                            tdLibWrapper.toggleChatIsPinned(chat_id, !is_pinned, chatListType == ChatFoldersModel.FolderArchive)
                }

                MenuItem {
                    id: toggleArchiveMenuItem
                    visible: false
                    onClicked: tdLibWrapper.addChatToList(chat_id, canArchive)
                    text: canArchive ? qsTr("Archive") : qsTr("Unarchive")
                }

                MenuItem {
                    visible: chat_id != tdLibWrapper.myUserId
                    onClicked:
                        if (tdLibWrapper.chatIsMuted(chat_id, notification_settings))
                            Functions.setChatIsMuted(chat_id, notification_settings, false)
                        else
                            contextMenuLoader.sourceComponent = notificationsContextMenuComponent
                    text: Functions.getMuteButtonTitle(tdLibWrapper.chatIsMuted(chat_id, notification_settings), notification_settings, highlighted)
                }

                MenuItem {
                    onClicked: {
                        if(pageStack.depth > 2) {
                            pageStack.pop(pageStack.find( function(page){ return(page._depth === 0)} ), PageStackAction.Immediate);
                        }

                        pageStack.push(Qt.resolvedUrl("../../pages/ChatInformationPage.qml"), { "chatInformation" : display});
                    }
                    text: model.display.type['@type'] === "chatTypePrivate" ? qsTr("User Info") : qsTr("Group Info")
                }
            }
        }

        Component {
            id: notificationsContextMenuComponent
            ChatNotificationsContextMenu {
                chatId: chat_id
                notificationSettings: notification_settings
            }
        }
    }

}
