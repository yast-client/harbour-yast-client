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
import "../components"
import "../js/functions.js" as Functions
import "../js/twemoji.js" as Emoji

Dialog {
    id: newPollDialog
    allowedOrientations: Orientation.All

    property var chatId
    property string chatTitle
    property bool isChannel
    property var replyToMessageId
    property var topicId

    property alias pollQuestion: questionField.text
    property alias quiz: quizSwitch.checked
    property int openPeriod: 3600

    readonly property bool canAddOption: options.count < tdLibWrapper.options.poll_answer_count_max

    property bool acceptableOptionsLength
    property bool validationErrorsVisible: false
    property var validationErrors: [""]

    canAccept: questionField.acceptableInput && descriptionField.acceptableInput && (!quiz || explanationField.acceptableInput)
               && validationErrors.length === 0
    onAcceptBlocked: {
        questionField.errorHighlight = Qt.binding(function () { return !questionField.acceptableInput })
        descriptionField.errorHighlight = Qt.binding(function () { return !descriptionField.acceptableInput })
        explanationField.errorHighlight = Qt.binding(function () { return !explanationField.acceptableInput })
    }
    onAcceptPendingChanged: {
        if (acceptPending) {
            validate()

            if (validationErrors.length > 0) {
                validationErrorsVisible = true
                flickable.scrollToTop()
            }
        }
    }

    function validate() {
        var errors = []

        if (options.count < 2 || options.count > tdLibWrapper.options.poll_answer_count_max)
            errors.push(qsTr("A poll requires %1-%2 options.").arg(2).arg(tdLibWrapper.options.poll_answer_count_max))
        else {
            var hadError = false
            for (var i = 0; i < options.count; i++) {
                var len = options.get(i).text.length
                if (len < 1 || len > 100) {
                    hadError = true
                    break
                }
            }
            acceptableOptionsLength = !hadError
        }
        if (quiz) {
            var hadCorrect = false
            for (i = 0; i < options.count; i++)
                if (options.get(i).correct) {
                    hasCorrect = true
                    break
                }

            if (!hadCorrect)
                errors.push(qsTr("Please choose at least one correct answer"))
        }

        if(errors.length === 0) validationErrorsVisible = false
        validationErrors = errors
    }
    function createNewOption() {
        if (canAddOption) {
            options.append({text: '', correct: false})
            focusLastOptionTimer.start()
        }
    }

    signal focusOption(int focusIndex)

    ListModel {
        id: options
        ListElement {
            text: ''
            correct: false
        }
    }

    DialogHeader {
        id: header
        dialog: newPollDialog
        title: qsTr("New poll", "header")
    }

    Label {
        id: chatTitleLabel
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        anchors.verticalCenter: header.bottom

        color: Theme.secondaryHighlightColor
        wrapMode: Text.Wrap
        text: qsTr("in %1", "After dialog header… New Poll in [group name]").arg(Emoji.emojify(chatTitle, font.pixelSize))
        font.pixelSize: Theme.fontSizeSmall
    }

    SilicaFlickable {
        id: flickable
        clip: true
        width: parent.width
        anchors {
            top: chatTitleLabel.bottom
            bottom: parent.bottom
        }

        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
            topPadding: Theme.paddingLarge
            bottomPadding: Theme.paddingLarge

            Item {
                id: errorItem
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: newPollDialog.validationErrorsVisible ? errorColumn.height : 0
                clip: true
                opacity: newPollDialog.validationErrorsVisible ? 1 : 0
                Behavior on opacity { FadeAnimator {} }
                Behavior on height { NumberAnimation {}}
                Rectangle {
                    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                    anchors.fill: parent
                    radius: Theme.paddingLarge

                    IconButton {
                        icon.source: 'image://theme/icon-m-close'
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        onClicked:
                            newPollDialog.validationErrorsVisible = false
                    }
                }


                Column {
                    id: errorColumn
                    width: parent.width - Theme.paddingLarge * 2 - Theme.itemSizeSmall
                    spacing: Theme.paddingMedium
                    padding: Theme.paddingLarge
                    Repeater {
                        model: newPollDialog.validationErrors
                        delegate: Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.highlightColor
                            text: modelData
                            wrapMode: Text.Wrap
                            leftPadding: Theme.iconSizeSmall + Theme.paddingSmall
                            Icon {
                                highlighted: true
                                source: "image://theme/icon-s-high-importance"
                                y: Theme.paddingSmall / 2
                            }
                        }
                    }

                }
            }

            TextField {
                id: questionField
                label: qsTr("Question")
                placeholderText: qsTr("Enter your question here")
                property int charactersLeft: 255 - text.length
                description: errorHighlight && !text ? qsTr("You have to enter a question") : qsTr("%Ln characters left", '', charactersLeft)
                acceptableInput: !!text && charactersLeft >= 0
                wrapMode: TextEdit.Wrap
                onFocusChanged:
                    validate()
            }

            TextField {
                id: descriptionField
                label: qsTr("Description")
                property int charactersLeft: tdLibWrapper.options.message_caption_length_max - text.length
                description: qsTr("%Ln characters left", '', charactersLeft)
                acceptableInput: charactersLeft >= 0
                wrapMode: TextEdit.Wrap
                onFocusChanged:
                    validate()

            }

            SectionHeader {
                text: qsTr("Poll options", "Section header")
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                add: Transition {
                    FadeAnimator { from: 0; to: 1 }
                    NumberAnimation { properties: 'height'; from: 0; to: ViewTransition.item.childrenRect.height }
                }
                move: Transition {
                    NumberAnimation { properties: 'y' }
                }
                Behavior on height { NumberAnimation {} }

                Repeater {
                    model: options
                    delegate: Row {
                        width: parent.width

                        Switch {
                            id: correctSwitch
                            enabled: quiz
                            opacity: enabled ? 1 : 0
                            Behavior on opacity { FadeAnimator {} }
                            width: enabled ? implicitWidth : 0
                            Behavior on width { NumberAnimation {} }

                            automaticCheck: false
                            checked: model.correct
                            onCheckedChanged: {
                                options.get(index).correct = !checked
                                validate()
                            }
                        }

                        TextField {
                            id: optionField
                            width: parent.width - correctSwitch.width - Theme.itemSizeSmall
                            placeholderText: qsTr("Add an option")
                            property int charactersLeft: 100 - text.length
                            description: errorHighlight && !text ? qsTr("Option can't be empty") : qsTr("%Ln characters left", '', charactersLeft)
                            acceptableInput: !!text && charactersLeft >= 0
                            wrapMode: TextEdit.Wrap
                            onFocusChanged:
                                validate()

                            onTextChanged: {
                                options.get(index).text = text
                                newPollDialog.validate()
                            }

                            property bool hasNextOption: index < options.count - 1
                            EnterKey.iconSource: hasNextOption ? "image://theme/icon-m-enter-next" : (canAddOption ? "image://theme/icon-m-add" : "image://theme/icon-m-enter-close")
                            EnterKey.onClicked: {
                                if (hasNextOption)
                                    newPollDialog.focusOption(index + 1)
                                else if (canAddOption)
                                    newPollDialog.createNewOption()
                                else
                                    focus = false
                            }
                        }

                        Connections {
                            target: newPollDialog
                            onFocusOption:
                                if (focusIndex === index) optionField.forceActiveFocus()
                            onAcceptBlocked:
                                optionField.errorHighlight = Qt.binding(function () { return !optionField.acceptableInput })
                        }

                        IconButton {
                            icon.source: "image://theme/icon-m-remove"
                            onClicked: {
                                options.remove(index)
                                newPollDialog.validate()
                            }
                        }
                    }
                }
            }
            ButtonLayout {
                Button {
                    enabled: canAddOption
                    text: qsTr("Add an answer")
                    onClicked: {
                        newPollDialog.createNewOption()
                        newPollDialog.validate()
                    }
                }
            }
            Timer {
                id: focusLastOptionTimer
                interval: 20
                onTriggered:
                    newPollDialog.focusOption(options.count - 1)
            }

            SectionHeader {
                text: qsTr("Settings")
            }
            TextSwitch {
                id: anonymousSwitch
                visible: !isChannel
                text: qsTr("Anonymous answers")
            }
            TextSwitch {
                id: multipleSwitch
                text: qsTr("Multiple answers")
                checked: true
            }
            TextSwitch {
                id: allowAddingSwitch
                opacity: quiz ? 1 : 0
                Behavior on opacity { FadeAnimator {} }
                height: quiz ? implicitHeight : 0
                Behavior on height { NumberAnimation {} }
                text: qsTr("Allow adding options")
            }
            TextSwitch {
                id: revotingSwitch
                text: qsTr("Allow revoting")
                description: qsTr("Allow users to change their vote")
                checked: true
            }
            TextSwitch {
                id: shuffleSwitch
                text: qsTr("Shuffle options")
                description: qsTr("Make answer appear in random order")
            }

            TextSwitch {
                id: quizSwitch
                text: qsTr("Quiz Mode")
                description: qsTr("Mark one or more options as the correct answer")
                onCheckedChanged:
                    validate()
            }
            TextField {
                id: explanationField
                width: parent.width
                opacity: newPollDialog.quiz ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
                height: newPollDialog.quiz ? implicitHeight : 0
                Behavior on height { NumberAnimation { duration: explanationField.focus ? 0 : 200 } }
                visible: opacity > 0

                label: qsTr("Shown when the user selects a wrong answer.")
                placeholderText: qsTr("Enter an optional explanation")
                property int charactersLeft: 200 - text.length
                acceptableInput: charactersLeft >= 0
                description: qsTr("%Ln characters left", '', charactersLeft)

                wrapMode: TextEdit.Wrap
                onFocusChanged:
                    validate()
            }

            TextSwitch {
                id: openPeriodSwitch
                text: qsTr("Limit duration")
                description: qsTr("Automatically close the poll at a set time")
            }
            Column {
                width: parent.width
                opacity: openPeriodSwitch.checked ? 1 : 0
                Behavior on opacity { FadeAnimator {} }
                height: openPeriodSwitch.checked ? implicitHeight : 0
                Behavior on height { NumberAnimation {} }
                visible: opacity > 0

                ComboBox {
                    id: openPeriodComboBox
                    label: qsTr("Close in")

                    currentIndex: 0
                    value: currentIndex == 5
                           ? Format.formatDuration(duration)
                           : currentItem.text

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("1 hour")
                            readonly property int duration: 3600
                        }
                        MenuItem {
                            text: qsTr("3 hours")
                            readonly property int duration: 3*3600
                        }
                        MenuItem {
                            text: qsTr("8 hours")
                            readonly property int duration: 8*3600
                        }
                        MenuItem {
                            text: qsTr("1 day")
                            readonly property int duration: 62400
                        }
                        MenuItem {
                            text: qsTr("3 days")
                            readonly property int duration: 3*62400
                        }
                        MenuItem {
                            text: qsTr("Custom")
                        }
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex == 5) {
                            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/DurationPickerDialog.qml"), {
                                                            title: qsTr("Close poll in"),
                                                            maxDays: Math.floor(tdLibWrapper.options.poll_open_period_max / 62400)
                                                        })
                            dialog.accepted.connect(function() {
                                openPeriod = Math.min(dialog.allSeconds, tdLibWrapper.options.poll_open_period_max)
                            })
                        } else
                            openPeriod = currentItem.duration
                    }
                }

                TextSwitch {
                    id: hideResultsUntilClosesSwitch
                    text: qsTr("Hide results")
                    description: qsTr("Hide results until the poll closes")
                }
            }
        }
    }

    onAccepted: {
        var optionsArr = []
        var correctOptionIds = []

        for (var i = 0; i < options.count; i++) {
            var option = options.get(i)

            optionsArr.push(option.text)
            if (option.correct)
                correctOptionIds.push(i)
        }

        tdLibWrapper.sendPollMessage(chatId, pollQuestion, optionsArr, descriptionField.text,
                                     anonymousSwitch.checked, multipleSwitch.checked, revotingSwitch.checked, shuffleSwitch.checked,
                                     openPeriodSwitch.checked ? openPeriod : 0, hideResultsUntilClosesSwitch.checked,
                                     allowAddingSwitch.checked && !quiz, quiz ? correctOptionIds : [], explanationField.text,
                                     replyToMessageId, topicId)
    }
}
