//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0

AccordionItem {
    name: "storage"
    title: qsTr("Data and Storage")
    Component {
        ResponsiveGrid {
            bottomPadding: Theme.paddingMedium
            TextSwitch {
                width: parent.columnWidth
                checked: yaqtSettings.onlineOnlyMode
                text: qsTr("Enable online-only mode")
                description: qsTr("Disables offline caching. Certain features may be limited or missing in this mode. Changes require a restart of the app to take effect.")
                automaticCheck: false
                onClicked: {
                    yaqtSettings.onlineOnlyMode = !checked
                }
            }

            TextSwitch {
                width: parent.columnWidth
                checked: yaqtSettings.storageOptimizer
                text: qsTr("Enable storage optimizer")
                automaticCheck: false
                onClicked: {
                    yaqtSettings.storageOptimizer = !checked
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

            ButtonLayout {
                width: parent.columnWidth
                Button {
                    text: qsTr("Proxy settings")
                    onClicked: pageStack.push(Qt.resolvedUrl("../../pages/ProxiesPage.qml"))
                }
            }
        }
    }
}
