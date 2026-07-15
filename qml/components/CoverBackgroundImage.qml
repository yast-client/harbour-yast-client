//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0

Icon {
    anchors.fill: parent
    source: Qt.resolvedUrl('../../images/cover-background.svg')
    color: Theme.colorPrimary
    opacity: 0.15
    sourceSize {
        width: width
        height: height
    }
}