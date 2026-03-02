import QtQuick 2.0
import '..'

ChatInformationTabItemChatsBase {
    loadingText: isChannel ? qsTr("Loading subscribers", "channel") : qsTr("Loading members", "group")
    placeholderText: isChannel
                        ? (canGetMembers ? qsTr("This channel is empty") : qsTr("Channel members are anonymous"))
                        : qsTr("This group is empty")
    model: membersList
    delegate: TDLibChatListItem {
        chatId: model.member_id['@type'] === 'messageSenderChat' ? model.member_id.chat_id : null
        userId: model.member_id['@type'] === 'messageSenderUser' ? model.member_id.user_id : chatInformation.type.user_id
    }

    onLoadMore:
        if (groupInformation.member_count > view.count)
            tdLibWrapper.getSupergroupMembers(chatUserOrGroupId, initial ? 50 : 200, membersList.count)

    Connections {
        target: tdLibWrapper
        onChatMembersReceived:
            if (chatId === chatUserOrGroupId) {
                handleGroupMembers(members, false)
                loadedTimer.start()
            }
    }
}
