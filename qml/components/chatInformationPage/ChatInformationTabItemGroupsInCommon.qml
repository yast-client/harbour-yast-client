import QtQuick 2.0
import '..'

ChatInformationTabItemChatsBase {
    loading: false // initial request is already sent from the tab view
    loadingText: qsTr("Loading groups in common", "groups you have in common with a user")
    placeholderText: qsTr("No groups in common")
    model: groupsInCommonList
    delegate: TDLibChatListItem {
        chatId: model.chatId
    }

    loadInitial: false
    onLoadMore:
        if (groupsInCommonList.totalCount > view.count)
            tdLibWrapper.getGroupsInCommon(chatUserOrGroupId, 200, groupsInCommonList.get(groupsInCommonList.count - 1).chatId)

    Connections {
        target: tdLibWrapper
        onChatsReceived:
            if (extra == "getGroupsInCommon:"+chatUserOrGroupId) {
                handleGroupsInCommon(chatIds, totalCount)
                loadedTimer.start()
            }
    }
}
