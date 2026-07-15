//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../js/functions.js" as Functions

Grid {
    width: parent.width - ( 2 * x )
    columns: Functions.isWidescreen(appWindow) ? 2 : 1
    readonly property real columnWidth: width/columns
}
