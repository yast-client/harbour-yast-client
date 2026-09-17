//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    canAccept: clearShippingSwitch.checked || clearPaymentSwitch.checked
    onAccepted: {
        if (clearShippingSwitch.checked) tdLibWrapper.deleteSavedOrderInfo()
        if (clearPaymentSwitch.checked) tdLibWrapper.deleteSavedCredentials()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Clear payment info")
                acceptText: qsTr("Clear")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Delete your shipping info and instruct all payment providers to remove your saved credit cards? Note that Telegram never stores your credit card data.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
            }

            TextSwitch {
                id: clearShippingSwitch
                text: qsTr("Shipping info")
                checked: true
            }
            TextSwitch {
                id: clearPaymentSwitch
                text: qsTr("Payment info")
                checked: true
            }
        }
    }
}
