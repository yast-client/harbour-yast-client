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
import "pages"
import "components"
import "./js/functions.js" as Functions
import WerkWolf.Fernschreiber 1.0

ApplicationWindow {
    id: appWindow

    initialPage: Qt.resolvedUrl("pages/OverviewPage.qml")
    cover: Qt.resolvedUrl("pages/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Connections {
        target: dBusAdaptor
        onPleaseOpenMessage: appWindow.activate()
        onPleaseOpenUrl: appWindow.activate()
    }

    Connections {
        target: tdLibWrapper
        onOpenFileExternally: Qt.openUrlExternally(filePath)
        onTgUrlFound: Functions.handleLink(tgUrl)
        onErrorReceived: Functions.handleErrorMessage(code, message, extra)
        onServiceNotificationReceived: appNotification.show(utilities.getMessageContentText(content, true))
    }

    AppNotification {
        id: appNotification
        parent: contentItem
        layoutMaxWidth: orientation & Orientation.LandscapeMask ? parent.height : parent.width
        rotation: switch (appWindow.orientation) {
                      // 90 * (appWindow.orientation-1) would work, but it can break
                  case Orientation.Portrait: return 0
                  case Orientation.Landscape: return 90
                  case Orientation.PortraitInverted: return 180
                  case Orientation.LandscapeInverted: return 270
                  }
    }

    Component {
        id: tdlibFileComponent
        TDLibFile {
            tdlib: tdLibWrapper
            autoLoad: true
        }
    }

    Component.onCompleted: {
        Functions.setGlobals({
            tdLibWrapper: tdLibWrapper,
            appNotification: appNotification,
            utilities: utilities,
        })
    }
}
