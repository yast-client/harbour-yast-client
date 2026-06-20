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
import io.yaqtlib 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: debugPage
    allowedOrientations: Orientation.All

    property var overviewPage

    function showResult(res) {
        customDataLabel.text = res
    }
    function showJsonResult(res) {
        showResult(JSON.stringify(res, null, '\t'))
    }

    SilicaFlickable {
        id: aboutContainer
        contentHeight: column.height
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: "Destroy TDLib instance"
                onClicked: tdLibWrapper.destroyInstance()
            }
            MenuItem {
                text: "Reopen TDLib instance"
                onClicked: tdLibWrapper.close()
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: "Debug Page"
                description: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady
                             ? "description"
                             : ('<font color="%1">Warning</color>: '.arg(Theme.highlightColor)
                                + "You are not currently unauthorized. Certain feautres, including but not limited to opening chats and translating, are unlikely to work in this state.")
                descriptionWrapMode: Text.Wrap
            }

            SectionHeader { text: "Settings" }

            ButtonLayout {
                Button {
                    text: "Reset hints"
                    onClicked: {
                        appConfig.remainingInteractionHints = appConfig.remainingDoubleTapHints = 3
                        appConfig.archiveChatListHintCompleted = appConfig.welcomeTourCompleted = false
                        appNotification.show("Reopen the app to view the hints")
                    }
                }
            }

            SectionHeader {
                text: "Chats"
            }

            Row {
                TextField {
                    id: chatId
                    anchors.bottom: parent.bottom
                    width: column.width - joinButton.width - Theme.horizontalPageMargin
                    placeholderText: "Chat id"
                    inputMethodHints: Qt.ImhDigitsOnly
                    labelVisible: false
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: tdLibWrapper.joinChat(text)
                }
                Button {
                    id: joinButton
                    text: "Join by id"
                    anchors.bottom: parent.bottom
                    enabled: chatId.text.length > 0
                    onClicked: tdLibWrapper.joinChat(chatId.text)
                }
            }

            Row {
                width: parent.width
                TextField {
                    id: chatIdWithMessage
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    placeholderText: "Chat id"
                    inputMethodHints: Qt.ImhDigitsOnly
                    labelVisible: false
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: messageId.focus = true
                }
                TextField {
                    id: messageId
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    placeholderText: "Message id"
                    inputMethodHints: Qt.ImhDigitsOnly
                    labelVisible: false
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: overviewPage.openChat(chatIdWithMessage.text, {messageIdToShow: messageId.text}, popSwitch.checked)
                }
            }
            TextSwitch {
                id: popSwitch
                text: "Pop"
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open"
                onClicked: overviewPage.openChat(chatIdWithMessage.text, {messageIdToShow: messageId.text}, popSwitch.checked)
            }

            SectionHeader { text: "Translating" }
            function translate() {
                pageStack.push(Qt.resolvedUrl("TranslatePage.qml"), {
                                                              getExtra: function() { return "debug" },
                                                              sourceText: utilities.newFormattedText(translateArea.text)
                                                          })
            }
            TextArea {
                id: translateArea
                width: parent.width
                label: "Text to translate"
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: translate()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Translate"
                onClicked: translate()
            }


            SectionHeader { text: "Execute custom request" }
            function executeCustom() {
                tdLibWrapper.sendRequestWithId(JSON.parse(customRequestArea.text)).finished.connect(function(response) {
                    customRequestResponseLabel.text = JSON.stringify(response, null, '\t')
                })
            }
            TextArea {
                id: customRequestArea
                width: parent.width
                label: "JSON-encoded request"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: column.executeCustom()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Execute"
                onClicked: column.executeCustom()
            }

            Label {
                id: customRequestResponseLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                text: "Response to your request will be here.\n\n@extra field is not supported here and will be overwritten, because it is used for request identification.\n\nClick on the text to copy"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Clipboard.text = parent.text
                        appNotification.show("Copied")
                    }
                }
            }


            SectionHeader { text: "Custom request (no response)" }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                text: "You can still check the response in this mode by building the app in debug mode and checking the logs from the console"
                color: Theme.secondaryHighlightColor
            }

            function executeCustomNoResponse() {
                tdLibWrapper.sendRequest(JSON.parse(customRequestNoResponseArea.text))
            }

            TextArea {
                id: customRequestNoResponseArea
                width: parent.width
                label: "JSON-encoded request"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: column.executeCustomNoResponse()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Execute"
                onClicked: column.executeCustomNoResponse()
            }

            SectionHeader { text: "Execute JS" }
            TextArea {
                id: jsArea
                width: parent.width
                label: "Code"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                text: 'showJsonResult("Hello from JS!")'
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: eval(jsArea.text)
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Execute"
                onClicked: eval(jsArea.text)
            }
            Label {
                id: customDataLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                text: "Use `showResult(text)` from JS to show text here, or the showJsonResult shorthand to show it in JSON."
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Clipboard.text = parent.text
                        appNotification.show("Copied")
                    }
                }
            }


            SectionHeader { text: "Options" }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                text: JSON.stringify(tdLibWrapper.options, null, '\t')
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Clipboard.text = parent.text
                        appNotification.show("Copied")
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Timer {
        id: profileTimer
        interval: 1000
        property bool hasRun
        property var cases: []
        onTriggered: {
            if (!cases.length)
                return

            if (!hasRun) {
                hasRun = true
                Debug.profile()
            }
            cases.pop()()

            if (cases.length)
                restart()
            else
                Debug.profileEnd()
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // example runner for comparing function calls

//            profileTimer.cases.push(function(){
//                Debug.compareAndRepeat(
//                            "getUserName",
//                            utilities.getUserName,
//                            utilities.getUserName,
//                            [
//                                [{first_name: "Test", last_name: "User"}],
//                                [{first_name: "Test", last_name: ""}],
//                                [{first_name: "Test"}],
//                                [{first_name: "", last_name: "User"}],
//                                [{last_name: "User"}]
//                            ],
//                            800
//                            )
//            })
//            profileTimer.start()
        }
    }
}
