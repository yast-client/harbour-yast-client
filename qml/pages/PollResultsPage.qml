import QtQuick 2.6
import Sailfish.Silica 1.0
import '../components'
import '../components/tdlib'
import '../js/functions.js' as Functions
import '../js/twemoji.js' as Emoji
import '../js/debug.js' as Debug

Page {
    id: pollResultsPage
    allowedOrientations: Orientation.All

    property var chatId
    property var message: ({})
    property var messageId: message.id
    property var pollData: message.content.poll
    property bool isQuiz: pollData.type['@type'] === 'pollTypeQuiz'
    property bool hasAnswered: pollData.options.filter(function(option) { return option.is_chosen }).length > 0

    property bool canAnswer: !hasAnswered && !pollData.is_closed
    onCanAnswerChanged:
        if (canAnswer) pageStack.pop() // vote removed from another client

    PageHeader {
        id: pageHeader
        title: pollResultsPage.isQuiz ? qsTr("Quiz Results") : qsTr("Poll Results")
        description: qsTr("%Ln vote(s) total", "number of total votes", pollData.total_voter_count)
        leftMargin: headerPictureThumbnail.width + Theme.paddingLarge + Theme.horizontalPageMargin
    }

    SilicaFlickable {
        id: flickable
        width: parent.width
        anchors {
            top: pageHeader.bottom
            bottom: parent.bottom
        }
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                text: Emoji.emojify(Functions.enhanceMessageText(pollData.question), font.pixelSize)
            }

            Column {
                id: resultsColumn
                width: parent.width
                topPadding: Theme.paddingLarge
                bottomPadding: Theme.paddingLarge

                SectionHeader {
                    text: qsTr("Results", "section header")
                }

                Repeater {
                    model: pollData.options
                    Item {
                        id: optionDelegate
                        x: Theme.horizontalPageMargin
                        width: parent.width - x
                        height: optionColumn.height

                        ListModel { id: votersModel }

                        property string optionExtra: pollResultsPage.chatId+':'+pollResultsPage.messageId+':'+index
                        property int totalCount: modelData.voter_count
                        property bool isCorrectOption: pollResultsPage.isQuiz && pollData.type.correct_option_id === index

                        function loadVoters() {
                            tdLibWrapper.getPollVoters(pollResultsPage.chatId, pollResultsPage.messageId, index, optionExtra, votersModel.count)
                        }

                        Timer {
                            id: loadVotersTimer
                            interval: index * 80
                            running: true
                            onTriggered:
                                if (votersModel.count < modelData.voter_count)
                                    loadVoters()
                        }

                        Connections {
                            target: tdLibWrapper
                            onPollVotersReceived: {
                                if (extra === optionDelegate.optionExtra) {
                                    Debug.log("Received poll voters")
                                    for (var i = 0; i < voters.length; i++)
                                        votersModel.append(voters[i])
                                    optionDelegate.totalCount = totalCount
                                    showMoreButton.enabled = true
                                }
                            }
                        }

                        Rectangle {
                            id: displayOptionChosenMarker
                            height: parent.height
                            width: Theme.horizontalPageMargin/2
                            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                            visible: modelData.is_chosen
                            x: -width
                        }
                        OpacityRampEffect {
                            sourceItem: displayOptionChosenMarker
                            direction: OpacityRamp.LeftToRight
                        }

                        Column {
                            id: optionColumn
                            anchors {
                                left: displayOptionChosenMarker.right
                                right: parent.right
                            }
                            spacing: Theme.paddingMedium

                            Label {
                                id: displayOptionLabel
                                width: parent.width
                                text: Emoji.emojify(Functions.enhanceMessageText(modelData.text), Theme.fontSizeMedium)
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                color: Theme.highlightColor

                                leftPadding: Theme.paddingMedium*2 + correctOptionIcon.width
                                rightPadding: Theme.horizontalPageMargin
                                Icon {
                                    id: correctOptionIcon
                                    source: "image://theme/icon-s-accept"
                                    highlighted: true
                                    visible: optionDelegate.isCorrectOption
                                    width: visible ? Theme.iconSizeSmall : 0
                                    anchors {
                                        leftMargin: Theme.paddingMedium
                                        verticalCenter: parent.verticalCenter
                                    }
                                }

                                // TODO: implement something like section.labelPositioning = ViewSection.CurrentLabelAtStart in ListView
                                /*y: (optionDelegate.y <= flickable.contentY && optionDelegate.y + optionDelegate.height > flickable.contentY)
                                   //? mapFromItem(contentColumn, 0, flickable.contentY).y
                                   ? flickable.contentY - resultsColumn.y - optionDelegate.y
                                   : 0*/
                            }

                            Item {
                                id: displayOptionStatistics
                                anchors {
                                    left: parent.left
                                    leftMargin: displayOptionLabel.leftPadding
                                    rightMargin: Theme.horizontalPageMargin
                                    right: parent.right
                                }

                                height: optionVoterPercentage.height + optionVoterPercentageBar.height

                                Label {
                                    id: optionVoterCount
                                    font.pixelSize: Theme.fontSizeTiny
                                    text: modelData.is_chosen ? qsTr("%Ln vote(s) including yours", "number of votes for option", modelData.voter_count) : qsTr("%Ln vote(s)", "number of votes for option", modelData.voter_count)
                                    anchors {
                                        left: parent.left
                                        right: parent.horizontalCenter
                                        rightMargin: Theme.paddingSmall
                                    }
                                    color: Theme.secondaryHighlightColor
                                }
                                Label {
                                    id: optionVoterPercentage
                                    font.pixelSize: Theme.fontSizeTiny
                                    text: qsTr("%Ln\%", "% of votes for option", modelData.vote_percentage)
                                    horizontalAlignment: Text.AlignRight
                                    anchors {
                                        right: parent.right
                                        left: parent.horizontalCenter
                                        leftMargin: Theme.paddingSmall
                                    }
                                    color: Theme.secondaryHighlightColor
                                }
                                Rectangle {
                                    id: optionVoterPercentageBar
                                    height: Theme.paddingSmall
                                    width: parent.width

                                    color: Theme.rgba(Theme.secondaryHighlightColor, 0.3)
                                    radius: height/2
                                    anchors {
                                        left: parent.left
                                        bottom: parent.bottom
                                    }

                                    Rectangle {
                                        height: parent.height
                                        color: Theme.highlightColor
                                        radius: height/2
                                        width: parent.width * modelData.vote_percentage * 0.01
                                    }
                                }
                            }

                            ColumnView {
                                width: parent.width
                                model: votersModel
                                itemHeight: Theme.itemSizeMedium
                                clip: true

                                delegate: TDLibChatListItem {
                                    leftMargin: Theme.paddingMedium
                                    contentHeight: Theme.itemSizeMedium
                                    pictureThumbnailItem.height: Theme.itemSizeSmall
                                    messageSender: voter_id
                                    showFullInfo: false
                                    prologSecondaryText.text: ''
                                    secondaryText.text: Functions.getDateTimeTimepoint(date)
                                    secondaryText.color: Theme.secondaryColor
                                }
                            }

                            Button {
                                id: showMoreButton
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("Show %Ln more", "Button to show %Ln more poll voters", optionDelegate.totalCount - votersModel.count)
                                visible: votersModel.count < optionDelegate.totalCount
                                onClicked: {
                                    enabled = false
                                    loadVoters()
                                }
                            }
                        }

                    }
                }

            }

        }

        VerticalScrollDecorator {}
    }
}
