import QtQuick 2.0
import '..'
import '../tdlib'

ChatInformationTabItemChatsBase {
    loading: false // initial request is already sent from the tab view
    loadInitial: false
    fullyLoaded: groupsInCommonList.totalCount <= view.count
    loadingText: qsTr("Loading groups in common", "groups you have in common with a user")
    placeholderText: qsTr("No groups in common")
    model: groupsInCommonList
    delegate: TDLibChatListItem {
        chatId: model.chatId
        prologSecondaryText.text: ''
    }

    onLoadMore:
        tdLibWrapper.getGroupsInCommon(chatUserOrGroupId, 200, groupsInCommonList.get(groupsInCommonList.count - 1).chatId)

    Connections {
        target: tdLibWrapper
        onChatsReceived:
            if (extra == "getGroupsInCommon:"+chatUserOrGroupId) {
                handleGroupsInCommon(chatIds, totalCount)
                loading = false
            }
    }
}
