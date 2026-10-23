//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.WebView 1.0
import "../js/debug.js" as Debug

WebView {
    visible: false

    property int carrierId
    property url proxyUrl
    // TODO: what should we do with origin and pathPrefix?
    property string origin
    property string pathPrefix

    function postMessage(data) {
        sendAsyncMessage('toProxyMessage', {data: data})
    }

    function checkUrl(url) {
        url = '' + url
        if (!url.indexOf(origin + pathPrefix) === 0 && !url.indexOf(origin + ':443' + pathPrefix) === 0)
            stop()
    }

    Component.onCompleted: {
        Debug.log("[WebProxyCarrier] Carrier created", carrierId)
        addMessageListener('fromProxyMessage')
        loadFrameScript(Qt.resolvedUrl("../../assets/webproxyframescript.js"))
        url = proxyUrl
    }
    Component.onDestruction: Debug.log("[WebProxyCarrier] Carrier destroyed", carrierId)

    onLinkClicked: checkUrl(url)
    onLoadRedirect: checkUrl(url)

    onRecvAsyncMessage:
        if (message === 'fromProxyMessage') {
            var proxyData = data.data
            if (proxyData[0] === 'f')
                tdLibWrapper.reportWebProxyCarrierError(carrierId, "Error from WebView:" + proxyData.slice(1))
            else
                tdLibWrapper.processWebProxyCarrierMessage(carrierId, proxyData[0] === 'b', proxyData.slice(1))
        }
}
