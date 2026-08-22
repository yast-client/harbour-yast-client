//@ SPDX-FileCopyrightText: 2026 roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

FullscreenHintDialog {
    header.cancelText: qsTr("Back to Messages")
    header.acceptText: qsTr("Proceed")
    largeIcon: Qt.resolvedUrl("../../images/icon-l-experimental.svg")
    title: qsTr("Beta Notice")
    description: qsTr("Forum topics are currently a %1beta feature%2").arg('<b>').arg('</b>')
    cards: [
        {icon: 'image://theme/icon-m-accept', title: qsTr("Basics Already Work"), description: qsTr("You can already switch between topics, as well as view and send messages in them")},
        {icon: 'image://theme/icon-m-back', title: qsTr("Viewing as Messages"), description: qsTr("When a feature you want to use is not yet available for forum topics, you can always switch back to the whole chat view by pulling down to return to the older behavior")},
        {
            icon: 'image://theme/icon-m-developer-mode', title: qsTr("Help the Development"),
            description: qsTr("If you find a bug, submit it %1on GitHub%2. Make sure to check %4existing issues%3 first to avoid creating duplicates. React to issues you think are the most critical to make them more recognizeable and faster to get fixed.")
                .arg('<a href="%1">'.arg('https://github.com/yast-client/harbour-yast-client/issues/new?labels=forum+topics')).arg('</a>')
                .arg('</a>').arg('<a href="%1">'.arg('https://github.com/yast-client/harbour-yast-client/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22forum%20topics%22'))
        },
    ]

    onAccepted: hintsConfig.topicsBetaNoticeCompleted = true
}
