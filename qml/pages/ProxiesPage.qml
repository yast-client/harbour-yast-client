import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/functions.js" as Functions

Page {
    property bool loading: true
    property bool isEmpty: !loading && proxiesModel.count == 0

    property var proxiesToCopy
    property int proxiesToCopyCount

    property int proxiesToImportDone
    property int proxiesToImportFailed
    property int proxiesToImportTotal

    ListModel {
        id: proxiesModel
    }

    function handleProxyToImportReceived() {
        if (proxiesToImportDone + proxiesToImportFailed == proxiesToImportTotal) {
            if (proxiesToImportDone && proxiesToImportFailed)
                appNotification.show(qsTr("%1, %2", 'Combines the "Added %Ln proxies" and "%Ln failed" strings')
                    .arg(qsTr("Added %Ln proxies", 'First part of "Added %Ln proxies, %Ln failed"', proxiesToImportDone))
                    .arg(qsTr("%Ln failed", 'Second part of "Added %Ln proxies, %Ln failed"', proxiesToImportFailed))
                    )
            else if (proxiesToImportFailed)
                appNotification.show(qsTr("Failed to add %Ln proxies", '', proxiesToImportFailed))
            else
                appNotification.show(qsTr("Added %Ln proxies", '', proxiesToImportDone))
        }
    }

    Connections {
        target: tdLibWrapper
        onAddedProxiesReceived: {
            proxiesModel.clear()
            for (var i=0; i < proxies.length; i++)
                proxiesModel.append(proxies[i])
            loading = false
        }
        onAddedProxyReceived:
            if (extra == 'new')
                proxiesModel.append(proxy)

        onHttpUrlReceived:
            if (proxiesToCopy && extra == 'copyProxyList') {
                proxiesToCopy.push(url)
                if (proxiesToCopy.length == proxiesToCopyCount) {
                    Clipboard.text = proxiesToCopy.join('\n')
                    appNotification.show(qsTr("Proxy List copied to clipboard"))
                }
            }
        onInternalLinkTypeReceived:
            if (extra == 'proxyLinkImport') {
                if (type['@type'] == 'internalLinkTypeProxy') {
                    proxiesToImportDone++
                    tdLibWrapper.addProxy(type.proxy, 'new')
                } else
                    proxiesToImportFailed++

                handleProxyToImportReceived()
            }
        onErrorReceived:
            if (extra == 'proxyLinkImport') {
                proxiesToImportFailed++
                handleProxyToImportReceived()
            }
    }

    Component.onCompleted: tdLibWrapper.getProxies()

    function getProxyTypeText(type) {
        switch (type['@type']) {
        case 'proxyTypeMtproto':
            return qsTr("MTPROTO")
        case 'proxyTypeSocks5':
            return qsTr("SOCKS5")
        case 'proxyTypeHttp':
            return qsTr("HTTP")
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                visible: !!Clipboard.text
                text: qsTr("Add proxy from clipboard")
                onClicked: {
                    var proxyLinks = Clipboard.text.split('\n').map(function (el) { return el.trim() }).filter(function (el) { return el })
                    proxiesToImportDone = proxiesToImportFailed = 0
                    proxiesToImportTotal = proxyLinks.length
                    for (var i=0; i < proxiesToImportTotal; i++)
                        tdLibWrapper.getInternalLinkType(proxyLinks[i], 'proxyLinkImport')
                }
            }
            MenuItem {
                visible: !loading
                text: qsTr("Copy Proxy List")
                onClicked: {
                    proxiesToCopy = []
                    proxiesToCopyCount = proxiesModel.count
                    for (var i=0; i < proxiesToCopyCount; i++)
                        tdLibWrapper.getInternalLink({'@type': 'internalLinkTypeProxy', proxy: proxiesModel.get(i).proxy}, 'copyProxyList')
                }
            }
            MenuItem {
                text: qsTr("Add proxy")
                onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AddProxyDialog.qml"))
            }
        }

        BusyLabel {
            running: loading
        }

        ViewPlaceholder {
            enabled: isEmpty
            text: qsTr("No proxies")
            hintText: qsTr("Pull down to add a new proxy server")
        }

        Column {
            id: column
            width: parent.width
            opacity: loading ? 0 : 1
            Behavior on opacity { FadeAnimator {} }

            PageHeader {
                title: qsTr("Proxy")
                description: qsTr("Proxy servers may be helpful in accessing Telegram if there is no connection in a specific region.")
                descriptionWrapMode: Text.Wrap
            }

            SectionHeader {
                visible: !isEmpty
                text: qsTr("Connections")
            }

            TextSwitch {
                id: withoutProxySwitch
                visible: !isEmpty
                text: qsTr("Without Proxy")
                automaticCheck: false
                checked: true

                property double ping: -1
                description: Functions.getProxyPingDescription(ping)

                onClicked:
                    if (!checked)
                        tdLibWrapper.disableProxy()

                Connections {
                    target: tdLibWrapper
                    onOkReceived:
                        if (extra == "disableProxy") {
                            withoutProxySwitch.busy = false
                            withoutProxySwitch.checked = true
                        } else if (extra.indexOf('enableProxy:') === 0)
                            withoutProxySwitch.busy = withoutProxySwitch.checked = false
                    onPingErrorReceived:
                        withoutProxySwitch.ping = -2
                    onPingReceived:
                        withoutProxySwitch.ping = ping
                }
                Component.onCompleted: tdLibWrapper.pingProxy()
            }

            Repeater {
                model: proxiesModel
                ListItem {
                    id: proxyItem
                    contentHeight: proxySwitch.height

                    highlighted: proxySwitch.down || menuOpen
                    _backgroundColor: 'transparent'
                    openMenuOnPressAndHold: false

                    TextSwitch {
                        id: proxySwitch
                        text: getProxyTypeText(proxy.type) + ' <font color="%1">'.arg(highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor) + proxy.server + ':' + proxy.port + '</font>'
                        highlighted: proxyItem.highlighted

                        property double ping: -1
                        description: Functions.getProxyPingDescription(ping)

                        automaticCheck: false
                        checked: is_enabled
                        Component.onCompleted: {
                            if (is_enabled)
                                withoutProxySwitch.checked = false
                            tdLibWrapper.pingProxy(model.proxy)
                        }

                        onClicked: {
                            if (!is_enabled) {
                                busy = true
                                tdLibWrapper.enableProxy(model.id)
                            }
                        }
                        onPressAndHold: proxyItem.openMenu()

                        function setEnabled(enabled) {
                            proxiesModel.setProperty(index, 'is_enabled', enabled)
                            busy = false
                        }

                        Connections {
                            target: tdLibWrapper
                            onOkReceived:
                                if (extra == 'removeProxy:' + model.id) {
                                    if (is_enabled)
                                        withoutProxySwitch.checked = true
                                    proxiesModel.remove(index)
                                } else if (extra == 'disableProxy' && is_enabled)
                                    proxySwitch.setEnabled(false)
                                else if (extra.indexOf('enableProxy:') == 0)
                                    proxySwitch.setEnabled(extra == 'enableProxy:' + model.id)

                            onProxyPingErrorReceived:
                                if (server === proxy.server && port === proxy.port && JSON.stringify(type) === JSON.stringify(proxy.type))
                                    proxySwitch.ping = -2
                            onProxyPingReceived:
                                if (server === proxy.server && port === proxy.port && JSON.stringify(type) === JSON.stringify(proxy.type))
                                    proxySwitch.ping = ping
                            onAddedProxyReceived:
                                if (!extra && proxy.id === model.id) {
                                    proxiesModel.set(index, proxy)
                                    tdLibWrapper.pingProxy(model.proxy)
                                }
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Remove", "proxy")
                            onClicked: remorseDelete(function() { tdLibWrapper.removeProxy(model.id) })
                        }
                        MenuItem {
                            text: qsTr("Edit", "proxy")
                            onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/AddProxyDialog.qml"),
                                                      {editProxyId: model.id, server: proxy.server, port: proxy.port, proxyType: proxy.type})
                        }
                        MenuItem {
                            text: qsTr("Copy link", "proxy")
                            onClicked: tdLibWrapper.getInternalLink({'@type': 'internalLinkTypeProxy', proxy: proxy}, 'copy')
                        }
                    }
                }
            }
        }
    }
}
