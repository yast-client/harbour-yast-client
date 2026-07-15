//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import '..'
import '../tdlib'

ChatInformationTabItemChatsBase {
    loadInitial: !isBasicGroup
    fullyLoaded: isBasicGroup || groupInformation.member_count <= view.count
    loadingText: isChannel ? qsTr("Loading subscribers", "channel") : qsTr("Loading members", "group")
    placeholderText: isChannel
                        ? (canGetMembers ? qsTr("This channel is empty") : qsTr("Channel members are anonymous"))
                        : qsTr("This group is empty")
    model: membersList
    delegate: TDLibChatListItem {
        messageSender: model.member_id
        prologSecondaryText.text: chatId ? chatTypeName : ''
    }

    onLoadMore:
        tdLibWrapper.getSupergroupMembers(chatUserOrGroupId, initial ? 50 : 200, membersList.count)

    Connections {
        target: tdLibWrapper
        onChatMembersReceived:
            if (chatId === chatUserOrGroupId) {
                handleGroupMembers(members, false)
                loading = false
            }
    }
}
