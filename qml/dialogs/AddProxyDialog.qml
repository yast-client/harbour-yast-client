import QtQuick 2.6
import Sailfish.Silica 1.0
import "../js/functions.js" as Functions

Dialog {
    id: dialog
    objectName: 'addProxyDialog'

    property int editProxyId: -1
    property bool openAfterAdding

    property alias server: serverField.text
    property alias port: portField.text
    property var proxyType

    property alias proxyTypeId: typeComboBox.currentIndex
    readonly property bool isMtproto: proxyTypeId == 0
    readonly property bool isHttp: proxyTypeId == 2

    property double ping: -1

    Component.onCompleted:
        if (proxyType)
            switch (proxyType['@type']) {
            case 'proxyTypeMtproto':
                proxyTypeId = 0
                secretField.text = proxyType.secret
                break
            case 'proxyTypeSocks5':
            case 'proxyTypeHttp':
                proxyTypeId = proxyType['@type'] === 'proxyTypeHttp' ? 2 : 1
                usernameField.text = proxyType.username
                passwordField.text = proxyType.password
                if (isHttp)
                    transparentConnectionSwitch.checked = !proxyType.http_only
                break
            }

    function getTypeObject() {
        var type = {}
        switch (proxyTypeId) {
        case 0:
            type['@type'] = 'proxyTypeMtproto'
            type.secret = secretField.text
            break
        case 1:
        case 2:
            type['@type'] = isHttp ? 'proxyTypeHttp' : 'proxyTypeSocks5'
            type.username = usernameField.text
            type.password = passwordField.text
            if (isHttp)
                type.http_only = !transparentConnectionSwitch.checked
            break
        }
        return type
    }

    signal proxyChanged
    onProxyChanged: statusLabel.visible = false

    canAccept: serverField.acceptableInput && portField.acceptableInput
    onAccepted:
        if (editProxyId >= 0)
            tdLibWrapper.editProxy(editProxyId, server, port, getTypeObject())
        else
            tdLibWrapper.addProxy(server, port, getTypeObject(), openAfterAdding ? 'open' : 'new', openAfterAdding)

    Connections {
        target: tdLibWrapper
        onProxyPingErrorReceived:
            if (server == dialog.server && port == dialog.port && JSON.stringify(type) === JSON.stringify(getTypeObject()))
                dialog.ping = -2
        onProxyPingReceived:
            if (server == dialog.server && port == dialog.port && JSON.stringify(type) === JSON.stringify(getTypeObject()))
                dialog.ping = ping
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            visible: canAccept
            MenuItem {
                text: qsTr("Check status", "Check proxy status when adding")
                onClicked: tdLibWrapper.pingProxy(server, port, getTypeObject())
            }
        }

        DialogHeader {
            id: header
            title: qsTr("Add proxy")
            acceptText: qsTr("Add")
        }

        SilicaFlickable {
            width: parent.width
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }
            contentHeight: column.height
            clip: true

            Column {
                id: column
                width: parent.width

                Label {
                    id: statusLabel
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    bottomPadding: Theme.paddingMedium
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    visible: !!text
                    text: Functions.getProxyPingDescription(ping)
                }

                TextField {
                    id: serverField
                    width: parent.width
                    label: qsTr("Server")
                    acceptableInput: !!text
                    onTextChanged: proxyChanged()
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: portField.focus = true
                }

                TextField {
                    id: portField
                    width: parent.width
                    label: qsTr("Port")
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 65535 }
                    description: errorHighlight ? qsTr("TCP/UDP port number must be within the 0-65535 range") : ''
                    onTextChanged: proxyChanged()
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked:
                        (isMtproto ? secretField : usernameField).focus = true
                }

                ComboBox {
                    id: typeComboBox
                    width: parent.width
                    label: qsTr("Type")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("MTPROTO") }
                        MenuItem { text: qsTr("SOCKS5") }
                        MenuItem { text: qsTr("HTTP") }
                    }
                    onCurrentIndexChanged: proxyChanged()
                }

                TextField {
                    id: secretField
                    width: parent.width
                    label: qsTr("Secret")
                    visible: isMtproto
                    onTextChanged: proxyChanged()
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: canAccept
                    EnterKey.onClicked: accept()
                }

                TextSwitch {
                    id: transparentConnectionSwitch
                    text: qsTr("Transparent TCP connection")
                    visible: isHttp
                    onCheckedChanged: proxyChanged()
                }

                SectionHeader {
                    visible: !isMtproto
                    text: qsTr("Credentials (optional)")
                }

                TextField {
                    id: usernameField
                    width: parent.width
                    label: qsTr("Username")
                    visible: !isMtproto
                    onTextChanged: proxyChanged()
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: passwordField.focus = true
                }

                TextField {
                    id: passwordField
                    width: parent.width
                    label: qsTr("Password")
                    visible: !isMtproto
                    onTextChanged: proxyChanged()
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: canAccept
                    EnterKey.onClicked: accept()
                }
            }
        }
    }
}
