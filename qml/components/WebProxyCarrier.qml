//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.WebView 1.0
import "../js/debug.js" as Debug

RawWebView {
    visible: false
    enabled: false

    property int carrierId
    property url proxyUrl
    // TODO: what should we do with origin and pathPrefix?
    property string origin
    property string pathPrefix

    function postMessage(data) {
        sendAsyncMessage('toProxyMessage', {data: data})
    }

    Component.onCompleted: {
        Debug.log("[WebProxyCarrier] Carrier created", carrierId)
        addMessageListener('fromProxyMessage')
        loadFrameScript(Qt.resolvedUrl("../../assets/webproxyframescript.js"))
        url = proxyUrl
    }
    Component.onDestruction: Debug.log("[WebProxyCarrier] Carrier destroyed", carrierId)

    // TODO: block requests to wrong hosts from other placestoo (e.g. iframes, fetch() from JS and so on)
    onUrlChanged: {
        var strUrl = String(url)
        if (!strUrl.indexOf(origin + pathPrefix) === 0 && !strUrl.indexOf(origin + ':443' + pathPrefix) === 0) {
            stop()
            Debug.warn("[WebProxyCarrier] Invalid URL opened")
            tdLibWrapper.reportWebProxyCarrierError(carrierId, "Invalid URL opened")
        }
    }

    onRecvAsyncMessage:
        if (message === 'fromProxyMessage') {
            var proxyData = data.data
            if (proxyData[0] === 'f')
                tdLibWrapper.reportWebProxyCarrierError(carrierId, "Error from WebView: " + proxyData.slice(1))
            else
                tdLibWrapper.processWebProxyCarrierMessage(carrierId, proxyData[0] === 'b', proxyData.slice(1))
        }
}
