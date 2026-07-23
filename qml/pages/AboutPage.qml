//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import "../components"
import "../modules/Opal/About"

AboutPageBase {
    id: aboutPage
    allowedOrientations: Orientation.All

    _pageHeaderItem.title: qsTr("About YAST")
    appName: "YAST Client"
    appIcon: Qt.resolvedUrl("../../images/yast-client.svg")
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    _iconItem.width: Math.min(2 * Theme.itemSizeHuge, Math.min(aboutPage.width, aboutPage.height) / 2)
    _iconItem.height: _iconItem.width
    _iconItem.asynchronous: true
    _iconItem.sourceSize.width: _iconItem.width
    _iconItem.sourceSize.height: _iconItem.height
    description: qsTr("A Telegram client for Sailfish OS")
    sourcesUrl: "https://github.com/roundedrectangle/harbour-yast-client"
    autoAddOpalAttributions: true
    licenses: License { spdxId: 'GPL-3.0-only' }

    authors: ["roundedrectangle"]
    contributionSections: [
        /*ContributionSection {
            title: qsTr("Development")
            groups: [
                ContributionGroup {
                    title: qsTr("A useful feature")
                    entries: ["John Doe", "Jane Doe", "..."]
                },
                // ...
            ]
        },*/
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup {
                    title: qsTr("Italian")
                    entries: "247"
                },
                ContributionGroup {
                    title: qsTr("Russian")
                    entries: ["roundedrectangle", "windes14"]
                }

            ]
        },
        ContributionSection {
            title: qsTr("Fernschreiber translations")
            groups: [
                ContributionGroup {
                    title: qsTr("Chinese")
                    entries: "dashinfantry"
                },
                ContributionGroup {
                    title: qsTr("Finnish")
                    entries: "jorm1s"
                },
                ContributionGroup {
                    title: qsTr("French")
                    entries: ["Patrick Hervieux", "Nicolas Bourdais"]
                },
                ContributionGroup {
                    title: qsTr("Hungarian")
                    entries: "edp17"
                },
                ContributionGroup {
                    title: qsTr("Italian")
                    entries: "Matteo"
                },
                ContributionGroup {
                    title: qsTr("Polish")
                    entries: "atlochowski"
                },
                ContributionGroup {
                    title: qsTr("Russian")
                    entries: ["Rustem Abzalov", "Slava Monich"]
                },
                ContributionGroup {
                    title: qsTr("Slovak")
                    entries: "okruhliak"
                },
                ContributionGroup {
                    title: qsTr("Spanish")
                    entries: "carlosgonz"
                },
                ContributionGroup {
                    title: qsTr("Swedish")
                    entries: "Åke Engelbrektson"
                }
            ]
        }
    ]

    property list<Attribution> baseAttributions: [
        Attribution {
            name: "Fernschreiber"
            description: qsTr("This application is a fork of Fernschreiber, and wouldn't be possible without it. Thanks to everyone who developed and contributed to it!")
            licenses: License { spdxId: 'GPL-3.0-only' }
            entries: ["Sebastian J. Wolf", "Slava Monich", "jgibbon", "Christian Stemmle", "santhoshmanikandan", "Peter G.", "Johannes Bachmann", "Mikhail Barashkov", "Matteo"]
            sources: "https://github.com/Wunderfitz/harbour-fernschreiber"
        },
        Attribution {
            name: "TDLib"
            description: qsTr("Telegram Database Library (TDLib)")
            licenses: License { spdxId: 'BSL-1.0' }
            sources: "https://github.com/tdlib/td"
        },
        Attribution {
            name: "Twemoji"
            description: qsTr("This project uses twemoji. Thanks for making it available under the conditions of the MIT License (coding) and CC-BY 4.0 (graphics)!")
            entries: ["2022–present Jason Sofonia & Justine De Caires", "2014–2021 Twitter"]
            licenses: [
                License {
                    spdxId: 'MIT'
                    customShortText: qsTr("Coding")
                },
                License {
                    spdxId: 'CC-BY 4.0'
                    customShortText: qsTr("Graphics")
                }
            ]
            sources: "https://github.com/jdecked/twemoji"
        },
        Attribution {
            name: "rlottie"
            entries: ["2020 Samsung Electronics Co., Ltd.", qsTr("other contributors")]
            licenses: License { spdxId: 'MIT' }
            sources: "https://github.com/Samsung/rlottie"
        },
        Attribution {
            name: "Nominatim"
            description: qsTr("This project uses OpenStreetMap Nominatim for reverse geocoding of location attachments. Thanks for making it available as web service!")
            sources: "https://wiki.openstreetmap.org/wiki/Nominatim"
        }
    ]
    property list<Attribution> customAttributions: [
        Attribution {
            name: "tgcalls"
            entries: "2020 The Telegram Calls Library Authors"
            licenses: License { spdxId: 'LGPL-3.0-only' }
            sources: "https://github.com/TelegramMessenger/tgcalls"
        },
        Attribution {
            name: "WebRTC (tg_owt)"
            entries: "2011, The WebRTC project authors"
            licenses: License { spdxId: 'BSD-3-Clause' }
            sources: "https://github.com/desktop-app/tg_owt"
        },
        Attribution {
            name: "openh264"
            entries: "2013, Cisco Systems"
            licenses: License { spdxId: 'BSD-2-Clause' }
            sources: "https://github.com/cisco/openh264"
        }
    ]

    attributions: {
        var result = []
        for (var i=0; i < baseAttributions.length; i++)
            result.push(baseAttributions[i])

        if (NO_HARBOUR_COMPLIANCE)
            for (i=0; i < customAttributions.length; i++)
                result.push(customAttributions[i])
        return result
    }

    function openTMeUrl(path) {
        tdLibWrapper.getInternalLinkType(tdLibWrapper.options.t_me_url + path)
    }

    extraSections: [
        InfoSection {
            title: qsTr("About Telegram")
            text: qsTr("This product uses the Telegram API but is not endorsed or certified by Telegram.")
            buttons: [
                InfoButton {
                    text: qsTr("Terms of Service")
                    onClicked: Qt.openUrlExternally("https://telegram.org/tos")
                },
                InfoButton {
                    text: qsTr("Privacy Policy")
                    onClicked: Qt.openUrlExternally("https://telegram.org/privacy")
                }
            ]
        },
        InfoSection {
            text: qsTr("TDLib version %1 (commit hash %2)").arg(tdLibWrapper.options.version).arg(tdLibWrapper.options.commit_hash)
        },
        InfoSection {
            visible: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady
            buttons: [
                InfoButton {
                    text: qsTr("News")
                    onClicked: openTMeUrl("+klEzuTNf7iYyODYy")
                },
                InfoButton {
                    text: qsTr("Features", "Opens Telegram Tips channel")
                    onClicked: openTMeUrl(qsTr('TelegramTips', "Username of the localized Telegram Tips channel. Keep unfinished or as-is if not available for your language"))
                },
                InfoButton {
                    text: qsTr("Ask a Question", "Contact support")
                    onClicked: pageStack.push(Qt.resolvedUrl('../dialogs/ContactSupportDialog.qml'))
                }
            ]
        },
        InfoSection {
            visible: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady
            title: qsTr("SailfishOS Resources")
            smallPrint: qsTr("To get more info on SailfishOS, consider joining these groups and channels.")

            buttons: [
                InfoButton {
                    text: qsTr("International Fan Club", "Button which opens the SailfishOS Fan Club group")
                    onClicked: openTMeUrl("+KeJKDDA60uU2M2Q0")
                },
                InfoButton {
                    text: qsTr("News Network", "Button which opens the Sailfish OS News Network channel")
                    onClicked: openTMeUrl("sailfishosnews")
                },
                InfoButton {
                    text: qsTr("Community meeting", "Button which opens the SailfishOS Meeting channel")
                    onClicked: openTMeUrl("+AAAAAFcbasJX67Fu-aGxxQ")
                }
            ]
        },
        InfoSection {
            visible: tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady
            title: qsTr("English-speaking resources", "Change `English` to the name of your language")
            visible: firstExtraButton.enabled || secondExtraButton.enabled
            Component.onCompleted: console.log(firstExtraButton.text, firstExtraButton.link, secondExtraButton.text, secondExtraButton.link)
            buttons: [
                // qsTrId would fit better here, but lrelease doesn't support using both source and ID-based strings
                InfoButton {
                    id: firstExtraButton
                    text: qsTr('extra_resource_title_1', "Extra resource link title #1. See here for more info: https://github.com/yast-client/harbour-yast-client/blob/main/doc/translating.md#extra-resource-links")
                    property string link: qsTr('extra_resource_link_path_1', "Extra resource link path #1. See here for more info: https://github.com/yast-client/harbour-yast-client/blob/main/doc/translating.md#extra-resource-links")
                    enabled: !!(text && link) && text != 'extra_resource_title_1' && link != 'extra_resource_link_path_1'
                    onClicked: openTMeUrl(link)
                },
                InfoButton {
                    id: secondExtraButton
                    text: qsTr('extra_resource_title_2', "Extra resource link title #2. See here for more info: https://github.com/yast-client/harbour-yast-client/blob/main/doc/translating.md#extra-resource-links")
                    property string link: qsTr('extra_resource_link_path_2', "Extra resource link path #2. See here for more info: https://github.com/yast-client/harbour-yast-client/blob/main/doc/translating.md#extra-resource-links")
                    enabled: !!(text && link) && text != 'extra_resource_title_2' && link != 'extra_resource_link_path_2'
                    onClicked: openTMeUrl(link)
                }
            ]
        }
    ]

    property int iconClicks
    MouseArea {
        parent: _iconItem
        anchors.fill: parent
        onClicked: {
            if (DebugLog.enabled) {
                appNotification.show(qsTr("Not needed, debug mode is already enabled."))
                return
            }

            iconClicks++
            resetIconClicksTimer.restart()
            if (iconClicks >= 3)
                appNotification.show(qsTr("You are now %n steps away from enabling debug mode", '', 7 - iconClicks))

            if (iconClicks == 7) {
                DebugLog.enabled = true
                appNotification.show(qsTr("Debug mode is now enabled!"))
            }
        }
    }

    Timer {
        id: resetIconClicksTimer
        interval: 1000
        onTriggered: iconClicks = 0
    }
}
