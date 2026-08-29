//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components/tdlib"
import "../components/chat"
import "../js/twemoji.js" as Emoji

Page {
    id: page
    allowedOrientations: Orientation.All

    property double communityId
    property var community: tdData.getCommunity(communityId)
    property var communityFullInfo

    Connections {
        target: tdData
        onCommunityUpdated:
            if (page.communityId == communityId)
                page.community = tdData.getCommunity(communityId)
    }
    Connections {
        target: tdLibWrapper
        onCommunityFullInfoUpdated:
            if (page.communityId == communityId)
                page.communityFullInfo = communityFullInfo
    }

    Component.onCompleted: tdLibWrapper.loadCommunityFullInfo(communityId)

    SilicaListView {
        anchors.fill: parent

        PullDownMenu {
            visible:
                switch (community.status['@type']) {
                case 'communityMemberStatusCreator':
                    return true
                case 'communityMemberStatusAdministrator':
                    return community.status.rights.can_change_info
                default:
                    return false
                }

            MenuItem {
                text: qsTr("Rename community")
                onClicked: pageStack.push(renamePageComponent)
            }
        }

        header: ChatHeader {
            enabled: false
            chatNameText.text: Emoji.emojify(community.name, chatNameText.font.pixelSize)
            chatStatusText.text: communityFullInfo ? qsTr("%Ln chats", "Number of chats in a community", communityFullInfo.chats.length) : ''
            // TODO fullscreen community photo view
            pictureThumbnail {
                photoData: community.photo.small
                minithumbnail: community.photo.minithumbnail
                radius: Theme.paddingLarge
            }
        }

        model: communityFullInfo.chats

        BusyLabel {
            running: !communityFullInfo
        }
        // no need for ViewPlaceholder here (a community must have at least one chat)

        delegate: TDLibChatListItem {
            chatId: modelData.chat_id
            enabled: modelData.can_view_history || (isPrivateChat && relatedInformation.type['@type'] === 'userTypeBot')
            openOnClick: true
        }
    }

    Component {
        id: renamePageComponent
        Dialog {
            allowedOrientations: Orientation.All
            canAccept: nameField.acceptableInput
            onAccepted: tdLibWrapper.setCommunityName(communityId, nameField.text)

            Column {
                width: parent.width
                DialogHeader {}

                TextField {
                    id: nameField
                    label: qsTr("Community name")
                    text: community.name
                    acceptableInput: !!text
                }
            }
        }
    }
}
