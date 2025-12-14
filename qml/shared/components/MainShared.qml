import QtQuick 2.0
import App.Logic 1.0
import "../js/functions.js" as Functions

QtObject {
    property Connections c1: Connections {
        target: tdLibWrapper
        onOpenFileExternally: Qt.openUrlExternally(filePath)
        onErrorReceived: Functions.handleErrorMessage(code, message, extra)
        onServiceNotificationReceived: appNotification.show(utilities.getMessageContentText(content, Utilities.MessageTextSimple))
        onLinkUnsupportedByApp: appNotification.show(qsTr("Link unsupported: %1").arg(type))
        onDeepLinkInfoReceived:
            appNotification.show(utilities.getMessageContentText(text, Utilities.MessageTextSimple))
    }

    Component.onCompleted: {
        Functions.setGlobals({
            tdLibWrapper: tdLibWrapper,
            appNotification: appNotification,
            utilities: utilities,
        })
    }
}
