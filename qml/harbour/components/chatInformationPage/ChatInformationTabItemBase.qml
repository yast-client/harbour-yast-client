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
import "../../pages"
import "../"
import "../../modules/Opal/Tabs"

TabItem {
    id: tabItem
    property bool loading
    //overrideable:
    property alias loadingVisible: busyLabel.running
    property alias loadingText: busyLabel.text

    property int tabIndex: index
    property bool tabActive: index === tabView.currentIndex
    property bool active: Qt.application.active && chatInformationPage.status === PageStatus.Active && tabActive

    BusyLabel {
        id: busyLabel
        running: tabItem.loading
        visible: tabItem.loading
    }
}
