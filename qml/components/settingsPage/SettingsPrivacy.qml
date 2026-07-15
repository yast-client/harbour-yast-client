//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2021 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.6
import Sailfish.Silica 1.0
import io.yaqtlib 1.0
import '../../js/debug.js' as Debug

AccordionItem {
    name: "privacy"
    title: qsTr("Privacy")
    Component {
        Column {
            bottomPadding: Theme.paddingMedium
            Connections {
                target: tdLibWrapper
                onUserPrivacySettingUpdated: {
                    Debug.log("Received updated privacy setting: " + setting + ":" + rule);
                    switch (setting) {
                    case TDLibAPI.SettingAllowChatInvites:
                        allowChatInvitesComboBox.currentIndex = rule;
                        break;
                    case TDLibAPI.SettingAllowFindingByPhoneNumber:
                        allowFindingByPhoneNumberComboBox.currentIndex = rule;
                        break;
                    case TDLibAPI.SettingShowLinkInForwardedMessages:
                        showLinkInForwardedMessagesComboBox.currentIndex = rule;
                        break;
                    case TDLibAPI.SettingShowPhoneNumber:
                        showPhoneNumberComboBox.currentIndex = rule;
                        break;
                    case TDLibAPI.SettingShowProfilePhoto:
                        showProfilePhotoComboBox.currentIndex = rule;
                        break;
                    case TDLibAPI.SettingShowStatus:
                        showStatusComboBox.currentIndex = rule;
                        break;
                    }
                }
            }
            ResponsiveGrid {
                ComboBox {
                    id: allowChatInvitesComboBox
                    width: parent.columnWidth
                    label: qsTr("Allow chat invites")
                    description: qsTr("Privacy setting for managing whether you can be invited to chats.")
                    menu: ContextMenu {
                        x: 0
                        width: allowChatInvitesComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingAllowChatInvites, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingAllowChatInvites, TDLibAPI.RuleAllowContacts);
                            }
                        }
                        MenuItem {
                            text: qsTr("No")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingAllowChatInvites, TDLibAPI.RuleRestrictAll);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingAllowChatInvites);
                    }
                }

                ComboBox {
                    id: allowFindingByPhoneNumberComboBox
                    width: parent.columnWidth
                    label: qsTr("Allow finding by phone number")
                    description: qsTr("Privacy setting for managing whether you can be found by your phone number.")
                    menu: ContextMenu {
                        x: 0
                        width: allowFindingByPhoneNumberComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingAllowFindingByPhoneNumber, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingAllowFindingByPhoneNumber, TDLibAPI.RuleAllowContacts);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingAllowFindingByPhoneNumber);
                    }
                }

                ComboBox {
                    id: showLinkInForwardedMessagesComboBox
                    width: parent.columnWidth
                    label: qsTr("Show link in forwarded messages")
                    description: qsTr("Privacy setting for managing whether a link to your account is included in forwarded messages.")
                    menu: ContextMenu {
                        x: 0
                        width: showLinkInForwardedMessagesComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowLinkInForwardedMessages, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowLinkInForwardedMessages, TDLibAPI.RuleAllowContacts);
                            }
                        }
                        MenuItem {
                            text: qsTr("No")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowLinkInForwardedMessages, TDLibAPI.RuleRestrictAll);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingShowLinkInForwardedMessages);
                    }
                }

                ComboBox {
                    id: showPhoneNumberComboBox
                    width: parent.columnWidth
                    label: qsTr("Show phone number")
                    description: qsTr("Privacy setting for managing whether your phone number is visible.")
                    menu: ContextMenu {
                        x: 0
                        width: showPhoneNumberComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowPhoneNumber, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowPhoneNumber, TDLibAPI.RuleAllowContacts);
                            }
                        }
                        MenuItem {
                            text: qsTr("No")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowPhoneNumber, TDLibAPI.RuleRestrictAll);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingShowPhoneNumber);
                    }
                }

                ComboBox {
                    id: showProfilePhotoComboBox
                    width: parent.columnWidth
                    label: qsTr("Show profile photo")
                    description: qsTr("Privacy setting for managing whether your profile photo is visible.")
                    menu: ContextMenu {
                        x: 0
                        width: showProfilePhotoComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowProfilePhoto, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowProfilePhoto, TDLibAPI.RuleAllowContacts);
                            }
                        }
                        MenuItem {
                            text: qsTr("No")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowProfilePhoto, TDLibAPI.RuleRestrictAll);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingShowProfilePhoto);
                    }
                }

                ComboBox {
                    id: showStatusComboBox
                    width: parent.columnWidth
                    label: qsTr("Show status")
                    description: qsTr("Privacy setting for managing whether your online status is visible.")
                    menu: ContextMenu {
                        x: 0
                        width: showStatusComboBox.width

                        MenuItem {
                            text: qsTr("Yes")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowStatus, TDLibAPI.RuleAllowAll);
                            }
                        }
                        MenuItem {
                            text: qsTr("Your contacts only")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowStatus, TDLibAPI.RuleAllowContacts);
                            }
                        }
                        MenuItem {
                            text: qsTr("No")
                            onClicked: {
                                tdLibWrapper.setUserPrivacySettingRule(TDLibAPI.SettingShowStatus, TDLibAPI.RuleRestrictAll);
                            }
                        }
                    }

                    Component.onCompleted: {
                        currentIndex = tdLibWrapper.getUserPrivacySettingRule(TDLibAPI.SettingShowStatus);
                    }
                }
            }
        }
    }
}
