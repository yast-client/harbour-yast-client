//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../"
import "../../pages"
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions
import "../../js/debug.js" as Debug

ChatInformationTabItemBase {
    id: tabBase
    loading: loadInitial
    loadingVisible: loading && listView.count === 0

    property bool fullyLoaded

    scrollableView: listView
    property alias view: listView
    property alias model: listView.model
    property alias delegate: listView.delegate

    property bool loadInitial: true
    property string placeholderText

    signal loadMore(bool initial)

    SilicaListView {
        id: listView
        clip: true
        height: tabBase.height
        width: tabBase.width
        opacity: loading && !fullyLoaded ? (count > 0 ? 0.5 : 0.0) : 1.0
        Behavior on opacity { FadeAnimation {} }
        onContentYChanged: {
            if (active && !loading && !fullyLoaded && listView.indexAt(listView.contentX, listView.contentY) > Math.max(0, listView.count - 20)) {
                Debug.log("[ChatInformationTabItemChatsBase] Trying to get more items...")
                loading = true
                loadMore(false)
            }
        }
        ViewPlaceholder {
            y: Theme.paddingLarge
            enabled: listView.count === 0
            text: placeholderText
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted:
        if (loadInitial) loadMore(true)
}
