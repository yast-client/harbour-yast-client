import QtQuick 2.0
import Sailfish.Silica 1.0
import App.Logic 1.0
import Opal.SortFilterProxyModel 1.0
import "../js/twemoji.js" as Emoji
import "../js/functions.js" as Functions

Page {
    id: page
    property var message
    property var chatId: message ? message.chat_id : null
    property var messageId: message ? message.id : null

    readonly property var supportedLanguages: ["af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca", "ceb", "zh-CN", "zh", "zh-Hans", "zh-TW", "zh-Hant", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "fi", "fr", "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "he", "iw", "hi", "hmn", "hu", "is", "ig", "id", "in", "ga", "it", "ja", "jv", "kn", "kk", "km", "rw", "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb", "mk", "mg", "ms", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ny", "or", "ps", "fa", "pl", "pt", "pa", "ro", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tl", "tg", "ta", "tt", "te", "th", "tr", "tk", "uk", "ur", "ug", "uz", "vi", "cy", "xh", "yi", "ji", "yo", "zu"]

    property var sourceText: appSettings.formattedTranslate ? utilities.newFormattedText(utilities.getMessageText(message)) : null
    property bool translating
    property string translated
    property string plainTranslated

    property string deviceLanguage: Qt.locale().name.slice(0, 2) // for locales like ru_RU and en_US
    property bool deviceLanguageSupported: supportedLanguages.indexOf(deviceLanguage) >= 0

    property string language: deviceLanguageSupported ? deviceLanguage : 'en'

    property var getExtra: function() {
        return "msgtr" + chatId + ":" + messageId + language
    }

    /*
        How appSettings.formattedTranslate works:
        1. Instead of using translateMessageText, putting formatted text with entities, we put HTML text to translateText function
        2. When receiving translated version, we don't escape HTML tag characters when running utilities.enhanceMessageText().
    */

    function translate() {
        translating = true
        translated = ""
        if (sourceText)
            tdLibWrapper.translateText(sourceText, language, getExtra())
        else if (message)
            tdLibWrapper.translateMessageText(chatId, messageId, language)
    }

    onSourceTextChanged: translate()
    onLanguageChanged: translate()
    onMessageChanged: translate()
    Component.onCompleted: translate()

    Connections {
        target: tdLibWrapper
        onFormattedTextReceived:
            if (extra === getExtra()) {
                plainTranslated = utilities.enhanceMessageText(formattedText, true)
                translated = Emoji.emojify(utilities.enhanceMessageText(formattedText, false, !appSettings.formattedTranslate))
                translating = false
            }
    }

    Component {
        id: languageSelectionPageComponent
        Page {
            SilicaListView {
                id: languageSelectionView
                anchors.fill: parent

                property string searchQuery: headerItem ? headerItem.query : ''

                currentIndex: -1 // don't steal focus from search field

                model: SortFilterProxyModel {
                    sourceModel: ListModel {
                        id: languagesModel
                        Component.onCompleted:
                            supportedLanguages.forEach(function(lang) {
                                append({
                                           lang: lang,
                                           name: Qt.locale(lang).nativeLanguageName,
                                           //isDevice: deviceLanguageSupported && lang === deviceLanguage
                                       })
                            })
                    }

                    filters: AnyOf {
                        enabled: !!languageSelectionView.searchQuery
                        RegExpFilter {
                            roleName: 'lang'
                            pattern: languageSelectionView.searchQuery
                        }
                        RegExpFilter {
                            roleName: 'name'
                            pattern: languageSelectionView.searchQuery
                        }
                    }

                    sorters: FilterSorter {
                        enabled: deviceLanguageSupported
                        ValueFilter {
                            enabled: deviceLanguageSupported
                            roleName: 'lang'
                            value: deviceLanguage
                        }
                    }
                }

                header: Column {
                    width: parent.width
                    property alias query: languageSearchField.text

                    PageHeader { title: qsTr("Language") }
                    SearchField {
                        id: languageSearchField
                        width: parent.width
                    }
                }

                delegate: BackgroundItem {
                    id: languageItem
                    height: languageColumn.height

                    onClicked: {
                        page.language = lang
                        pageStack.pop()
                    }

                    property bool isDeviceLanguage: deviceLanguageSupported && lang === deviceLanguage

                    Column {
                        id: languageColumn
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x

                        Label {
                            id: mainLabel
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: name || lang
                            highlighted: languageItem.highlighted || lang === page.language
                        }

                        Label {
                            width: parent.width
                            visible: !!name || isDeviceLanguage
                            height: visible ? implicitHeight : 0
                            font.pixelSize: Theme.fontSizeExtraSmall
                            wrapMode: Text.Wrap
                            text: isDeviceLanguage ?
                                      (name
                                       ? qsTr("%2Device Language%3 (%1)", "Indicator in language selection page for translation that a certain language is currently set as the device language").arg(lang)
                                       : '%1'+qsTr("Device Language")+'%2')
                                      .arg(highlighted ? '' : '<font color="'+Theme.secondaryHighlightColor+'">').arg(highlighted ? '' : '</font>')
                                    : lang
                            highlighted: mainLabel.highlighted
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Change language")
                onClicked: pageStack.push(languageSelectionPageComponent)
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
                onLinkActivated: utilities.handleLink(link)
            }
        }
    }

    PageBusyIndicator {
        running: translating
    }
}
