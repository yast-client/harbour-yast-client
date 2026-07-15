//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import io.yaqtlib 1.0
import "../js/functions.js" as Functions

Page {
    id: page

    property bool currentSoundUnavailable
    property string currentSoundId

    signal selected(string soundId)

    SilicaListView {
        id: soundsListView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Upload Sound", "Upload a new sound")
                onClicked: {
                    var page = pageStack.push('Sailfish.Pickers.MusicPickerPage')
                    page.selectedContentPropertiesChanged.connect(function () {
                        tdLibWrapper.addSavedNotificationSound(page.selectedContentProperties.filePath)
                    })
                }
            }
        }

        header: Column {
            width: parent.width

            PageHeader { title: qsTr("Sound", "Page header") }

            Repeater {
                model: 2
                BackgroundItem {
                    id: defaultSoundBackgroundItem
                    height: Theme.itemSizeMedium

                    Label {
                        id: defaultLabel
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        text: index == 0 ? qsTr("Default", "Sound") : qsTr("Disabled", "Sound")
                        highlighted: defaultSoundBackgroundItem.highlighted || (currentSoundUnavailable && (index == 0 ? (currentSoundId != '0') : (currentSoundId == '0')))
                    }

                    onClicked: {
                        var soundId = index == 0 ? '-1' : '0'
                        if (currentSoundId !== soundId)
                            selected(soundId)
                    }
                }
            }
        }

        delegate: ListItem {
            id: soundListItem
            contentHeight: Theme.itemSizeMedium

            Column {
                id: column
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x - (progressCircle.opacity > 0 ? (progressCircle.width + Theme.paddingLarge) : 0)
                anchors.verticalCenter: parent.verticalCenter

                Flow {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Label {
                        id: mainLabel
                        width: Math.min(implicitWidth, parent.width)
                        wrapMode: Text.Wrap
                        highlighted: soundListItem.highlighted || modelData.id === currentSoundId
                        text: modelData.title
                    }

                    Label {
                        highlighted: mainLabel.highlighted
                        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        text: Format.formatDuration(modelData.duration)
                    }
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    highlighted: mainLabel.highlighted
                    color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    wrapMode: Text.Wrap
                    text: Functions.getDateTimeTimepoint(modelData.date)
                }
            }

            ProgressCircle {
                id: progressCircle
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }

                opacity: file.isDownloadingActive ? 1 : 0
                Behavior on opacity { FadeAnimator {} }
            }

            TDLibFile {
                id: file
                fileInformation: modelData.sound
            }

            Audio {
                id: audioPlayer
                source: file.isDownloadingCompleted ? file.path : ''
                autoPlay: false
            }

            onClicked:
                if (currentSoundId === modelData.id) {
                    if (file.isDownloadingCompleted) {
                        if (audioPlayer.playbackState === Audio.PlayingState)
                            audioPlayer.stop()
                        audioPlayer.play()
                    } else if (file.isDownloadingActive) {
                        audioPlayer.autoPlay = false
                        file.cancel()
                    } else {
                        audioPlayer.autoPlay = true
                        file.load()
                    }
                } else
                    selected(modelData.id)

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: tdLibWrapper.removeSavedNotificationSound(modelData.id)
                    }
                }
            }
        }

        Connections {
            target: tdLibWrapper
            onNotificationSoundsReceived:
                soundsListView.model = sounds
            onSavedNotificationSoundsUpdated:
                tdLibWrapper.getSavedNotificationSounds()
            onNotificationSoundReceived:
                if (extra == 'localSaved')
                    selected(soundId)
        }

        Component.onCompleted: tdLibWrapper.getSavedNotificationSounds()
    }
}
