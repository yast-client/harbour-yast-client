//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

MessageCall {
    text: utilities.getMessageGroupCallText(rawMessage.content, rawMessage.is_outgoing)
    defaultOnClicked: false
}
