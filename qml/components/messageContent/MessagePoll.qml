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
import io.libfernie 1.0
import "../../modules/Opal/FancyMenus"
import '../../pages'
import '..'

import "../../js/functions.js" as Functions
import "../../js/twemoji.js" as Emoji

MessageContentBase {
    id: pollMessageComponent
    height: pollColumn.height

    readonly property var chatId: rawMessage.chat_id
    readonly property var messageId: rawMessage.id
    readonly property var pollData: rawMessage.content.poll
    property var chosenPollData: ({})
    property var chosenIndexes: []
    readonly property bool hasAnswered: pollData.options.filter(function(option){ return option.is_chosen }).length > 0
    readonly property bool canAnswer: !hasAnswered && !pollData.is_closed
    readonly property bool isQuiz: pollData.type['@type'] === 'pollTypeQuiz'
    property list<Item> extraContextMenuItems: [
        FancyMenuRow {
            property bool canEdit
            function processProperties(properties) { canEdit = !!properties.can_be_edited }
            IconTextRowMenuItem {
                visible: !pollData.is_closed && canEdit
                text: qsTr("Stop poll")
                onClicked: tdLibWrapper.stopPoll(pollMessageComponent.chatId, pollMessageComponent.messageId)
            }
            IconTextRowMenuItem {
                visible: !pollData.is_closed && !pollMessageComponent.isQuiz && pollMessageComponent.hasAnswered
                text: qsTr("Retract vote")
                onClicked: {
                    chosenIndexes = []
                    sendResponse()
                }
            }
        }
    ]

    function sendResponse() {
        tdLibWrapper.setPollAnswer(chatId, messageId, chosenIndexes)
    }
    function handleChoose(index) {
        if (!pollData.allows_multiple_answers) {
            chosenIndexes = [index]
            sendResponse()
            return
        }

        var found = chosenIndexes.indexOf(index)
        if (found > -1) // uncheck
            chosenIndexes.splice(found, 1)
        else
            chosenIndexes.push(index)
        chosenIndexesChanged()
    }

    Component.onCompleted:
        if (!hasAnswered)
            chosenIndexes = pollData.options.filter(function(option){ return option.is_being_chosen })

    Component {
        id: pollResultsPageComponent
        PollResultsPage {
            // don't pass theses as properties to pageStack.push so if rawMessage is updated, it would be updated here too
            chatId: pollMessageComponent.chatId
            message: pollMessageComponent.rawMessage
        }
    }

    Column {
        id: pollColumn
        width: parent.width
        spacing: Theme.paddingSmall

        Row {
            width: parent.width
            layoutDirection: isOwnMessage ? Qt.RightToLeft : Qt.LeftToRight

            Column {
                width: parent.width - pollDurationRow.width
                bottomPadding: pollMessageComponent.canAnswer ? Theme.paddingSmall : 0

                Label {
                    width: parent.width
                    text: Emoji.emojify(Functions.enhanceMessageText(pollData.question), Theme.fontSizeSmall)
                    visible: !!text
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                }

                Row {
                    spacing: Theme.paddingMedium

                    Label {
                        width: recentVotersList.visible
                               ? Math.min(implicitWidth, parent.width - (recentVotersList.visible ? recentVotersList.width + parent.spacing : 0))
                               : implicitWidth
                        visible: !!text
                        text: pollData.is_closed ? qsTr("Final results") : (isQuiz
                                                                            ? (pollData.is_anonymous ? qsTr("Anonymous Quiz") : qsTr("Quiz"))
                                                                            : (pollData.is_anonymous ? qsTr("Anonymous Poll") : qsTr("Poll")))
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                        color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }

                    RecentActorsList {
                        id: recentVotersList
                        width: implicitWidth + (recentVotersButton.visible ? recentVotersButton.width : 0)
                        model: pollData.recent_voter_ids.reverse()
                        inverted: true
                        visible: count > 0 || recentVotersButton.visible
                        height: Theme.iconSizeSmallPlus
                        paddingDifference: Theme.iconSizeSmall
                        highlighted: recentVotersMouseArea.containsPress

                        Icon {
                            id: recentVotersButton
                            anchors.right: parent.right
                            width: parent.height
                            height: width
                            visible: !!pollData.can_get_voters && recentVotersList.count == 0
                            source: 'image://theme/icon-m-media-artists'
                            highlighted: parent.highlighted
                            Icon {
                                width: Theme.iconSizeExtraSmall
                                height: width
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                }
                                opacity: 0.8
                                source: 'image://theme/icon-s-maybe'
                                highlighted: parent.highlighted
                            }
                        }

                        MouseArea {
                            id: recentVotersMouseArea
                            anchors.fill: parent
                            onClicked: pageStack.push(pollResultsPageComponent)
                        }
                    }
                }

                Label {
                    width: parent.width
                    text: Emoji.emojify(Functions.enhanceMessageText(rawMessage.description), Theme.fontSizeSmall)
                    visible: !!text
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }
            }

            Row {
                id: pollDurationRow
                opacity: pollData.close_date && !!pollDurationLabel.text ? 1 : 0
                Behavior on opacity { FadeAnimator {} }
                width: opacity == 1 ? childrenRect.width : 0
                Behavior on width { NumberAnimation { duration: 200 } }
                layoutDirection: parent.layoutDirection
                spacing: Theme.paddingSmall

                Label {
                    id: pollDurationLabel
                    font.pixelSize: Theme.fontSizeMedium
                    text: Functions.getDurationToFuture(pollData.close_date)
                    color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter

                    Timer {
                        interval: 1000
                        running: pollDurationRow.visible
                        repeat: true
                        onTriggered:
                            pollDurationLabel.text = Functions.getDurationToFuture(pollData.close_date)
                    }
                }

                Icon {
                    source: "image://theme/icon-m-timer"
                    color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        Component {
            id: canAnswerDelegate
            TextSwitch {
                id: optionDelegate
                width: pollMessageComponent.width
                automaticCheck: false
                text: Emoji.emojify(Functions.enhanceMessageText(modelData.text), Theme.fontSizeMedium)
                checked: pollMessageComponent.chosenIndexes.indexOf(index) > -1
                busy: checked && modelData.is_being_chosen
                highlighted: pollMessageComponent.highlighted || down
                onClicked: handleChoose(index)
            }
        }

        Component {
            id: resultDelegate
            Row {
                id: optionDelegate
                height: Math.max(Theme.itemSizeExtraSmall, implicitHeight)

                Item {
                    height: parent.height
                    width: Theme.horizontalPageMargin/2
                    anchors.bottom: parent.bottom

                    Rectangle {
                        id: displayOptionChosenMarker
                        anchors.fill: parent
                        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                        visible: modelData.is_chosen
                    }

                    OpacityRampEffect {
                        sourceItem: displayOptionChosenMarker
                        direction: OpacityRamp.LeftToRight
                    }
                }

                Item {
                    width: Theme.paddingMedium + (pollMessageComponent.isQuiz ? Theme.iconSizeSmall : 0)
                    height: correctAnswerIcon.height
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: (votePercentageBar.height - height)/2
                    }
                    Icon {
                        id: correctAnswerIcon
                        anchors.bottom: parent.bottom
                        highlighted: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted
                        readonly property bool isRight: pollMessageComponent.isQuiz && pollData.type.correct_option_id === index
                        source: "image://theme/icon-s-accept"
                        visible: isRight
                    }
                }

                Column {
                    width: list.width - x
                    anchors.bottom: parent.bottom

                    Item {
                        width: parent.width
                        height: Math.max(voteTextLabel.height, votePercentageLabel.y + votePercentageLabel.height)

                        Label {
                            id: voteTextLabel
                            property int lastLineWidth
                            width: parent.width
                            text: Emoji.emojify(Functions.enhanceMessageText(modelData.text), Theme.fontSizeMedium)
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            onTextChanged: lastLineWidth = 0
                            onLineLaidOut: {
                                if (line.isLast) {
                                    lastLineWidth = line.x + line.implicitWidth
                                }
                            }
                        }

                        Label {
                            id: votePercentageLabel
                            y: (voteTextLabel.lastLineWidth + Theme.paddingLarge) > x ? voteTextLabel.height : Math.max(0, voteTextLabel.height - height)
                            font.pixelSize: Theme.fontSizeTiny
                            text: qsTr("%Ln\%", "% of votes for option", modelData.vote_percentage)
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                            color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }

                    Rectangle {
                        id: votePercentageBar
                        height: Theme.paddingSmall
                        width: parent.width
                        color: Theme.rgba(pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor, 0.3)
                        radius: height/2
                        Rectangle {
                            height: parent.height
                            color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            radius: height/2
                            width: parent.width * modelData.vote_percentage * 0.01
                        }
                    }
                }
            }
        }

        Repeater {
            id: list
            model: pollData.options
            x: -Theme.horizontalPageMargin/2
            width: parent.width - x
            delegate: pollMessageComponent.canAnswer ? canAnswerDelegate : resultDelegate
        }

        Item {
            width: 1
            height: Theme.paddingSmall
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            visible: isQuiz && text.length > 0
            text: Emoji.emojify(Functions.enhanceMessageText(pollData.type.explanation) || "", font.pixelSize)
            textFormat: Text.StyledText
            color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.highlightColor : Theme.primaryColor
            linkColor: Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraSmall
            leftPadding: Theme.iconSizeSmall
            bottomPadding: Theme.paddingSmall
            Icon {
                source: "image://theme/icon-s-high-importance"
                asynchronous: true
                width: Theme.iconSizeExtraSmall
                height: Theme.iconSizeExtraSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Label {
            font.pixelSize: Theme.fontSizeTiny
            anchors.right: parent.right
            text: qsTr("%Ln vote(s) total", "number of total votes", pollData.total_voter_count)
            horizontalAlignment: Text.AlignRight
            color: pollMessageComponent.isOwnMessage || pollMessageComponent.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }

        SecondaryButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !!pollData.allows_multiple_answers && !pollData.is_closed && !pollMessageComponent.hasAnswered
            enabled: pollMessageComponent.chosenIndexes.length > 0
            text: qsTr("Vote")
            icon.source: 'image://theme/icon-m-send'
            onClicked: sendResponse()
        }
    }
}
