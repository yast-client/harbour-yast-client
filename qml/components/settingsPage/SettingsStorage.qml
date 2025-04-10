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
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0

AccordionItem {
    text: qsTr("Storage")
    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium
            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.onlineOnlyMode
                text: qsTr("Enable online-only mode")
                description: qsTr("Disables offline caching. Certain features may be limited or missing in this mode. Changes require a restart of Fernschreiber to take effect.")
                automaticCheck: false
                onClicked: {
                    appSettings.onlineOnlyMode = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.storageOptimizer
                text: qsTr("Enable storage optimizer")
                automaticCheck: false
                onClicked: {
                    appSettings.storageOptimizer = !checked
                }
            }

            Loader {
                id: statisticsLoader
                width: parent.columnWidth
                property var statistics
                property var fullStatistics
                sourceComponent: statistics||fullStatistics ? loadedComponent : loadingComponent
                onStatusChanged: if (status == Loader.Ready) {

                                     //height = item.height
                                     console.log(item.height, height)
                                 }
                height: item.height

                Component {
                    id: loadedComponent
                    Column {
                        width: parent.width
                        height: childrenRect.height
                        spacing: Theme.paddingLarge

                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width-2*x
                            text: qsTr("%1 <b>files</b>, <b>totalling</b> %2")
                                        .arg(statisticsLoader.fullStatistics ? statisticsLoader.fullStatistics.count : statisticsLoader.statistics.file_count)
                                        .arg(Format.formatFileSize(statisticsLoader.fullStatistics ? statisticsLoader.fullStatistics.count : statisticsLoader.statistics.files_size))
                                  + '<br>' + qsTr("<b>Local database size</b>: %1").arg(Format.formatFileSize(statisticsLoader.statistics.database_size))
                                  + '<br>' + qsTr("<b>TDLib log size</b>: %1").arg(Format.formatFileSize(statisticsLoader.statistics.log_size))
                                  + '<br>' + qsTr("<b>TDLib language pack database size</b>: %1").arg(Format.formatFileSize(statisticsLoader.statistics.language_pack_database_size))
                            wrapMode: Text.Wrap
                            Component.onCompleted: console.log("A",height)
                        }
                        ButtonLayout {
                            Button {
                                text: qsTr("Optimize storage")
                                onClicked: tdLibWrapper.optimizeStorage()
                            }
                            Button {
                                text: qsTr("Clear all cache")
                                color: Theme.errorColor
                                onClicked: tdLibWrapper.optimizeStorage(true)
                            }
                            Component.onCompleted: console.log("B",height)
                        }
                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width-2*x
                            font.pixelSize: Theme.fontSizeSmall
                            text: qsTr("Clearing all cache is not recommended, unless issues occur.")
                            color: Theme.secondaryColor
                            wrapMode: Text.Wrap
                            Component.onCompleted: console.log("C",height)
                        }
                        Component.onCompleted: console.log(height)
                    }
                }

                Component {
                    id: loadingComponent
                    BusyIndicator {
                        size: BusyIndicatorSize.Medium
                        anchors.horizontalCenter: parent ? parent.horizontalCenter : null
                    }
                }

                Connections {
                    target: tdLibWrapper
                    onStorageStatisticsFastReceived: statisticsLoader.statistics = statistics
                    onStorageStatisticsReceived: statisticsLoader.fullStatistics = statistics // After cache is cleared
                }
                Component.onCompleted: tdLibWrapper.getStorageStatisticsFast()
            }
        }
    }
}
