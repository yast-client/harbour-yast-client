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
import App.Logic 1.0

AccordionItem {
    name: "storage"
    title: qsTr("Storage")
    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium
            TextSwitch {
                width: parent.columnWidth
                checked: appSettings.onlineOnlyMode
                text: qsTr("Enable online-only mode")
                description: qsTr("Disables offline caching. Certain features may be limited or missing in this mode. Changes require a restart of Ferniegram to take effect.")
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
                sourceComponent: statistics || fullStatistics ? loadedComponent : loadingComponent
                height: item ? item.height : 0

                Component {
                    id: loadedComponent
                    Column {
                        width: parent.width
                        height: childrenRect.height
                        spacing: Theme.paddingLarge

                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width-2*x
                            text: qsTr("<b>%Ln</b> files, totalling <b>%1</b>", '', statisticsLoader.fullStatistics ? statisticsLoader.fullStatistics.count : statisticsLoader.statistics.file_count)
                                  .arg(Format.formatFileSize(statisticsLoader.fullStatistics ? statisticsLoader.fullStatistics.count : statisticsLoader.statistics.files_size))
                                  + '<br>' + qsTr("Local database size: <b>%1</b>").arg(Format.formatFileSize(statisticsLoader.statistics.database_size))
                                  + '<br>' + qsTr("TDLib log size: <b>%1</b>").arg(Format.formatFileSize(statisticsLoader.statistics.log_size))
                                  + '<br>' + qsTr("TDLib language pack database size: <b>%1</b>").arg(Format.formatFileSize(statisticsLoader.statistics.language_pack_database_size))
                            wrapMode: Text.Wrap
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
                        }
                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width-2*x
                            font.pixelSize: Theme.fontSizeSmall
                            text: qsTr("Clearing all cache is not recommended, unless issues occur.")
                            color: Theme.secondaryColor
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Component {
                    id: loadingComponent
                    BusyIndicator {
                        height: implicitHeight
                        width: implicitWidth
                        running: true
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
