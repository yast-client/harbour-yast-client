import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0
import ".."

import "../../js/debug.js" as Debug
import "../../js/twemoji.js" as Emoji

Column {
    id: newMessageColumn
    spacing: Theme.paddingSmall
    topPadding: Theme.paddingSmall + inlineQuery.buttonPadding
    anchors.horizontalCenter: parent.horizontalCenter
    visible: height > 0
    width: parent.width - ( 2 * Theme.horizontalPageMargin )
    height: show ? implicitHeight : 0
    Behavior on height { SmoothedAnimation { duration: 200 } }

    property int allowedOrientations
    property var myUserId
    property bool show
    property string replyToMessageId: "0"
    property string editMessageId: "0"
    property bool editIsCaption

    property var emojiProposals

    property alias newMessageInReplyToRow: newMessageInReplyToRow
    property alias knownUsersRepeater: knownUsersRepeater
    property alias attachmentPreviewRow: attachmentPreviewRow
    property alias newMessageTextField: newMessageTextField
    property alias attachmentOptionsFlickable: attachmentOptionsFlickable

    function getWordBoundaries(text, cursorPosition) {
        var wordBoundaries = { beginIndex : 0, endIndex : text.length}
        var currentIndex = 0
        for (currentIndex = (cursorPosition - 1); currentIndex > 0; currentIndex--) {
            if (text.charAt(currentIndex) === ' ') {
                wordBoundaries.beginIndex = currentIndex + 1
                break
            }
        }
        for (currentIndex = cursorPosition; currentIndex < text.length; currentIndex++) {
            if (text.charAt(currentIndex) === ' ') {
                wordBoundaries.endIndex = currentIndex
                break
            }
        }
        return wordBoundaries
    }

    function replaceMessageText(text, cursorPosition, newText) {
        var wordBoundaries = getWordBoundaries(text, cursorPosition)
        var newCompleteText = text.substring(0, wordBoundaries.beginIndex) + newText + " " + text.substring(wordBoundaries.endIndex)
        var newIndex = wordBoundaries.beginIndex + newText.length + 1
        newMessageTextField.text = newCompleteText
        newMessageTextField.cursorPosition = newIndex
        lostFocusTimer.start()
    }

    function handleMessageTextReplacement(text, cursorPosition) {
        if(!newMessageTextField.focus) return

        var wordBoundaries = getWordBoundaries(text, cursorPosition)

        var currentWord = text.substring(wordBoundaries.beginIndex, wordBoundaries.endIndex)
        if (currentWord.length > 1 && currentWord.charAt(0) === ':')
            tdLibWrapper.searchEmojis(currentWord.substring(1))
        else
            emojiProposals = null

        if (currentWord.length > 1 && currentWord.charAt(0) === '@') {
            knownUsersRepeater.model = knownUsersProxyModel
            knownUsersProxyModel.setFilterWildcard("*" + currentWord.substring(1) + "*")
        } else
            knownUsersRepeater.model = undefined
    }

    Connections {
        target: tdLibWrapper
        onFileUpdated: {
            uploadStatusRow.visible = fileInformation.remote.is_uploading_active
            if (uploadStatusRow.visible) {
                uploadingProgressBar.maximumValue = fileInformation.size
                uploadingProgressBar.value = fileInformation.remote.uploaded_size
            }
        }
    }

    Timer {
        id: textReplacementTimer
        interval: 600
        running: false
        repeat: false
        onTriggered:
            handleMessageTextReplacement(newMessageTextField.text, newMessageTextField.cursorPosition)
    }

    Connections {
        target: tdLibWrapper
        onEmojiKeywordsReceived: {
            emojiProposals = emojis
        }
    }

    InReplyToRow {
        onInReplyToMessageChanged:
            if (inReplyToMessage) {
                newMessageColumn.replyToMessageId = newMessageInReplyToRow.inReplyToMessage.id.toString()
                newMessageInReplyToRow.visible = true
            } else {
                newMessageInReplyToRow.visible = false
                newMessageColumn.replyToMessageId = "0"
            }

        editable: true

        onClearRequested:
            newMessageInReplyToRow.inReplyToMessage = null

        id: newMessageInReplyToRow
        myUserId: newMessageColumn.myUserId
        visible: false
    }

    Column {
        id: botCommandsColumn
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        visible: opacity > 0
        opacity: hidden ? 0 : 1
        Behavior on opacity { NumberAnimation {} }
        height: hidden ? 0 : childrenRect.height
        Behavior on height { SmoothedAnimation { duration: 200 } }
        spacing: Theme.paddingMedium

        property bool hidden: true

        Flickable {
            width: parent.width
            height: Math.min(botCommandsContentColumn.height, Theme.itemSizeHuge) + Theme.paddingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            contentHeight: botCommandsContentColumn.height
            clip: true
            Column {
                id: botCommandsContentColumn
                spacing: Theme.paddingMedium
                width: parent.width
                Repeater {
                    id: botCommandsRepeater
                    model: !botCommandsColumn.hidden && botInformation ? botInformation.commands : undefined

                    BackgroundItem {
                        width: parent.width
                        height: botCommandItem.height
                        contentItem.color: 'transparent'

                        Row {
                            id: botCommandItem
                            width: parent.width
                            spacing: Theme.paddingSmall
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: modelData.command
                                textFormat: Text.StyledText
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                            }
                            Label {
                                width: parent.width - parent.children[0].width - parent.spacing*1
                                text: Emoji.emojify(modelData.description, Theme.fontSizeSmall)
                                textFormat: Text.StyledText
                                font.pixelSize: Theme.fontSizeMedium
                                truncationMode: TruncationMode.Fade
                            }
                        }

                        onClicked: {
                            botCommandsColumn.hidden = true
                            tdLibWrapper.sendTextMessage(chatInformation.id,
                                                            '/'+modelData.command // FIXME
                                                            )
                        }
                    }

                }
            }
        }
    }

    Flickable {
        id: attachmentOptionsFlickable

        property bool show: false
        width: newMessageColumn.parent.width
        x: -Theme.horizontalPageMargin
        height: show && !inlineQuery.userNameIsValid ? attachmentOptionsRow.height : 0
        Behavior on height { SmoothedAnimation { duration: 200 } }
        visible: height > 0
        contentHeight: attachmentOptionsRow.height
        contentWidth: Math.max(width, attachmentOptionsRow.width)
        property bool fadeRight: (attachmentOptionsRow.width-contentX) > width
        property bool fadeLeft: !fadeRight && contentX > 0
        layer.enabled: fadeRight || fadeLeft
        layer.effect: OpacityRampEffectBase {
            direction: attachmentOptionsFlickable.fadeRight ? OpacityRamp.LeftToRight : OpacityRamp.RightToLeft
            source: attachmentOptionsFlickable
            slope: 1 + 6 * (newMessageColumn.parent.width) / Screen.width
            offset: 1 - 1 / slope
        }


        Row {
            id: attachmentOptionsRow

            height: attachImageIconButton.height

            anchors.right: parent.right
            layoutDirection: Qt.RightToLeft
            spacing: Theme.paddingMedium
            leftPadding: Theme.horizontalPageMargin
            rightPadding: Theme.horizontalPageMargin

            IconButton {
                id: attachImageIconButton
                visible: chatPage.hasSendPrivilege("can_send_photos")
                icon.source: "image://theme/icon-m-image"
                onClicked: {
                    var picker = pageStack.push("Sailfish.Pickers.ImagePickerPage", {
                        allowedOrientations: newMessageColumn.allowedOrientations
                    })
                    picker.selectedContentPropertiesChanged.connect(function(){
                        attachmentOptionsFlickable.show = false
                        Debug.log("Selected document: ", picker.selectedContentProperties.filePath )
                        attachmentPreviewRow.fileProperties = picker.selectedContentProperties
                        attachmentPreviewRow.isPicture = true
                    })
                }
            }
            IconButton {
                visible: chatPage.hasSendPrivilege("can_send_videos")
                icon.source: "image://theme/icon-m-video"
                onClicked: {
                    var picker = pageStack.push("Sailfish.Pickers.VideoPickerPage", {
                        allowedOrientations: newMessageColumn.allowedOrientations
                    })
                    picker.selectedContentPropertiesChanged.connect(function(){
                        attachmentOptionsFlickable.show = false
                        Debug.log("Selected video: ", picker.selectedContentProperties.filePath )
                        attachmentPreviewRow.fileProperties = picker.selectedContentProperties
                        attachmentPreviewRow.isVideo = true
                    })
                }
            }
            IconButton {
                visible: chatPage.hasSendPrivilege("can_send_voice_notes")
                icon.source: "image://theme/icon-m-mic"
                icon.sourceSize {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                }
                highlighted: down || voiceNoteOverlayLoader.active
                onClicked: {
                    voiceNoteOverlayLoader.active = !voiceNoteOverlayLoader.active
                    stickerPickerLoader.active = false
                    botCommandsColumn.hidden = true
                }
            }
            IconButton {
                visible: chatPage.hasSendPrivilege("can_send_documents")
                icon.source: "image://theme/icon-m-document"
                onClicked: {
                    var picker = pageStack.push("Sailfish.Pickers.FilePickerPage", {
                        allowedOrientations: newMessageColumn.allowedOrientations
                    })
                    picker.selectedContentPropertiesChanged.connect(function(){
                        attachmentOptionsFlickable.show = false
                        Debug.log("Selected document: ", picker.selectedContentProperties.filePath)
                        attachmentPreviewRow.fileProperties = picker.selectedContentProperties
                        attachmentPreviewRow.isDocument = true
                    })
                }
            }
            IconButton {
                visible: chatPage.hasSendPrivilege("can_send_other_messages")
                icon.source: "../../../images/icon-m-sticker.svg"
                icon.sourceSize {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                }
                highlighted: down || stickerPickerLoader.active
                onClicked: {
                    stickerPickerLoader.active = !stickerPickerLoader.active
                    voiceNoteOverlayLoader.active = false
                    botCommandsColumn.hidden = true
                }
            }
            IconButton {
                visible: !(chatPage.isPrivateChat || chatPage.isSecretChat) && chatPage.hasSendPrivilege("can_send_polls")
                icon.source: "image://theme/icon-m-question"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../../dialogs/NewPollDialog.qml"), {
                                        chatId: chatInformation.id,
                                        chatTitle: chatInformation.title,
                                        isChannel: isChannel,
                                        replyToMessageId: newMessageColumn.replyToMessageId,
                                        topicId: topicId
                                    })
                    attachmentOptionsFlickable.show = false
                }
            }
            IconButton {
                visible: utilities.supportsGeoLocation() && newMessageTextField.text === ""
                icon.source: "image://theme/icon-m-location"
                icon.sourceSize {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                }
                onClicked: {
                    utilities.startGeoLocationUpdates()
                    attachmentOptionsFlickable.show = false
                    attachmentPreviewRow.isLocation = true
                    attachmentPreviewRow.attachmentDescription = qsTr("Location: Obtaining position...")
                }
            }
            IconButton {
                visible: !!botInformation && botInformation.commands.length > 0
                highlighted: down || !botCommandsColumn.hidden
                icon.source: "image://theme/icon-m-menu"
                onClicked: {
                    //attachmentOptionsFlickable.show = false
                    botCommandsColumn.hidden = !botCommandsColumn.hidden
                    stickerPickerLoader.active = false
                    voiceNoteOverlayLoader.active = false
                }
            }
        }

    }


    Row {
        id: attachmentPreviewRow
        visible: (!!locationData || !!fileProperties || isVoiceNote) && !inlineQuery.userNameIsValid
        spacing: Theme.paddingMedium
        width: parent.width
        layoutDirection: Qt.RightToLeft
        anchors.right: parent.right

        property bool isPicture: false
        property bool isVideo: false
        property bool isDocument: false
        property bool isVoiceNote: false
        property bool isLocation: false
        property bool attachmentSelected: isPicture || isDocument || isVideo || isVoiceNote || isLocation
        property var locationData: null
        property var geocodedAddress: qsTr("Unknown address")
        property var fileProperties: null
        property string attachmentDescription: ""

        function getLocationDescription() {
            return qsTr("Location (%1/%2)").arg(attachmentPreviewRow.locationData.latitude).arg(attachmentPreviewRow.locationData.longitude) + " | "
                    + qsTr("Accuracy: %1m").arg(attachmentPreviewRow.locationData.horizontalAccuracy) + "\n"
                    + attachmentPreviewRow.geocodedAddress
        }

        Connections {
            target: utilities
            onNewPositionInformation: {
                attachmentPreviewRow.locationData = positionInformation
                if (attachmentPreviewRow.isLocation)
                    attachmentPreviewRow.attachmentDescription = attachmentPreviewRow.getLocationDescription()
            }
            onNewGeocodedAddress: {
                attachmentPreviewRow.geocodedAddress = geocodedAddress
                if (attachmentPreviewRow.isLocation)
                    attachmentPreviewRow.attachmentDescription = attachmentPreviewRow.getLocationDescription()
            }
        }

        IconButton {
            id: removeAttachmentsIconButton
            icon.source: "image://theme/icon-m-clear"
            onClicked: {
                clearAttachmentPreviewRow()
            }
        }

        Thumbnail {
            id: attachmentPreviewImage
            width: Theme.itemSizeMedium
            height: Theme.itemSizeMedium
            sourceSize.width: width
            sourceSize.height: height

            fillMode: Thumbnail.PreserveAspectCrop
            mimeType: !!attachmentPreviewRow.fileProperties ? attachmentPreviewRow.fileProperties.mimeType || "" : ""
            source: !!attachmentPreviewRow.fileProperties ? attachmentPreviewRow.fileProperties.url || "" : ""
            visible: attachmentPreviewRow.isPicture || attachmentPreviewRow.isVideo
        }

        Label {
            id: attachmentPreviewText
            font.pixelSize: Theme.fontSizeSmall
            text: ( attachmentPreviewRow.isVoiceNote || attachmentPreviewRow.isLocation ) ? attachmentPreviewRow.attachmentDescription : ( !!attachmentPreviewRow.fileProperties ? attachmentPreviewRow.fileProperties.fileName || "" : "" )
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - removeAttachmentsIconButton.width - Theme.paddingMedium
            maximumLineCount: 2
            wrapMode: Text.Wrap
            truncationMode: TruncationMode.Fade
            color: Theme.secondaryColor
            visible: attachmentPreviewRow.isDocument || attachmentPreviewRow.isVoiceNote || attachmentPreviewRow.isLocation
        }
    }

    Row {
        id: uploadStatusRow
        visible: false
        spacing: Theme.paddingMedium
        width: parent.width
        anchors.right: parent.right

        Text {
            id: uploadingText
            font.pixelSize: Theme.fontSizeSmall
            text: qsTr("Uploading...")
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.secondaryColor
            visible: uploadStatusRow.visible
        }

        ProgressBar {
            id: uploadingProgressBar
            minimumValue: 0
            maximumValue: 100
            value: 0
            visible: uploadStatusRow.visible
            width: parent.width - uploadingText.width - Theme.paddingMedium
        }

    }

    Column {
        id: emojiColumn
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        visible: opacity > 0
        opacity: emojiProposals && emojiProposals.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation {} }
        spacing: Theme.paddingMedium

        Flickable {
            width: parent.width
            height: emojiResultRow.height + Theme.paddingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            contentWidth: emojiResultRow.width
            clip: true
            Row {
                id: emojiResultRow
                spacing: Theme.paddingMedium
                Repeater {
                    model: emojiProposals
                    Image {
                        id: emojiPicture
                        source: Emoji.getEmojiPath(modelData)
                        width: Theme.fontSizeLarge
                        height: Theme.fontSizeLarge

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                replaceMessageText(newMessageTextField.text, newMessageTextField.cursorPosition, modelData)
                                emojiProposals = null
                            }
                        }
                    }

                }
            }
        }
    }

    Column {
        id: atMentionColumn
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        visible: opacity > 0
        opacity: knownUsersRepeater.count > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation {} }
        height: knownUsersRepeater.count > 0 ? childrenRect.height : 0
        Behavior on height { SmoothedAnimation { duration: 200 } }
        spacing: Theme.paddingMedium

        Flickable {
            width: parent.width
            height: atMentionResultRow.height + Theme.paddingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            contentWidth: atMentionResultRow.width
            clip: true
            Row {
                id: atMentionResultRow
                spacing: Theme.paddingMedium
                Repeater {
                    id: knownUsersRepeater

                    Item {
                        id: knownUserItem
                        height: singleAtMentionRow.height
                        width: singleAtMentionRow.width

                        property string atMentionText: "@" + (user_name ? user_name : user_id + "(" + title + ")")

                        Row {
                            id: singleAtMentionRow
                            spacing: Theme.paddingSmall

                            Item {
                                width: Theme.fontSizeHuge
                                height: Theme.fontSizeHuge
                                anchors.verticalCenter: parent.verticalCenter
                                ProfileThumbnail {
                                    id: atMentionThumbnail
                                    replacementStringHint: title
                                    width: parent.width
                                    height: parent.width
                                    photoData: photo_data.small
                                    minithumbnail: photo_data.minithumbnail
                                }
                            }

                            Column {
                                Text {
                                    text: Emoji.emojify(title, Theme.fontSizeExtraSmall)
                                    textFormat: Text.StyledText
                                    color: Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    font.bold: true
                                }
                                Text {
                                    id: userHandleText
                                    text: user_handle
                                    textFormat: Text.StyledText
                                    color: Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                replaceMessageText(newMessageTextField.text, newMessageTextField.cursorPosition, knownUserItem.atMentionText)
                                knownUsersRepeater.model = undefined
                            }
                        }
                    }

                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.paddingSmall
        visible: newMessageColumn.editMessageId !== "0"

        Text {
            width: parent.width - Theme.paddingSmall - removeEditMessageIconButton.width

            anchors.verticalCenter: parent.verticalCenter

            id: editMessageText
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            text: qsTr("Edit Message")
            color: Theme.secondaryColor
        }

        IconButton {
            id: removeEditMessageIconButton
            icon.source: "image://theme/icon-m-clear"
            onClicked: {
                newMessageColumn.editMessageId = "0"
                newMessageColumn.editIsCaption = false
                newMessageTextField.text = ""
            }
        }
    }

    Row {
        id: newMessageRow
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter

        TextArea {
            id: newMessageTextField
            width: parent.width - (attachmentIconButton.visible ? attachmentIconButton.width : 0) - (newMessageSendButton.visible ? newMessageSendButton.width : 0) - (cancelInlineQueryButton.visible ? cancelInlineQueryButton.width : 0)
            height: Math.min(chatContainer.height / 3, implicitHeight)
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: Theme.fontSizeSmall
            placeholderText: {
                if (isChannel)
                    return chatInformation.default_disable_notification
                            ? qsTr("Silent Broadcast", "placeholder for broadcasting a message to a channel silently")
                            : qsTr("Broadcast", "placeholder for broadcasting a message to a channel")

                if (isSupergroup && chatGroupInformation && chatGroupInformation.status &&
                        ((chatGroupInformation.status["@type"] === "chatMemberStatusCreator" && chatGroupInformation.status.is_anonymous)
                         || (chatGroupInformation.status["@type"] === "chatMemberStatusAdministrator" && chatGroupInformation.status.rights.is_anonymous)))
                    return qsTr("Send anonymously", "placeholder for sending an anonymous message in a supergroup")

                if ((isSupergroup && chatGroupInformation.paid_message_star_count > 0) || (isPrivateChat && chatPartnerInformation.paid_message_star_count > 0))
                    // fixme: format the number somehow and maybe use ⭐️ emoji
                    return qsTr("Message for %1 Stars", "placeholder for sending a message for %1 stars").arg(isSupergroup ? chatGroupInformation.paid_message_star_count : chatPartnerInformation.paid_message_star_count)

                return qsTr("Message", "placeholder for sending a message")
            }
            labelVisible: false
            textLeftMargin: 0
            textTopMargin: 0
            enabled: !attachmentPreviewRow.isLocation
            focus: appSettings.focusTextAreaOnChatOpen
            EnterKey.onClicked: if (appSettings.sendByEnter) {
                var messageText = newMessageTextField.text
                newMessageTextField.text = messageText.substring(0, newMessageTextField.cursorPosition -1) + messageText.substring(newMessageTextField.cursorPosition)
                sendMessage()
                newMessageTextField.text = ""
                if(!appSettings.focusTextAreaAfterSend)
                    newMessageTextField.focus = false
            }

            EnterKey.enabled: !inlineQuery.userNameIsValid && (!appSettings.sendByEnter || (appSettings.sendAttachmentByEnter ? newMessageSendButton.enabled : text.length))
            EnterKey.iconSource: "image://theme/icon-m-" + (appSettings.sendByEnter ? "chat" : "enter")

            onTextChanged: {
                textReplacementTimer.restart()
                tdLibWrapper.sendChatAction(chatInformation.id, text ? TDLibWrapper.Typing : TDLibWrapper.Cancel, topicId)
            }
        }

        IconButton {
            id: attachmentIconButton
            icon.source: "image://theme/icon-m-attach?" +  (attachmentOptionsFlickable.show ? Theme.highlightColor : Theme.primaryColor)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            enabled: !attachmentPreviewRow.visible && !stickerSetOverlayLoader.item
            visible: !inlineQuery.userNameIsValid
            onClicked: {
                if (attachmentOptionsFlickable.show) {
                    attachmentOptionsFlickable.show = false
                    stickerPickerLoader.active = false
                    voiceNoteOverlayLoader.active = false
                    botCommandsColumn.hidden = true
                } else attachmentOptionsFlickable.show = true
            }
        }

        IconButton {
            id: newMessageSendButton
            icon.source: "image://theme/icon-m-chat"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            visible: !inlineQuery.userNameIsValid && (!appSettings.sendByEnter || (!appSettings.sendAttachmentByEnter && attachmentPreviewRow.visible))
            enabled: (/*chatPage.hasSendPrivilege('can_send_basic_messages') &&*/ newMessageTextField.text.length !== 0)
                     || attachmentPreviewRow.attachmentSelected
            /*icon.opacity: !enabled || (!attachmentPreviewRow.attachmentSelected && !chatPage.hasSendPrivilege('can_send_basic_messages'))
                          ? Theme.opacityLow : 1.0*/
            onClicked: {
                /*if (!attachmentPreviewRow.attachmentSelected && !chatPage.hasSendPrivilege('can_send_basic_messages')) {
                    appNotification.show(qsTr("The admins of this group don't allow sending text messages.", "app notification text"))
                    return
                }*/
                sendMessage()
                newMessageTextField.text = ""
                if(!appSettings.focusTextAreaAfterSend)
                    newMessageTextField.focus = false
            }
        }

        Item {
            width: cancelInlineQueryButton.width
            height: cancelInlineQueryButton.height
            visible: inlineQuery.userNameIsValid
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall

            IconButton {
                id: cancelInlineQueryButton
                icon.source: "image://theme/icon-m-cancel"
                visible: parent.visible
                opacity: inlineQuery.isLoading ? 0.2 : 1
                Behavior on opacity { FadeAnimation {} }
                onClicked: {
                    if(inlineQuery.query !== "") {
                        newMessageTextField.text = "@" + inlineQuery.userName + " "
                        newMessageTextField.cursorPosition = newMessageTextField.text.length
                        lostFocusTimer.start()
                    } else newMessageTextField.text = ""
                }
                onPressAndHold:
                    newMessageTextField.text = ""
            }

            BusyIndicator {
                size: BusyIndicatorSize.Small
                anchors.centerIn: parent
                running: inlineQuery.isLoading
            }
        }


    }
}
