import QtQuick 2.6
import Sailfish.Silica 1.0


Column {
    id: chatPermissionsColumn

    property var mediaPermissions: [
        'can_send_photos',
        'can_send_videos',
        'can_send_video_notes',
        'can_send_audios',
        'can_send_voice_notes',
        'can_send_documents',
        'can_send_other_messages',
        'can_send_polls',
        'can_add_link_previews',
    ]

    Component {
        id: permissionSwitch
        TextSwitch {
            automaticCheck: false
            readonly property string permission: modelData[0]
            text: modelData[1]
            checked: chatManager.permissions[permission]
            onCheckedChanged: busy = false
            onClicked: {
                if(busy) return
                var value = !checked
                busy = true
                var newPermissions = JSON.parse(JSON.stringify(chatManager.permissions))
                if (permission in newPermissions) {
                    newPermissions[permission] = value
                    // some permissions infer can_send_messages:
                    if(permission === "can_send_messages" && !value) {
                        for(var i in mediaPermissions)
                            newPermissions[mediaPermissions[i]] = false
                    } else if(mediaPermissions.indexOf(permission) > -1 && value)
                        newPermissions.can_send_messages = true
                }
                chatManager.permissions = newPermissions
            }
        }
    }

    Column {
        visible: chatInformationPage.groupInformation.status.can_restrict_members || chatInformationPage.groupInformation.status["@type"] === "chatMemberStatusCreator"
        width: parent.width

        SectionHeader {
            text: qsTr("Permissions", "What can members of this group do")
        }

        Loader {
            width: parent.width
            readonly property var modelData: ['can_send_basic_messages', qsTr("Send messages", "member permission")]
            sourceComponent: permissionSwitch
        }

        TextSwitch {
            text: qsTr("Send media", "member permission")
            automaticCheck: false
            checked: mediaPermissions.some(function(permission) { return chatManager.permissions[permission] })
            onCheckedChanged: busy = false
            onClicked: {
                if (busy) return
                busy = true

                var permissions = JSON.parse(JSON.stringify(chatManager.permissions))

                if (checked)
                    mediaPermissions.forEach(function(permission) { permissions[permission] = false })
                else {
                    mediaPermissions.forEach(function(permission) { permissions[permission] = true })
                    permissions.can_send_messages = true
                }

                chatManager.permissions = permissions
            }
        }

        Column {
            x: Theme.horizontalPageMargin // TextSwitch.rightMargin is still there (equal to same Theme.horizontalPageMargin)
            width: parent.width - x
            Repeater {
                model: [
                    ['can_send_photos', qsTr("Photos", "member permission")],
                    ['can_send_videos', qsTr("Videos", "member permission")],
                    ['can_send_video_notes', qsTr("Video messages", "member permission")],
                    ['can_send_audios', qsTr("Music", "member permission")],
                    ['can_send_voice_notes', qsTr("Voice messages", "member permission")],
                    ['can_send_documents', qsTr("Files", "member permission")],
                    ['can_send_other_messages', qsTr("Stickers & GIFs", "member permission")],
                    ['can_add_link_previews', qsTr("Embed links", "member permission")],
                    ['can_send_polls', qsTr("Polls", "member permission")],
                ]
                delegate: permissionSwitch
            }
        }

        Repeater {
            width: parent.width
            model: [
                ['can_invite_users', qsTr("Add members", "member permission")],
                ['can_pin_messages', qsTr("Pin messages", "member permission")],
                ['can_change_info', qsTr("Change group info", "member permission")],
            ]
            delegate: permissionSwitch
        }

        Loader {
            width: parent.width
            height: active ? implicitHeight : 0
            Behavior on height { NumberAnimation { duration: 200 } }
            active: chatInformationPage.isSupergroup && !!chatInformationPage.groupInformation.is_forum
            readonly property var modelData: ['can_create_topics', qsTr("Create topics", "member permission")]
            sourceComponent: permissionSwitch
        }
    }


}
