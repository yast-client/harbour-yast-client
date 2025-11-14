
/*
    Copyright (C) 2020-21 Sebastian J. Wolf and other contributors

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
import WerkWolf.Fernschreiber 1.0
import "../components"
import "../modules/Opal/About"

AboutPageBase {
    id: aboutPage
    allowedOrientations: Orientation.All

    _pageHeaderItem.title: qsTr("About Ferniegram")
    appName: "Ferniegram 0.1"
    appIcon: Qt.resolvedUrl("../../images/fernschreiber2.svg")
    _iconItem.width: Math.min(2 * Theme.itemSizeHuge, Math.min(aboutPage.width, aboutPage.height) / 2)
    _iconItem.height: _iconItem.width
    _iconItem.asynchronous: true
    _iconItem.sourceSize.width: _iconItem.width
    _iconItem.sourceSize.height: _iconItem.height
    description: qsTr("A Telegram client for Sailfish OS")
    sourcesUrl: "https://github.com/roundedrectangle/harbour-fernschreiber2"
    autoAddOpalAttributions: true
    licenses: License{ spdxId: 'GPL-3.0-only' }

    authors: ["roundedrectangle"]
    contributionSections: [
        /*ContributionSection { // TODO: add this when necessary
            title: qsTr("Development")
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
                    entries: "roundedrectangle"
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
    attributions: [
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
                License{
                    spdxId: 'MIT'
                    customShortText: qsTr("Coding")
                },
                License{
                    spdxId: 'CC-BY 4.0'
                    customShortText: qsTr("Graphics")
                }
            ]
            sources: "https://github.com/twitter/twemoji"
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
