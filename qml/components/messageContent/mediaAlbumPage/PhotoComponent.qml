//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6

ZoomImage {
    photoData: _model.content.photo
    onClicked:
        if (zoomed) {
            zoomOut(true)
            page.overlayActive = true
        } else
            page.overlayActive = !page.overlayActive
}
