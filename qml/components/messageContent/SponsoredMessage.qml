/*
    Copyright (C) 2021 Sebastian J. Wolf and other contributors

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
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import "../"
import "../../js/functions.js" as Functions

Column {
    id: sponsoredMessageColumn

    property var message

    Connections {
        target: tdLibWrapper
        onMessageLinkInfoReceived: {
            if (message.link.url === url) {
                messageOverlayLoader.overlayMessage = messageLinkInfo.message
                messageOverlayLoader.active = true
            }
        }
    }

    Button {
        id: sponsoredMessageButton
        anchors.horizontalCenter: parent.horizontalCenter

        text: message ? message.button_text : ''
        onClicked: {
            if (Functions.isDirectMessageLink(message.sponsor.url))
                tdLibWrapper.getMessageLinkInfo(message.sponsor.url)
            else Functions.handleLink(message.sponsor.url)
        }
    }

}
