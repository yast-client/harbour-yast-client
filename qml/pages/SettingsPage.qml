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
import Sailfish.Pickers 1.0
import App.Logic 1.0
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
                text: qsTr("About Ferniegram")
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

            Loader {
                width: parent.width
                active: suggestedActionsManager.checkPhoneNumber && (!item || !item.transitionRunning)
                height: active ? implicitHeight : 0
                sourceComponent: Component {
                    SuggestedActionListItem {
                        id: checkPhoneNumberSuggestedAction
                        // TODO: properly format the phone number
                        title: qsTr("Is %1 still your number?").arg(tdLibWrapper.userInformation.phone_number)
                        description: qsTr("Keep your number up to date to ensure you can always log into Telegram.")
                        name: 'suggestedActionCheckPhoneNumber'
                        active: suggestedActionsManager.checkPhoneNumber

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
                                    onClicked: Qt.openUrlExternally(qsTr("https://telegram.org/faq#q-i-have-a-new-phone-number-what-do-i-do", "URL to the Telegram's FAQ about changing the phone number for this language. Keep unfinished if not available for your language"))
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                width: parent.width
                active: suggestedActionsManager.checkPassword && (!item || !item.transitionRunning)
                height: active ? implicitHeight : 0
                sourceComponent: Component {
                    SuggestedActionListItem {
                        id: checkPasswordSuggestedAction
                        title: qsTr("Do you still remember your password?")
                        description: qsTr("Check that you still remember your 2-Step Verification password to ensure you can always log into Telegram.")
                        name: 'suggestedActionCheckPassword'
                        active: suggestedActionsManager.checkPassword

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
            }
        }

        VerticalScrollDecorator {}
    }
}
