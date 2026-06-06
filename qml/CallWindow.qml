import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Window 2.2
import io.libfernie 1.0
import "components"

Window {
    onClosing: destroy()
    Component.onDestruction:
        appWindow.callWindowInstance = null

    ApplicationWindow {
        id: callWindow
        cover: Qt.resolvedUrl("pages/CallCover.qml")
        initialPage: Qt.resolvedUrl("pages/CallPage.qml")

        TDLibUser {
            id: user
            userId: callsManager.currentCallUserId
        }

        readonly property bool canHangUp:
            switch (callsManager.currentCallState) {
            case CallsManager.HangingUp:
            case CallsManager.Declined:
            case CallsManager.Disconnected:
            case CallsManager.HungUp:
            case CallsManager.Discarded:
            case CallsManager.Error:
            case CallsManager.UnknownError:
                return false
            default:
                return true
            }
        readonly property bool canCallBack:
            switch (callsManager.currentCallState) {
            case CallsManager.Declined:
            case CallsManager.Disconnected:
            case CallsManager.HungUp:
            case CallsManager.Discarded:
            case CallsManager.Error:
            case CallsManager.UnknownError:
                return true
            default:
                return false
            }

        readonly property string callStatus:
            switch (callsManager.currentCallState) {
            case CallsManager.Pending:
                return qsTr("Connecting…")
            case CallsManager.Ringing:
                return qsTr("Ringing…")
            case CallsManager.ExchangingKeys:
                return qsTr("Exchanging keys…")
            case CallsManager.HangingUp:
                return qsTr("Hanging up…")
            case CallsManager.Declined:
                return qsTr("Line busy")
            case CallsManager.Disconnected:
                return qsTr("Disconnected")
            case CallsManager.HungUp:
            case CallsManager.Discarded:
                return qsTr("Call ended")
            case CallsManager.Error:
                var error = callsManager.currentCallError
                if (error.code === 4005000)
                    return qsTr("Connection timed out")
                return error.message ? qsTr("An error occured: %1").arg(error.message) : qsTr("An error occured")
            case CallsManager.Connecting:
                return qsTr("Connecting…")
            case CallsManager.Connected:
                return ""
            case CallsManager.UnknownError:
                return qsTr("Connection error")
            }

        Component.onCompleted: activate()
        Component.onDestruction:
            if (canHangUp)
                callsManager.discardCurrentCall()
    }
}
