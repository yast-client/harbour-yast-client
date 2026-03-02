/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
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

    scrollableView: listView
    property alias view: listView
    property alias model: listView.model
    property alias delegate: listView.delegate

    property bool loadInitial: true
    property string placeholderText

    signal loadMore(bool initial)

    property alias loadedTimer: loadedTimer

    SilicaListView {
        id: listView
        clip: true
        height: tabBase.height
        width: tabBase.width
        opacity: tabBase.loading ? (count > 0 ? 0.5 : 0.0) : 1.0
        Behavior on opacity { FadeAnimation {} }
        onContentYChanged: {
            if (active && !loading && listView.indexAt(listView.contentX, listView.contentY) > Math.max(0, listView.count - 20)) {
                Debug.log("[ChatInformationTabItemChatsBase] Trying to get more items...")
                loading = true
                loadMore(false)
                // keep loading as true forever if there's nothing more to load
            }
        }
        ViewPlaceholder {
            y: Theme.paddingLarge
            enabled: listView.count === 0
            text: placeholderText
        }

        VerticalScrollDecorator {}
    }

    Timer {
        id: loadedTimer
        // if we set it directly, the views start scrolling
        interval: 50
        onTriggered:
            tabBase.loading = false
    }

    Component.onCompleted:
        if (loadInitial) loadMore(true)
}
