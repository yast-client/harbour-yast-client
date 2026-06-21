import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

AccordionItem {
    id: archiveItem
    name: "archive"
    title: qsTr("Archive")

    Component {
        ResponsiveGrid {
            Component.onCompleted: tdLibWrapper.getArchiveChatListSettings()
            Connections {
                target: tdLibWrapper
                onArchiveChatListSettingsReceived: {
                    keepUnmutedChatsArchivedSwitch.checked = keepUnmutedChatsArchived
                    keepChatsFromFoldersArchivedSwitch.checked = keepChatsFromFoldersArchived
                    archiveAndMuteNewChatsFromUnknownUsersSwitch.checked = archiveAndMuteNewChatsFromUnknownUsers
                }
            }

            function save() {
                tdLibWrapper.setArchiveChatListSettings(archiveAndMuteNewChatsFromUnknownUsersSwitch.checked, keepUnmutedChatsArchivedSwitch.checked, keepChatsFromFoldersArchivedSwitch.checked)
            }
            Connections {
                target: archiveItem
                onExpandedChanged: if (!archiveItem.expanded) save()
            }
            Component.onDestruction: save()
            Connections {
                target: Qt.application
                onStateChanged:
                    if (Qt.application.state != Qt.ApplicationActive) save()
            }

            bottomPadding: Theme.paddingMedium
            TextSwitch {
                id: keepUnmutedChatsArchivedSwitch
                width: parent.columnWidth
                text: qsTr("Always keep unmuted chats archived")
                description: qsTr("Keep archived chats in the Archive even if they are unmuted and get a new message.")
            }

            TextSwitch {
                id: keepChatsFromFoldersArchivedSwitch
                width: parent.columnWidth
                enabled: !keepUnmutedChatsArchivedSwitch.checked
                text: qsTr("Always keep chats from folders archived")
                description: qsTr("Keep archived chats from folders in the Archive even if they are unmuted and get a new message.")
            }

            TextSwitch {
                id: archiveAndMuteNewChatsFromUnknownUsersSwitch
                width: parent.columnWidth
                visible: tdLibWrapper.options.can_archive_and_mute_new_chats_from_unknown_users
                text: qsTr("Automatically archive new chats from unknown users")
                description: qsTr("Automatically archive and mute new chats, groups and channels from non-contacts.")
            }
        }
    }
}
