//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    onAccepted: tdLibWrapper.getAndOpenSupportUser()

    Column {
        width: parent.width

        DialogHeader {
            title: qsTr("Ask a Question")
            acceptText: qsTr("Ask")
        }

        LinkedLabel {
            id: label
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            text: qsTr("Please note that Telegram Support is done by volunteers. We try to respond as quickly as possible, but it may take a while.

Please take a look at the %1Telegram FAQ%2: it has answers to most questions and important tips for %3troubleshooting%4.")
                .arg('<a href="' + qsTr("https://telegram.org/faq#general-questions", "Localized Telegram FAQ URL. Keep unfinished or as-is if not available for your language") + '">')
                .arg('</a>')
                .arg('<a href="' + qsTr("https://telegram.org/faq#troubleshooting", "Localized Telegram troubleshooting FAQ URL. Keep unfinished or as-is if not available for your language") + '">')
                .arg('</a>')
            wrapMode: Text.Wrap
        }
    }
}
