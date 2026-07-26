//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../js/debug.js" as Debug
import "../../js/twemoji.js" as Emoji
import "../../js/functions.js" as Functions

Loader {
    id: inlineQueryLoader
    active: userName.length > 1
    asynchronous: true
    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: active ? parent.bottom : parent.top
    }
    property bool loaded: active && userNameIsValid && status === Loader.Ready
    property bool hasOverlay: loaded && item.overlay && item.overlay.status === Loader.Ready
    property bool hasButton: loaded && item.button && item.button.status === Loader.Ready

    property int buttonPadding: hasButton ? item.button.height + Theme.paddingSmall : 0
    Behavior on buttonPadding { NumberAnimation { duration: 200} }

    property string chatId
    property string userName
    property bool userNameIsValid: userName !== "" && inlineBotInformation && userName.toLowerCase() === inlineBotInformation.usernames.editable_username.toLowerCase()
    property string query
    property string currentOffset: ''
    property string responseExtra: chatId+"|"+userName+"|"+query+"|"+currentOffset

    property bool queued: false
    property TextArea textField
    property bool isLoading
    property var inlineBotInformation: null

    onIsLoadingChanged:
        requestTimeout.start()

    function fetchBot() {
        inlineBotInformation = null
        if (status === Loader.Ready && userName) {
            isLoading = true
            tdLibWrapper.searchPublicChat(userName)
        }
    }
    onStatusChanged: fetchBot()
    onUserNameChanged: fetchBot()

    onQueryChanged:
        if (userName) {
            isLoading = true
            requestTimer.start()
        }

    function request() {
        if (!inlineBotInformation || !userNameIsValid) {
            queued = true
            return
        }

        queued = false
        var location = null
        if (inlineBotInformation.type.need_location && utilities.supportsGeoLocation()) {
            utilities.startGeoLocationUpdates()
            if (!attachmentPreviewRow.locationData.latitude) {
                queued = true
                return
            }
        }
        tdLibWrapper.getInlineQueryResults(inlineBotInformation.id, chatId, location, query, inlineQueryLoader.currentOffset, inlineQueryLoader.responseExtra)
        isLoading = true
    }

    Timer {
        id: requestTimeout
        interval: 5000
        onTriggered: inlineQueryLoader.isLoading = false
    }

    Timer {
        id: requestTimer
        interval: 1000
        onTriggered: request()
    }

    Connections {
        target: utilities
        onNewPositionInformation: {
            attachmentPreviewRow.locationData = positionInformation
            if (inlineQueryLoader.queued) {
                inlineQueryLoader.queued = false
                inlineQueryLoader.request()
            }
        }
    }

    Connections {
        target: textField
        onTextChanged: {
            inlineQueryLoader.currentOffset = ''
            var queryMatch = textField.text.match(/^@([a-zA-Z0-9_]+)\s(.*)/)
            if (queryMatch) {
                inlineQueryLoader.userName = queryMatch[1]
                inlineQueryLoader.query = queryMatch[2]
            } else
                inlineQueryLoader.userName = inlineQueryLoader.query = ''
        }
    }

    sourceComponent: Component {
        Item {
            id: inlineQueryComponent
            anchors.fill: parent
            property alias overlay: resultsOverlay
            property alias button: buttonLoader
            property string nextOffset
            property string inlineQueryId
            property var buttonData
            property ListModel resultModel: ListModel {
                dynamicRoles: true
            }
            property string inlineQueryPlaceholder: inlineBotInformation ? inlineBotInformation.type.inline_query_placeholder : ""
            property bool showInlineQueryPlaceholder: !!inlineQueryPlaceholder && query === ""
            property string useDelegateSize: "default"
            property var dimensions: ({
                                          default: [[Screen.width, Screen.height / 2], [Theme.itemSizeLarge, Theme.itemSizeLarge]], // whole line (portrait half)
                                          inlineQueryResultAnimation:  [[Screen.width / 3, Screen.height / 6], [Screen.width / 3, Screen.height / 6]],
                                          inlineQueryResultVideo:  [[Screen.width / 2, Screen.height / 4], [Theme.itemSizeLarge, Theme.itemSizeLarge]],
                                          inlineQueryResultSticker:  [[Screen.width / 3, Screen.height / 6], [Screen.width / 3, Screen.height / 6]],
                                          inlineQueryResultPhoto:  [[Screen.width/2, Screen.height / 3], [Theme.itemSizeExtraLarge, Theme.itemSizeExtraLarge]],
                                      })
            property int delegateWidth: chatPage.isPortrait ? dimensions[useDelegateSize][0][0] : dimensions[useDelegateSize][0][1]
            property int delegateHeight: chatPage.isPortrait ? dimensions[useDelegateSize][1][0] : dimensions[useDelegateSize][1][1]

            function setDelegateSizes() {
                var result = 'default'
                if (resultModel.count) {
                    result = resultModel.get(0)['@type']
                    for (var i=1; i < resultModel.count; i++)
                        if (result !== resultModel.get(0)['@type']) {
                            result = 'default'
                            break
                        }
                }
                useDelegateSize = result
            }

            function loadMore() {
                if (nextOffset && inlineQueryLoader.userNameIsValid) {
                    inlineQueryLoader.currentOffset = nextOffset
                    inlineQueryLoader.request()
                }
            }

            Connections {
                target: tdLibWrapper

                onChatReceived:
                    if (extra && extra.type === "searchPublicChat:"+inlineQueryLoader.userName) {
                        requestTimeout.stop()
                        inlineQueryLoader.isLoading = false
                        var inlineBotInformation = tdLibWrapper.getUserInformation(chat.type.user_id)
                        if (inlineBotInformation && inlineBotInformation.type["@type"] === "userTypeBot" && inlineBotInformation.type.is_inline) {
                            inlineQueryLoader.inlineBotInformation = inlineBotInformation
                            requestTimer.start()
                        }
                    }
                onInlineQueryResultsReceived:
                    if (extra === inlineQueryLoader.responseExtra) {
                        requestTimeout.stop()
                        inlineQueryLoader.isLoading = false
                        inlineQueryComponent.inlineQueryId = inlineQueryId
                        inlineQueryComponent.nextOffset = nextOffset
                        inlineQueryComponent.buttonData = button

                        if (!inlineQueryLoader.currentOffset)
                            inlineQueryComponent.resultModel.clear()
                        for (var i = 0; i < results.length; i++)
                            inlineQueryComponent.resultModel.append(results[i])

                        if (!inlineQueryLoader.currentOffset || inlineQueryLoader.useDelegateSize !== "default")
                            inlineQueryComponent.setDelegateSizes()
                }
            }

            Loader {
                id: buttonLoader
                asynchronous: true
                active: !!(buttonData && buttonData.text && buttonData.type)
                opacity: status === Loader.Ready ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }
                anchors {
                    top: parent.bottom
                    topMargin: Theme.paddingSmall
                }
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                sourceComponent: Component {
                    SecondaryButton {
                        // TODO: support inlineQueryResultsButtonTypeWebApp
                        anchors.horizontalCenter: parent.horizontalCenter
                        preferredWidth: Theme.buttonWidthLarge
                        text: Emoji.emojify(buttonData.text, Theme.fontSizeMedium)
                        enabled: buttonData.type['@type'] === 'inlineQueryResultsButtonTypeStartBot'
                        onClicked:
                            tdLibWrapper.createPrivateChat(inlineQueryLoader.inlineBotInformation.id,
                                {openDirectly: true, options: {openAndSendStartToBot: true, sendBotStartMessageParameter: buttonData.type.parameter}})
                    }
                }
            }

            // results grid overlay
            Loader {
                id: resultsOverlay
                asynchronous: true
                active: inlineQueryComponent.resultModel.count > 0
                anchors.fill: parent
                opacity: !!item ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }
                property var supportedResultTypes: [
                    "inlineQueryResultAnimation",
                    "inlineQueryResultArticle",
                    "inlineQueryResultAudio",
                    "inlineQueryResultContact",
                    "inlineQueryResultDocument",
                    "inlineQueryResultGame",
                    "inlineQueryResultLocation",
                    "inlineQueryResultPhoto",
                    "inlineQueryResultSticker",
                    "inlineQueryResultVenue",
                    "inlineQueryResultVideo",
                    "inlineQueryResultVoiceNote",
                ]
                sourceComponent: Component {
                    Item {
                        Rectangle {
                            id: messageContentBackground
                            color: Theme.overlayBackgroundColor
                            opacity: 0.7
                            anchors.fill: parent
                        }
                        Timer {
                            id: autoLoadMoreTimer
                            interval: 400
                            onTriggered:
                                if (resultView.height > resultView.contentHeight - Theme.itemSizeHuge)
                                    inlineQueryComponent.loadMore()
                        }
                        SilicaGridView {
                            id: resultView
                            anchors.fill: parent
                            cellWidth: inlineQueryComponent.delegateWidth
                            cellHeight: inlineQueryComponent.delegateHeight

                            signal requestPlayback(url playbackSource)
                            clip: true
                            model: inlineQueryComponent.resultModel
                            delegate: Loader {
                                id: queryResultDelegate
                                height: resultView.cellHeight
                                width: resultView.cellWidth
                                source: "inlineQueryResults/" + (resultsOverlay.supportedResultTypes.indexOf(model["@type"]) > -1 ? (model["@type"].charAt(0).toUpperCase() + model["@type"].substring(1)) : "InlineQueryResultDefaultBase") +".qml"
                            }
                            footer: Component {
                                Item {
                                    width: resultView.width
                                    visible: height > 0
                                    height: inlineQueryComponent.nextOffset ? Theme.itemSizeLarge : 0
                                    Behavior on height { NumberAnimation { duration: 500 } }
                                }
                            }

                            onContentYChanged:
                                if (!inlineQueryLoader.isLoading && contentHeight - contentY - height < Theme.itemSizeHuge)
                                    inlineQueryComponent.loadMore()

                            ScrollDecorator { flickable: resultView }
                        }
                    }
                }
            }


            // textarea placeholder
            Loader {
                asynchronous: true
                active: inlineQueryComponent.showInlineQueryPlaceholder
                sourceComponent: Component {
                    Label {
                        text: Emoji.emojify(inlineQueryComponent.inlineQueryPlaceholder, font.pixelSize);
                        parent: textField
                        anchors.fill: parent
                        anchors.leftMargin: textMetrics.boundingRect.width + Theme.paddingSmall
                        font: textField.font
                        color: Theme.secondaryColor

                        truncationMode: TruncationMode.Fade
                        TextMetrics {
                            id: textMetrics
                            font: textField.font
                            text: textField.text
                        }
                    }
                }
            }


        }
    }



}
