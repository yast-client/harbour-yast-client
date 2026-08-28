//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/functions.js" as Functions

// TODO: sorting

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

    function setProxyPing(server, port, type, ping) {
        for (var i=0; i < proxiesModel.count; i++) {
            var proxy = proxiesModel.get(i).proxy
            if (server === proxy.server && port === proxy.port && JSON.stringify(type) === JSON.stringify(proxy.type)) {
                proxiesModel.setProperty(i, 'ping', ping)
                break
            }
        }
    }

    function getProxyPingDescription(ping) {
        var desc = Functions.getProxyPingDescription(ping)
        if (!desc) return qsTr("connecting…", "Indicates that a connection test is being done for a proxy or a direct connection to Telegram's servers")
        return ping >= 0 ? '<font color="%1">%2</font>'.arg(Theme.secondaryHighlightColor).arg(desc) : desc
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
            for (var i=0; i < proxies.length; i++) {
                proxies[i].ping = -1
                proxiesModel.append(proxies[i])
            }
            loading = false
        }
        onOkReceived:
            if (extra.toString().indexOf('removeProxy:') == 0) {
                var proxyId = Number(extra.slice(12))
                for (var i=0; i < proxiesModel.count; i++)
                    if (proxiesModel.get(i).id == proxyId)
                        proxiesModel.remove(i)
            }
        onProxyPingErrorReceived: setProxyPing(server, port, type, -2)
        onProxyPingReceived: setProxyPing(server, port, type, ping)
        onAddedProxyReceived: {
            // even if returned from addProxy, it can be an existing proxy
            for (var i=0; i < proxiesModel.count; i++)
                if (proxiesModel.get(i).id == proxy.id) {
                    proxiesModel.set(i, proxy)
                    tdLibWrapper.pingProxy(proxy)
                    return
                }

            proxiesModel.append(proxy) // new proxy
        }

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
                    tdLibWrapper.addProxy(type.proxy)
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

    SilicaListView {
        anchors.fill: parent

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

        BusyLabel { running: loading }

        ViewPlaceholder {
            enabled: isEmpty
            text: qsTr("No proxies")
            hintText: qsTr("Pull down to add a new proxy server")
        }

        header: Column {
            width: parent.width
            opacity: loading ? 0 : 1
            Behavior on opacity { FadeAnimator {} }

            PageHeader {
                title: qsTr("Proxy")
                description: qsTr("Proxy servers may be helpful in accessing Telegram if there is no connection in a specific region.")
                descriptionWrapMode: Text.Wrap
            }

            TextSwitch {
                text: qsTr("Try connecting through IPv6")
                checked: tdData.options.prefer_ipv6
                automaticCheck: false
                onClicked: tdData.options.prefer_ipv6 = !checked
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
                checked: !tdData.options.enabled_proxy_id

                property double ping: -1
                description: getProxyPingDescription(model.ping)

                onClicked: {
                    busy = true
                    if (!checked) tdLibWrapper.disableProxy()
                }
                onCheckedChanged: busy = false

                Connections {
                    target: tdLibWrapper
                    onPingErrorReceived:
                        withoutProxySwitch.ping = -2
                    onPingReceived:
                        withoutProxySwitch.ping = ping
                }
                Component.onCompleted: tdLibWrapper.pingProxy()
            }
        }

        model: proxiesModel
        delegate: ListItem {
            id: proxyItem
            contentHeight: proxySwitch.height
            hidden: loading

            highlighted: proxySwitch.down || menuOpen
            _backgroundColor: 'transparent'
            openMenuOnPressAndHold: false

            TextSwitch {
                id: proxySwitch
                text: getProxyTypeText(proxy.type) + ' <font color="%1">%2:%3</font>'.arg(highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor).arg(proxy.server).arg(proxy.port)
                highlighted: proxyItem.highlighted

                description: getProxyPingDescription(model.ping)

                automaticCheck: false
                checked: model.id == tdData.options.enabled_proxy_id // don't use is_enabled for easier updating

                Component.onCompleted:
                    tdLibWrapper.pingProxy(model.proxy)

                onClicked: {
                    if (!checked) {
                        busy = true
                        tdLibWrapper.enableProxy(model.id)
                    }
                }
                onCheckedChanged: busy = false
                onPressAndHold: proxyItem.openMenu()
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
