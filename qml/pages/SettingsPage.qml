//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import io.yaqtlib 1.0
import "../components"
import "../components/settingsPage"
import "../js/functions.js" as Functions
import "../js/debug.js" as Debug

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    property string initialArea: 'profile'

    SilicaFlickable {
        id: settingsContainer
        contentHeight: column.height
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About YAST")
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutPage.qml"))
            }
        }

        Column {
            id: column
            width: settingsPage.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                title: qsTr("Settings")
            }

            AnimatedLoader {
                width: parent.width
                show: suggestedActionsManager.checkPhoneNumber
                sourceComponent: Component {
                    SuggestedActionListItem {
                        id: checkPhoneNumberSuggestedAction
                        // TODO: properly format the phone number
                        title: qsTr("Is %1 still your number?").arg(tdLibWrapper.userInformation.phone_number)
                        description: qsTr("Keep your number up to date to ensure you can always log into Telegram.")
                        name: 'suggestedActionCheckPhoneNumber'

                        menu: Component {
                            ContextMenu {
                                MenuItem {
                                    visible: false // TODO
                                    text: qsTr("Change phone number", "Button in the menu for suggestion to check if the phone number is still yours")
                                }
                                MenuItem {
                                    text: qsTr("Keep %1", "Button hiding the suggestion to check if the phone number is still yours").arg(tdLibWrapper.userInformation.phone_number)
                                    onClicked: checkPhoneNumberSuggestedAction.hide()
                                }
                                MenuItem {
                                    text: qsTr("Learn More", "Learn more about the suggestion to check if the phone number is still yours")
                                    onClicked: Qt.openUrlExternally(qsTr("https://telegram.org/faq#q-i-have-a-new-phone-number-what-do-i-do", "URL to the Telegram's FAQ about changing the phone number for this language. Keep unfinished or as-is if not available for your language"))
                                }
                            }
                        }
                    }
                }
            }

            AnimatedLoader {
                width: parent.width
                show: suggestedActionsManager.checkPassword
                sourceComponent: Component {
                    SuggestedActionListItem {
                        id: checkPasswordSuggestedAction
                        title: qsTr("Do you still remember your password?")
                        description: qsTr("Check that you still remember your 2-Step Verification password to ensure you can always log into Telegram.")
                        name: 'suggestedActionCheckPassword'

                        menu: Component {
                            ContextMenu {
                                MenuItem {
                                    visible: false // TODO
                                    text: qsTr("Verify Password", "Button in the menu for suggestion to check if you still remember your 2FA password")
                                }
                                MenuItem {
                                    text: qsTr("Hide Suggestion", "Button hiding the suggestion to check if you still remember your 2FA password").arg(tdLibWrapper.userInformation.phone_number)
                                    onClicked: checkPasswordSuggestedAction.hide()
                                }
                            }
                        }
                    }
                }
            }

            Accordion {
                flickable: settingsContainer
                Component.onCompleted: if (initialArea)
                                           setActiveArea(initialArea)

                SettingsUserProfile {}
                SettingsSession {}
                SettingsPrivacy {}
                SettingsBehavior {}
                SettingsArchiveChatList {}
                SettingsAppearance {}
                SettingsStorage {}
                SettingsAdvanced {}
            }
        }

        VerticalScrollDecorator {}
    }
}
