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
import App.Logic 1.0
import "../components"
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: debugPage
    allowedOrientations: Orientation.All

    property var overviewPage

    SilicaFlickable {
        id: aboutContainer
        contentHeight: column.height
        anchors.fill: parent

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: "Debug Page"
                description: "description"
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
                    labelVisible: false
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: overviewPage.openChatWithMessageId(chatIdWithMessage.text, messageId.text)
                }
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open"
                onClicked: overviewPage.openChatWithMessageId(chatIdWithMessage.text, messageId.text)
            }

            SectionHeader { text: "Translating" }
            TextArea {
                id: translateArea
                width: parent.width
                label: "Text to translate"
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Translate"
                onClicked: pageStack.push(Qt.resolvedUrl("TranslatePage.qml"), {
                                              getExtra: function() { return "debug" },
                                              sourceText: utilities.newFormattedText(translateArea.text)
                                          })
            }


            SectionHeader { text: "Execute custom request" }
            TextArea {
                id: customRequestArea
                width: parent.width
                label: "JSON-encoded request"
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Execute"
                onClicked: customRequestResponseLabel.requestId = tdLibWrapper.sendRequestWithId(JSON.parse(customRequestArea.text))
            }

            Label {
                id: customRequestResponseLabel
                property var requestId
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

            Connections {
                target: tdLibWrapper
                onResponseForRequestIdReceived:
                    if (requestId == customRequestResponseLabel.requestId)
                        customRequestResponseLabel.text = JSON.stringify(response, null, '\t')
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
            if(cases.length === 0) {
                return;
            }

            if(!hasRun) {
                hasRun = true;
                Debug.profile();
            }
            cases.pop()();

            if(cases.length > 0) {
                restart();
            } else {
                Debug.profileEnd();
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // example runner for comparing function calls

//            profileTimer.cases.push(function(){
//                Debug.compareAndRepeat(
//                            "getUserName",
//                            Functions.getUserName,
//                            Functions.getUserName,
//                            [
//                                [{first_name: "Test", last_name: "User"}],
//                                [{first_name: "Test", last_name: ""}],
//                                [{first_name: "Test"}],
//                                [{first_name: "", last_name: "User"}],
//                                [{last_name: "User"}]
//                            ],
//                            800
//                            )
//            });
//            profileTimer.start();
        }
    }
}
