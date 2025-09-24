import QtQuick 2.0
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0

PageHeader {
    id: pageHeader

    property string defaultTitle: qsTr("Ferniegram")

    title: defaultTitle
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
            when: tdLibWrapper.connectionState == TDLibAPI.WaitingForNetwork
            PropertyChanges { target: pageStatus; color: "red" }
            PropertyChanges { target: pageHeader; title: qsTr("Waiting for network...") }
        },
        State {
            name: "Connecting"
            when: tdLibWrapper.connectionState == TDLibAPI.Connecting
            PropertyChanges { target: pageStatus; color: "gold" }
            PropertyChanges { target: pageHeader; title: qsTr("Connecting to network...") }
        },
        State {
            name: "ConnectingToProxy"
            when: tdLibWrapper.connectionState == TDLibAPI.ConnectingToProxy
            PropertyChanges { target: pageStatus; color: "gold" }
            PropertyChanges { target: pageHeader; title: qsTr("Connecting to proxy...") }
        },
        State {
            name: "ConnectionReady"
            when: tdLibWrapper.connectionState == TDLibAPI.ConnectionReady
            PropertyChanges { target: pageStatus; color: "green" }
            PropertyChanges { target: pageHeader; title: pageHeader.defaultTitle }
        },
        State {
            name: "Updating"
            when: tdLibWrapper.connectionState == TDLibAPI.Updating
            PropertyChanges { target: pageStatus; color: "lightblue" }
            PropertyChanges { target: pageHeader; title: qsTr("Updating content...") }
        }
    ]
}
