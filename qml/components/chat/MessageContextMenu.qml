import QtQuick 2.0
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '..'
import '../../modules/Opal/FancyMenus'
import '../../js/functions.js' as Functions
import '../../js/debug.js' as Debug

Loader {
    id: contextMenuLoader
    active: false
    asynchronous: true

    property Item listItem
    property MessageData messageData
    property bool canCopy
    property bool canTranslate

    readonly property var messageId: messageData.messageId
    readonly property var message: messageData.message
    readonly property var reactions: messageData.reactions

    signal ready
    signal handleExtraContextMenuItems(var properties, var parent)

    function open() {
        contextMenuLoader.sourceComponent = mainContextMenuComponent
        contextMenuLoader.active = true
    }

    signal reply
    signal edit
    signal forward

    function togglePinned() {
        if (message.is_pinned)
            Remorse.popupAction(page, qsTr("Message unpinned"), function() {
                tdLibWrapper.unpinMessage(chatId, messageId)
            })
        else tdLibWrapper.pinMessage(chatId, messageId)
    }

    function deleteMessage(revoke) {
        Remorse.itemAction(listItem, (revoke || isSavedMessages) ? qsTr("Message deleted") : qsTr("Message deleted only for yourself"), function() {
            tdLibWrapper.deleteMessages(chatId, [messageId], revoke)
        })
    }

    function translate() {
        pageStack.push(Qt.resolvedUrl("../../pages/TranslatePage.qml"), {
                           messageId: messageId,
                           message: message,
                       })
    }

    MessagePropertiesLoader {
        id: propertiesLoader
        chatId: chatPage.chatId
        messageId: contextMenuLoader.messageId
        autoLoad: false

        onLoadedChanged:
            if (loaded) {
                if (properties.can_get_read_date && isOutgoingRead)
                    tdLibWrapper.getMessageReadDate(chatId, messageId)
            }
    }
    property alias messageProperties: propertiesLoader.properties
    readonly property bool canDeleteMessage: !!(messageProperties.can_be_deleted_for_all_users || messageProperties.can_be_deleted_only_for_self)

    property int messageReadDate

    property int reactionsRowSize: Math.floor(width / Theme.itemSizeSmall)
    property var messageReactions
    property bool reactionsLoading

    function getAvailableReactions() {
        if (reactionsLoading) return

        Debug.log("Obtaining message reactions, row size:", reactionsRowSize)
        reactionsLoading = true
        tdLibWrapper.getMessageAvailableReactions(chatId, messageId, reactionsRowSize)
    }
    onReactionsRowSizeChanged: // width changed
        if (status == Loader.Loading || status == Loader.Ready)
            getAvailableReactions()

    function loadData() {
        propertiesLoader.load()
        getAvailableReactions()
    }
    function reset() {
        propertiesLoader.reset()
        contextMenuLoader.messageReactions = null
        contextMenuLoader.reactionsLoading = false
        contextMenuLoader.messageReadDate = 0
    }

    Connections {
        target: tdLibWrapper
        onAvailableReactionsReceived:
            if (chatPage.chatId === chatId && contextMenuLoader.messageId === messageId) {
                Debug.log("Message reactions received")
                contextMenuLoader.reactionsLoading = false
                if (unavailabilityReason !== TDLibAPI.None) {
                    Debug.log("Reactions are unavailable", unavailabilityReason)
                    contextMenuLoader.messageReactions = null
                    return
                }

                contextMenuLoader.messageReactions = reactions
            }
        onMessageReadDateReceived:
            if (chatPage.chatId === chatId && contextMenuLoader.messageId === messageId) {
                Debug.log("Message read date received")
                contextMenuLoader.messageReadDate = typeof readDate == 'number' ? readDate : -1
            }
    }

    onStatusChanged: {
        if (status == Loader.Loading || status == Loader.Ready)
            loadData()

        if (status === Loader.Ready)
            ready()
        else if (status != Loader.Loading)
            reset()
    }

    sourceComponent: mainContextMenuComponent

    function toggleReaction(type) {
        if (type['@type'] === 'reactionTypePaid') {
            // TODO
            return
        }

        for (var i = 0; i < reactions.length; i++) {
            var reaction = reactions[i]
            if (JSON.stringify(reaction.type) === JSON.stringify(type)) {
                if (reaction.is_chosen) {
                    // Reaction is already selected
                    tdLibWrapper.removeMessageReaction(chatId, messageId, reaction.type)
                    return
                }
                break
            }
        }
        // Reaction is not yet selected
        tdLibWrapper.addMessageReaction(chatId, messageId, type, true)
    }

    Component {
        id: reactionMenuItemComponent
        BaseRowMenuItem {
            id: reactionMenuItem
            visible: reactionLoader.supported
            //highlight: false

            MessageReaction {
                id: reactionLoader
                anchors.centerIn: parent
                type: modelData.type
                highlighted: reactionMenuItem.down
            }

            onClicked: contextMenuLoader.toggleReaction(modelData.type)
        }
    }

    Component {
        id: mainContextMenuComponent
        FancyContextMenu {
            id: mainContextMenu
            listItem: contextMenuLoader.listItem

            readonly property bool isMessageListViewItemMainContextMenu: true

            onActiveChanged:
                if (active) contextMenuLoader.loadData()
            onClosed: // closed is called at end of animation, and active is set to false at the start
                contextMenuLoader.reset()

            MenuItem {
                visible: messagesView.canJumpToMessage
                text: qsTr("Jump to message")
                onClicked: jumpedTo(messageData.messageIndex, messageId)
            }

            MenuItemLoader {
                sourceComponent: Component {
                    FancyMenuRow {
                        visible: messageReactions && messageReactions.top_reactions && messageReactions.top_reactions.length

                        Repeater {
                            model: messageReactions.top_reactions.slice(0, reactionsRowSize - moreReactionsMenuItem.visible)
                            delegate: reactionMenuItemComponent
                        }

                        IconRowMenuItem {
                            id: moreReactionsMenuItem
                            visible: messageReactions && messageReactions.top_reactions && reactionsRowSize < messageReactions.top_reactions.length
                            icon.source: "image://theme/icon-m-down"
                            onClicked:
                                contextMenuLoader.sourceComponent = reactionsContextMenuComponent
                        }
                    }
                }
            }

            FancyMenuRow {
                // NOTE: In places like this we should generally use `enabled` instead of `visible` so people can rely on spatial memory.
                // NOTE2: When a user selects a message, the finger first goes to the (horizontal) center of the message, so the most used options should be there
                IconRowMenuItem {
                    icon.source: "image://theme/icon-m-select-all"
                    onClicked: messagesView.toggleMessageSelection(message, messageData.messageAlbumMessageIds)
                }
                IconRowMenuItem {
                    icon.source: "image://theme/icon-m-clipboard"
                    visible: canCopy
                    onClicked:
                        Clipboard.text = messageData.isAlbum
                                            ? utilities.getAlbumMessagesText(messageData.messageAlbumMessages, Utilities.MessageTextDefault, true, false)
                                            : utilities.getMessageText(message, Utilities.MessageTextDefault, true, false)
                }
                IconRowMenuItem {
                    visible: !!messageProperties.can_be_pinned // FIXME: should we use enabled or visible here? for spatial memory
                    icon.source: "../../../images/icon-m-" + (message.is_pinned ? 'un' : '') + "pin.svg"
                    onClicked: togglePinned()
                }
                IconRowMenuItem {
                    visible: appSettings.showTranslateOption
                    enabled: canTranslate
                    icon.source: "image://theme/icon-m-region"
                    onClicked: translate()
                }
            }
            FancyMenuRow {
                checkShort: function (ratio) { return Screen.sizeCategory <= Screen.Large && ratio > 1 }
                IconTextRowMenuItem {
                    visible: !!messageProperties.can_be_forwarded
                    icon.source: "image://theme/icon-m-message-forward"
                    shortText: qsTr("Forward", 'Short version for "Forward Message"')
                    longText: qsTr("Forward Message")
                    onClicked: forward()
                }
                IconTextRowMenuItem {
                    visible: !!messageProperties.can_be_replied
                    icon.source: "image://theme/icon-m-message-reply"
                    shortText: qsTr("Reply", 'Short version for "Reply to Message"')
                    longText: qsTr("Reply to Message")
                    onClicked: reply()
                }
            }
            FancyMenuRow {
                visible: !yaqtSettings.superCompactMessageMenu
                checkShort: function (ratio, size) { return Screen.sizeCategory <= Screen.Large && ratio > 1 }
                IconTextRowMenuItem {
                    visible: canDeleteMessage
                    icon.source: "image://theme/icon-m-delete"
                    shortText: qsTr("Delete", 'Short version for "Delete Message"')
                    longText: qsTr("Delete Message")
                    onClicked: {
                        if (messageProperties.can_be_deleted_only_for_self && messageProperties.can_be_deleted_for_all_users)
                            contextMenuLoader.sourceComponent = deleteContextMenuComponent
                        else
                            deleteMessage(!!messageProperties.can_be_deleted_for_all_users)
                    }
                }
                IconTextRowMenuItem {
                    visible: !!messageProperties.can_be_edited
                    icon.source: "image://theme/icon-m-edit"
                    shortText: qsTr("Edit", 'Short version for "Edit Message"')
                    longText: qsTr("Edit Message")
                    onClicked: edit()
                }
            }

            MenuLabel {
                visible: !!messageProperties.can_get_read_date && messageData.isOutgoingRead && messageReadDate >= 0
                text: messageReadDate
                      ? qsTr("Read %1", "Message read date").arg(Functions.getDateTimeTimepointRelative(messageReadDate))
                      : qsTr("Loading", "Indicates that the message read date is being loaded")
            }

            MenuLabel {
                visible: !!message.edit_date
                text: qsTr("Edited %1", "Message edit date").arg(Functions.getDateTimeTimepointRelative(myMessage.edit_date))
            }

            FancyMenuItem {
                text: "Copy debug info"
                icon.source: "image://theme/icon-m-diagnostic"
                visible: DebugLog.enabled
                onClicked: Clipboard.text =
                           "Message ID: " + messageId
                           + "\nMessage object:\n" + JSON.stringify(message, null, 2)
                           + "\n\n\nMessage properties:\n" + JSON.stringify(messageProperties, null, 2)
            }

            Component.onCompleted: handleExtraContextMenuItems(messageProperties, _contentColumn)
            Component.onDestruction: handleExtraContextMenuItems({}, null)
        }
    }

    Component {
        id: reactionsContextMenuComponent

        ContextMenu {
            // HACK: disable animation when opening the menu
            height: _contentHeight
            on_DisplayHeightChanged:
                if (_contentHeight == _displayHeight)
                    height = Qt.binding(function() { return _displayHeight })

            SilicaFlickable {
                id: reactionsFlickable
                width: parent.width
                height: Math.min(contentHeight, Theme.itemSizeLarge*3)
                contentHeight: reactionsGrid.height

                Grid {
                    id: reactionsGrid
                    width: parent.width
                    columns: reactionsRowSize

                    Repeater {
                        model: messageReactions.top_reactions
                        delegate: BackgroundItem {
                            visible: reactionLoader.supported
                            width: parent.width / parent.columns
                            height: Theme.itemSizeSmall

                            MessageReaction {
                                id: reactionLoader
                                anchors.centerIn: parent
                                type: modelData.type
                                highlighted: down
                            }

                            onClicked: {
                                contextMenuLoader.toggleReaction(modelData.type)
                                close()
                            }
                        }
                    }

                    VerticalScrollDecorator { flickable: reactionsFlickable }
                }
            }
        }
    }

    Component {
        id: deleteContextMenuComponent
        ContextMenu {
            MenuItem {
                text: (isPrivateChat || isSecretChat) ? qsTr("Delete for me and %1").arg(getChatTitle(font.pixelSize)) : qsTr("Delete for everyone")
                onClicked: deleteMessage(true)
            }
            MenuItem {
                text: qsTr("Delete just for me")
                onClicked: deleteMessage(false)
            }
        }
    }
}
