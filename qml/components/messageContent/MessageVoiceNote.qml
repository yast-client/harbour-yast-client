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

MessageAudio {
    id: message
    fileInformation: rawMessage.content.voice_note.voice
    primaryText: qsTr("Voice Note")
    secondaryText: ""
    duration: rawMessage.content.voice_note.duration
    thumbnail: null
    minithumbnail: null

    Row {
        id: background

        parent: slider
        // extra painting margins (Theme.paddingMedium on both sides) are needed,
        // because glass item doesn't visibly paint across the full width of the item
        x: slider.leftMargin-slider._glassItemPadding
        width: slider._grooveWidth + 2*slider._glassItemPadding
        y: slider._extraPadding + slider._backgroundTopPadding
        height: Theme.itemSizeSmall

        property var color: slider.highlighted ? slider.secondaryHighlightColor : slider.backgroundColor

        readonly property real itemWidth: Theme.paddingSmall
        spacing: Theme.paddingSmall
        property var waveform: fernschreiberUtils.getWaveformData(rawMessage.content.voice_note.waveform, (width + spacing) / (itemWidth + spacing))
        Repeater {
            model: parent.waveform.length
            Rectangle {
                color: parent.color
                width: parent.itemWidth
                height: parent.height * parent.waveform[index]
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component.onCompleted: {
        slider._backgroundItem.visible = false
        slider._progressBarItem.visible = false
        slider._highlightItem.visible = false

        progressBarProxy.height = slider._progressBarItem.height

        slider._backgroundItem = background
        slider._progressBarItem = progressBarProxy
        slider._highlightItem = highlight
    }

    Row {
        id: progressBar

        parent: slider
        x: background.x
        width: progressBarProxy.width
        height: background.height
        visible: slider.sliderValue > slider.minimumValue
        anchors.verticalCenter: background.verticalCenter
        z: 1
        clip: true

        property color color: slider.highlighted ? slider.highlightColor : slider.color

        readonly property real itemWidth: Theme.paddingSmall
        spacing: Theme.paddingSmall
        Repeater {
            model: background.waveform.length
            Rectangle {
                color: parent.color
                width: parent.itemWidth
                height: parent.height * background.waveform[index]
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        id: progressBarProxy
        visible: false
        width: slider._progressBarWidth
    }

    GlassItem {
        id: highlight

        x: slider._highlightX
        width: Theme.itemSizeMedium
        height: background.height
        visible: slider.handleVisible && background.visible
        z: 2
        radius: 0.17
        falloffRadius: 0.20
        anchors.verticalCenter: background.verticalCenter
        dimmed: true
        color: slider.highlighted ? slider.highlightColor : slider.color
        backgroundColor: slider.backgroundGlowColor
        onXChanged: {
            console.log(slider.leftMargin + slider._highlightPadding - slider._highlightItem.width/2
                        + (slider.maximumValue > slider.minimumValue
                           ? (slider.sliderValue - slider.minimumValue) / (slider.maximumValue - slider.minimumValue)
                             * (slider._grooveWidth - 2 * slider._highlightPadding)
                           : 0), slider._progressBarItem.width, slider.leftMargin, slider._highlightPadding, (slider.sliderValue - slider.minimumValue) / (slider.maximumValue - slider.minimumValue), slider._grooveWidth)
        }
    }
}
