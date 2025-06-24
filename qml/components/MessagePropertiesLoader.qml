import QtQuick 2.0

QtObject {
    id: loader
    property var message: ({})
    // we use var in MessageListViewItem instead of int, so
    property var chatId: message.chat_id
    property var messageId: message.id
    property bool autoLoad: true

    property var properties: ({stub: true})
    readonly property bool loaded: !properties.stub

    property bool _messagePropertiesLoading
    property var __c1: Connections {
        target: tdLibWrapper
        onMessagePropertiesReceived: if (loader.messageId === messageId) {
                                         loader.properties = messageProperties
                                         loader._messagePropertiesLoading = false
                                     }
    }

    function load() {
        if (_messagePropertiesLoading || loaded) return
        tdLibWrapper.getMessageProperties(loader.chatId, loader.messageId)
        _messagePropertiesLoading = true
    }
    function reset() {
        properties = {stub: true}
    }

    Component.onCompleted: if (autoLoad) load()
}
