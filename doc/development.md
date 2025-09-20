# Development notes

## Code Styling

In Fernschreiber, the code styling is very mixed. In Ferniegram, it can be mixed too. If it will not be abandoned by me, I will probably try to fix it later anyways.

## Some notes

- ~~setMessageProperties could probably be implemented better. Currently it is hardcoded in several places, including new message success callback. It is also not same as other set* chat list functions, others simply scrap data from the message, but this one sends a tdlib request. Not sure if this should also be added to handleMessageContentUpdated, handleMessageEditedUpdated or anything similar. Probably not, but who knows~~ Nevermind, messageProperties should only be received when opening a menu. That's what we do now

## Chat list handling

When a chat is discovered, these updates are sent:
1. updateNewChat
    `chat_lists` and `positions` fields seem to be empty, but we should still check them
2. updateChatAddedToList with chatListMain as chat_list
3. updateChatLastMessage, `positions` still seem to be empty in this case
4. updateChatPosition, with `position` for chatListMain


Received update {'@type': 'updateChatPosition', 'chat_id': -4854766042, 'position': {'@type': 'chatPosition', 'list': {'@type': 'chatListMain'}, 'order': '7544763113791361032', 'is_pinned': False}}

When a chat is removed (in this case, left the group and deleted it), these updates are sent:
1. updateChatLastMessage with `messageChatDeleteMember`, `positions` field isn't empty and is changed
2. updateChatReadOutbox
3. updateChatLastMessage with null message, `positions` field changed
4. updateChatReadInbox
5. updateChatRemovedFromList
6. updateChatPosition with 0 position in chatListMain. **It doesn't seem to be needed to handle this since updateChatRemovedFromList already handles this.** *While handling this will make everything more accurate, it might affect performance too.*
7. updateChatPermissions with all permissions set to false

## Error handling

Links:
- [error tdlib object documentation](https://core.telegram.org/tdlib/docs/classtd_1_1td__api_1_1error.html)
- [errors documentation in telegram API](https://core.telegram.org/api/errors) (contains a database of all errors and some more info)

406 errors are handled using [updateServiceNotification](https://core.telegram.org/tdlib/docs/classtd_1_1td__api_1_1update_service_notification.html). `error` objects with them should be ignored.
This update's [TL API analog](https://core.telegram.org/constructor/updateServiceNotification) also has a boolean property `popup`. It is not yet checked if this is handled automatically by tdlib somehow.

Some other links with error databases (but, official page is better and always up-to-date):
- https://github.com/KurimuzonAkuma/pyrogram/tree/4c367aaec5b4aa9d055d1334da117487ef9fabfa/compiler/errors/source
- https://github.com/xelaj/mtproto/blob/main/errors.go