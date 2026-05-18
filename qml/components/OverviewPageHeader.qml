import QtQuick 2.0
import Sailfish.Silica 1.0
import io.libfernie 1.0

PageHeader {
    id: pageHeader

    property alias statusItem: pageStatus
    property string defaultTitle: qsTr("Ferniegram")

    title: tdLibState.connectionStateText || defaultTitle
    leftMargin: Theme.itemSizeMedium

    GlassItem {
        id: pageStatus
        width: Theme.itemSizeMedium
        height: Theme.itemSizeMedium
        color: "red"
        falloffRadius: 0.1
        radius: 0.2
        cache: false
        anchors.bottom: parent.bottom
    }

    states: [
        State {
            name: "WaitingForNetwork"
            when: tdLibState.connectionState == TDLibState.WaitingForNetwork
            PropertyChanges { target: pageStatus; color: "red" }
        },
        State {
            name: "Connecting"
            when: tdLibState.connectionState == TDLibState.Connecting
            PropertyChanges { target: pageStatus; color: "gold" }
        },
        State {
            name: "ConnectingToProxy"
            when: tdLibState.connectionState == TDLibState.ConnectingToProxy
            PropertyChanges { target: pageStatus; color: "gold" }
        },
        State {
            name: "ConnectionReady"
            when: tdLibState.connectionState == TDLibState.ConnectionReady
            PropertyChanges { target: pageStatus; color: "green" }
        },
        State {
            name: "Updating"
            when: tdLibState.connectionState == TDLibState.Updating
            PropertyChanges { target: pageStatus; color: "lightblue" }
        }
    ]
}
