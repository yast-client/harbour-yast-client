import QtQuick 2.0
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Page {
    id: page
    property var messageId
    property var message

    readonly property var supportedLanguages: ["af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca", "ceb", "zh-CN", "zh", "zh-Hans", "zh-TW", "zh-Hant", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "fi", "fr", "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "he", "iw", "hi", "hmn", "hu", "is", "ig", "id", "in", "ga", "it", "ja", "jv", "kn", "kk", "km", "rw", "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb", "mk", "mg", "ms", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ny", "or", "ps", "fa", "pl", "pt", "pa", "ro", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tl", "tg", "ta", "tt", "te", "th", "tr", "tk", "uk", "ur", "ug", "uz", "vi", "cy", "xh", "yi", "ji", "yo", "zu"]

    property var sourceText
    property bool translating
    property string translated
    property string plainTranslated

    property string language: {
        var l = Qt.locale().name.slice(0, 2) // for locales like ru_RU and en_US
        if (supportedLanguages.indexOf(l) != -1) return l
        return "en"
    }

    /*
        How does appSettings.formattedTranslate work:
        1. Instead of putting formatted text with entities, we put HTML text to translateText function
        2. When receiving translated version, we don't escape HTML tag characters when running utilities.enhanceMessageText().
    */

    function checkMessage() {
        if (message) sourceText = appSettings.formattedTranslate
                     ? utilities.makeDummyFormattedText(utilities.getMessageText(message))
                     : utilities.getFormattedMessageText(message)
    }
    function translate() {
        translating = true
        translated = ""
        translating = true
        tdLibWrapper.translateText(sourceText, language, messageId)
    }

    onMessageChanged: checkMessage()
    onSourceTextChanged: translate()
    onLanguageChanged: translate()

    Component.onCompleted: {
        checkMessage()
        translate()
    }

    Connections {
        target: tdLibWrapper
        onTranslationResultReceived: if (extraId == messageId) {
                                         plainTranslated = utilities.enhanceMessageText(formattedText, true);
                                         translated = Emoji.emojify(utilities.enhanceMessageText(formattedText, false, !appSettings.formattedTranslate))
                                         translating = false
                                     }
    }

    Component {
        id: languageSelectorComponent

        Page {
            SilicaListView {
                anchors.fill: parent
                model: ListModel {
                    Component.onCompleted:
                        supportedLanguages.forEach(function (lang) { append({lang: lang})})
                }

                header: PageHeader {
                    title: qsTr("Change language")
                }

                delegate: BackgroundItem {
                    id: languageItem
                    height: languageColumn.height

                    onClicked: {
                        page.language = lang
                        pageStack.pop()
                    }

                    property string name: Qt.locale(lang).nativeLanguageName

                    Column {
                        id: languageColumn
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x

                        Label {
                            id: mainLabel
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: name || lang
                            visible: !!text
                            highlighted: languageItem.highlighted || page.language === lang
                        }

                        Label {
                            width: parent.width
                            visible: !!name
                            height: visible ? implicitHeight : 0
                            font.pixelSize: Theme.fontSizeExtraSmall
                            wrapMode: Text.Wrap
                            text: lang
                            highlighted: mainLabel.highlighted
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    ComboBox {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Change language")
                onClicked: pageStack.push(languageSelectorComponent)
            }
            MenuItem {
                text: qsTr("Copy")
                visible: !translating && !!plainTranslated // FIXME: should we use enabled or visible here?
                onClicked: Clipboard.text = plainTranslated
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: {
                    var name = Qt.locale(language).nativeLanguageName
                    if (!name) return qsTr("Translation")
                    return name.slice(0, 1).toUpperCase() + name.slice(1)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.StyledText
                linkColor: Theme.highlightColor
                text: translated
                onLinkActivated: Functions.handleLink(link)
            }
        }
    }

    /*PageBusyIndicator {
        running: translating
    }*/
}
