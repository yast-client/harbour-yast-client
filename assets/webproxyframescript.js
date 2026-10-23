// Based on https://github.com/UnigramDev/Unigram/blob/develop/Telegram/Common/WebProxyCarrierHost.cs
//@ SPDX-FileCopyrightText: 2026-present roundedrectangle, Fela Ameghino 2015-2026
//@ SPDX-License-Identifier: GPL-3.0-or-later

addEventListener("DOMWindowCreated", (event) => {
    const win = event.target.defaultView.wrappedJSObject;
    if (!win) return;

    // Disable some APIs for security
    const remove = (target, name) => { try { Object.defineProperty(target, name, { value: undefined, configurable: false, writable: false }) } catch (error) { } };
    for (const name of ['RTCPeerConnection', 'webkitRTCPeerConnection', 'RTCDataChannel', 'RTCSessionDescription', 'RTCIceCandidate', 'WebTransport', 'WebAssembly', 'Worker', 'SharedWorker', 'Notification', 'PaymentRequest', 'PresentationRequest', 'SpeechSynthesisUtterance', 'webkitSpeechRecognition', 'showOpenFilePicker', 'showSaveFilePicker', 'showDirectoryPicker', 'localStorage', 'sessionStorage', 'indexedDB', 'caches'])
        remove(win, name);

    const navigator = win.navigator;
    for (const name of ['serviceWorker', 'mediaDevices', 'getUserMedia', 'geolocation', 'credentials', 'storage', 'locks', 'wakeLock', 'share', 'xr', 'bluetooth', 'usb', 'hid', 'serial', 'sendBeacon', 'permissions', 'getGamepads'])
        remove(navigator, name);


    if (Object.prototype.hasOwnProperty.call(win, 'TelegramWebProxy')) return;

    const Cu = Components.utils

    let receiver = null

    function encode(value) {
        const bytes = new Uint8Array(value), parts = []
        for (let i = 0; i < bytes.length; i += 32768)
            parts.push(String.fromCharCode.apply(null, bytes.subarray(i, i + 32768)))
        return btoa(parts.join(''))
    }
    function decode(value) {
        const binary = atob(value), bytes = new Uint8Array(binary.length)
        for (let i = 0; i < binary.length; i++)
            bytes[i] = binary.charCodeAt(i)
        return bytes.buffer
    }

    function postNativeMessage(data) {
        sendAsyncMessage('fromProxyMessage', { data })
    }

    addMessageListener('toProxyMessage', e => {
        const value = e.data.data
        if (typeof value !== 'string' || value.length === 0) return
        if (typeof receiver !== 'function') {
            postNativeMessage('f' + "Receiver not set")
            return
        }

        try {
            const data = Cu.cloneInto({ data: decode(value) }, win);
            receiver(data)
        } catch (error) {
            postNativeMessage('f' + "Couldn't dispatch message: " + error)
        }
    }, true)

    const bridge = Cu.createObjectIn(win)

    const privilegedGlobal = globalThis
    Cu.exportFunction(function(value) {
        try {
            if (value instanceof win.ArrayBuffer || Object.prototype.toString.call(value) === '[object ArrayBuffer]') {
                const cloned = Cu.cloneInto(value, privilegedGlobal)
                postNativeMessage('b' + encode(cloned))
            } else if (ArrayBuffer.isView(value)) {
                // TODO: this part was not tested
                const cloned = Cu.cloneInto(value, privilegedGlobal)
                postNativeMessage('b' + encode(cloned.buffer.slice(cloned.byteOffset, cloned.byteOffset + cloned.byteLength)))
            } else if (typeof value === 'string')
                postNativeMessage('c' + value)
            else
                postNativeMessage('f' + "Unknown data type: " + typeof value)
        } catch (e) {
            postNativeMessage('f' + "postMessage failed: " + e)
        }
    }, bridge, { defineAs: 'postMessage' })

    Object.defineProperty(bridge, 'onmessage', {
        get: Cu.exportFunction(() => receiver, win),
        set: Cu.exportFunction((value) => { receiver = typeof value === 'function' ? value : null }, win),
        enumerable: true,
        configurable: false
    })

    Object.freeze(bridge)

    Object.defineProperty(win, 'TelegramWebProxy', {
        value: bridge,
        configurable: false,
        writable: false
    })
}, true)

// TODO
/*addEventListener("DOMContentLoaded", (event) => {
    // Lock policy
    const applyPolicy = () => {
        const meta = document.createElement('meta')
        meta.httpEquiv = 'Content-Security-Policy'
        meta.content = "default -src 'self'; script - src 'self' 'unsafe-inline'; style - src 'self' 'unsafe-inline'; img - src 'self' data: ; connect - src 'self' wss://" + location.host + "; object-src 'none'; frame-src 'none'; worker-src 'none'; base-uri 'none'; form-action 'none'"
        (document.head || document.documentElement).prepend(meta)
    }
    if (document.documentElement)
        applyPolicy()
    else
        document.addEventListener('readystatechange', applyPolicy, { once: true })
}, true)*/
