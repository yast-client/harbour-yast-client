import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQml.Models 2.3
import io.yaqtlib 1.0
import '../js/debug.js' as Debug

Dialog {
    id: dialog
    allowedOrientations: Orientation.All
    backNavigation: false

    property bool initial
    property bool _loading: true
    property bool wasActive
    readonly property bool loading: _loading || !wasActive || !contentLoader.item

    acceptDestination: Qt.resolvedUrl('InitializationDialog.qml')
    canAccept: false

    signal doneAccepted
    onAccepted:
        if (tdLibWrapper.authorizationState != TDLibAPI.AuthorizationReady)
            doneAccepted()

    function handleAuthorizationState() {
        Debug.log("Authorization state updated", tdLibWrapper.authorizationState, JSON.stringify(tdLibWrapper.authorizationStateData))
        if (tdLibWrapper.authorizationState == TDLibAPI.AuthorizationReady) {
            acceptDestination = null
            canAccept = true
            _loading = true
            pageStack.completeAnimation()
            accept()
            return
        }

        _loading = false
    }

    Connections {
        target: tdLibWrapper
        onAuthorizationStateChanged: handleAuthorizationState()
        onErrorReceived: _loading = false
    }

    onStatusChanged:
        if (status == PageStatus.Active)
            wasActive = true

    Component.onCompleted: {
        wasActive = status == PageStatus.Active
        if (initial)
            handleAuthorizationState()
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About YAST")
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Proxy settings")
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/ProxiesPage.qml"))
            }
            MenuItem {
                text: "Debug"
                visible: DebugLog.enabled
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/DebugPage.qml"), {overviewPage: pageStack.find(function (page) { return page.objectName === 'overviewPage' })})
            }
            MenuItem {
                text: qsTr("Visit telegram.org", "Visit telegram.org to download an official app for purchasing the Telegram Premium subscription")
                visible: tdLibWrapper.authorizationState == TDLibAPI.WaitPremiumPurchase
                onClicked: Qt.openUrlExternally("https://telegram.org/")
            }
        }

        DialogHeader {
            id: dialogHeader
            title: {
                if (loading) return ''

                switch (tdLibWrapper.authorizationState) {
                case TDLibAPI.WaitPhoneNumber:
                    return qsTr("Your Phone")
                case TDLibAPI.WaitCode:
                    return qsTr("Confirmation Code")
                case TDLibAPI.WaitPassword:
                    return qsTr("Two-Step Verification")
                case TDLibAPI.WaitEmailAddress:
                    return qsTr("Your Email")
                case TDLibAPI.WaitEmailCode:
                    return qsTr("Confirmation code", "email")
                case TDLibAPI.WaitRegistration:
                    return qsTr("Registration")
                default:
                    return ''
                }
            }
            acceptText: {
                if (loading) return defaultAcceptText

                switch (tdLibWrapper.authorizationState) {
                case TDLibAPI.WaitCode:
                    return qsTr("Confirm", "confirmation code")
                case TDLibAPI.WaitEmailAddress:
                    return qsTr("Confirm", "email code")
                case TDLibAPI.WaitRegistration:
                    return qsTr("Sign Up")
                default:
                    return defaultAcceptText
                }
            }
        }

        SilicaFlickable {
            id: flickable
            width: parent.width
            anchors {
                top: dialogHeader.bottom
                bottom: parent.bottom
            }
            contentHeight: contentLoader.height

            BusyLabel {
                running: loading
            }

            Loader {
                id: contentLoader
                width: parent.width
                focus: true // required for focusing a text field on start
                opacity: wasActive && item ? 1 : 0
                Behavior on opacity { FadeAnimator {} }

                asynchronous: true
                sourceComponent: {
                    if (_loading || !wasActive)
                        return null

                    switch (tdLibWrapper.authorizationState) {
                    case TDLibAPI.WaitPhoneNumber:
                        return phoneNumberComponent
                    case TDLibAPI.WaitCode:
                        return codeComponent
                    case TDLibAPI.WaitPassword:
                        return passwordComponent
                    case TDLibAPI.WaitRegistration:
                        return registrationComponent
                    case TDLibAPI.WaitEmailAddress:
                        return emailAddressComponent
                    case TDLibAPI.WaitEmailCode:
                        return emailCodeComponent
                    case TDLibAPI.WaitPremiumPurchase:
                        return premiumPurchaseComponent
                    default:
                        return unsupportedComponent
                    }
                }

                Component {
                    id: phoneNumberComponent

                    Column {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        TextField {
                            id: phoneField
                            label: qsTr("Phone number")
                            description: qsTr("Use the international format, e.g. %1").arg("+4912342424242")
                            inputMethodHints: Qt.ImhDialableCharactersOnly
                            focus: true

                            validator: RegExpValidator { regExp: /\+[1-9][0-9]{4,}/g }
                            EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                            EnterKey.enabled: acceptableInput
                            EnterKey.onClicked: accept()

                            Binding {
                                target: dialog
                                property: 'canAccept'
                                value: phoneField.acceptableInput
                            }
                            Connections {
                                target: dialog
                                onDoneAccepted:
                                    tdLibWrapper.setAuthenticationPhoneNumber(phoneField.text)
                            }
                        }
                    }
                }

                Component {
                    id: codeComponent
                    TextField {
                        id: codeField

                        property bool isDigit:
                            switch (tdLibWrapper.authorizationStateData.type['@type']) {
                            case 'authenticationCodeTypeCall':
                            case 'authenticationCodeTypeFragment':
                            case 'authenticationCodeTypeMissedCall':
                            case 'authenticationCodeTypeTelegramMessage':
                                return true
                            default:
                                // Other known authorization code types are either disabled when providing the phone number setting or are only supported by official apps
                                // Just in case, we remove all restrictions for these kinds of codes
                                return false
                            }

                        placeholderText:
                            switch (tdLibWrapper.authorizationStateData.code_info.type['@type']) {
                            case 'authenticationCodeTypeMissedCall':
                                return qsTr("Last %Ln digits", '', tdLibWrapper.authorizationStateData.code_info.type.length)
                            default:
                                return qsTr("Code")
                            }
                        focus: true

                        IntValidator {
                            id: digitCodeValidator
                            bottom: 10 ^ tdLibWrapper.authorizationStateData.code_info.type.length
                            top: 10 ^ (tdLibWrapper.authorizationStateData.code_info.type.length + 1) - 1
                        }
                        validator: isDigit ? digitCodeValidator : null
                        inputMethodHints: Qt.ImhDigitsOnly

                        description: {
                            var phoneText = '<b>' + tdLibWrapper.authorizationStateData.code_info.phone_number + '</b>'

                            switch (tdLibWrapper.authorizationStateData.code_info.type['@type']) {
                            case 'authenticationCodeTypeCall':
                                return qsTr("Calling your phone %1 to dictate the code.").arg(phoneText)
                            case 'authenticationCodeTypeFragment':
                                return qsTr("Get the code for %1 in the Numbers section on Fragment.").arg(phoneText)
                            case 'authenticationCodeTypeMissedCall':
                                return qsTr("Within next few seconds you should receive a short call from a phone number which starts with %1.").arg(phoneText)
                            case 'authenticationCodeTypeTelegramMessage':
                                return qsTr("We've sent the code to the Telegram app on your other device.")
                            default:
                                return ''
                            }
                        }

                        labelComponent: Label {
                            width: parent.width
                            visible: tdLibWrapper.authorizationStateData.code_info.type['@type'] == 'authenticationCodeTypeFragment'
                            text: visible ? ('<a href="%1">'.arg(tdLibWrapper.authorizationStateData.code_info.type.url) + qsTr("Open Fragment") + '</a>') : ''
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Fade

                            linkColor: highlighted ? Theme.highlightColor : Theme.secondaryHighlightColor
                            onLinkActivated: Qt.openUrlExternally(link)
                        }
                        hideLabelOnEmptyField: false

                        EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                        EnterKey.enabled: acceptableInput
                        EnterKey.onClicked: accept()

                        Binding {
                            target: dialog
                            property: 'canAccept'
                            value: codeField.acceptableInput
                        }
                        Connections {
                            target: dialog
                            onDoneAccepted:
                                tdLibWrapper.checkAuthenticationCode(codeField.text)
                        }
                    }
                }

                Component {
                    id: passwordComponent
                    PasswordField {
                        id: passwordField
                        placeholderText: qsTr("Password")
                        label: qsTr("Hint: %1", "Password hint").arg(tdLibWrapper.authorizationStateData.password_hint)
                        hideLabelOnEmptyField: false
                        description: qsTr("You have enabled Two-Step Verification, so your account is protected with an additional password.")
                        focus: true

                        acceptableInput: !!text

                        EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                        EnterKey.enabled: acceptableInput
                        EnterKey.onClicked: accept()

                        Binding {
                            target: dialog
                            property: 'canAccept'
                            value: passwordField.acceptableInput
                        }
                        Connections {
                            target: dialog
                            onDoneAccepted:
                                tdLibWrapper.checkAuthenticationPassword(passwordField.text)
                        }
                    }
                }

                Component {
                    id: emailAddressComponent
                    TextField {
                        id: emailField
                        placeholderText: qsTr("Email address")
                        description: qsTr("Please enter your valid email address.")
                        focus: true

                        validator: RegExpValidator { regExp: /^\S+@\S+\.\S+$/ }

                        EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                        EnterKey.enabled: acceptableInput
                        EnterKey.onClicked: accept()

                        Binding {
                            target: dialog
                            property: 'canAccept'
                            value: emailField.acceptableInput
                        }
                        Connections {
                            target: dialog
                            onDoneAccepted:
                                tdLibWrapper.setAuthenticationEmailAddress(emailField.text)
                        }
                    }
                }

                Component {
                    id: emailCodeComponent
                    TextField {
                        id: emailCodeField
                        placeholderText: qsTr("Code", "email")
                        description: qsTr("We've sent a %Ln-digit recovery code to %1. Please check your email and enter it here.",
                                          "%1 is the email address", tdLibWrapper.authorizationStateData.type.code_info.length)
                            .arg(tdLibWrapper.authorizationStateData.type.code_info.email_address_pattern)
                        focus: true

                        validator: IntValidator {
                            id: digitCodeValidator
                            bottom: 10 ^ tdLibWrapper.authorizationStateData.type.code_info.length
                            top: 10 ^ (tdLibWrapper.authorizationStateData.type.code_info.length + 1) - 1
                        }
                        inputMethodHints: Qt.ImhDigitsOnly

                        EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                        EnterKey.enabled: acceptableInput
                        EnterKey.onClicked: accept()

                        Binding {
                            target: dialog
                            property: 'canAccept'
                            value: emailCodeField.acceptableInput
                        }
                        Connections {
                            target: dialog
                            onDoneAccepted:
                                tdLibWrapper.checkAuthenticationEmailCode(emailCodeField.text)
                        }
                    }
                }

                Component {
                    id: premiumPurchaseComponent
                    Item {
                        width: parent.width
                        height: flickable.height

                        ViewPlaceholder {
                            text: qsTr("Telegram Premium required")
                            hintText: qsTr("Telegram Premium is required to proceed. Unfortunately, it's currently not possible to make in-app purchases through YAST. Please use one of Telegram's official apps and enter the same phone number to set up the subscription, after which you can return to singing in to YAST.\n\nPull down to visit telegram.org")
                        }
                    }
                }

                Component {
                    id: registrationComponent
                    Column {
                        width: parent.width
                        anchors.topMargin: Theme.paddingLarge

                        Column {
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2*x
                            spacing: Theme.paddingMedium
                            bottomPadding: Theme.paddingLarge

                            Label {
                                width: parent.width
                                text: qsTr("By accepting, you agree to the Telegram Terms of Service:")
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeMedium
                                wrapMode: Text.Wrap
                            }

                            Label {
                                width: parent.width
                                text: utilities.enhanceMessageText(tdLibWrapper.authorizationStateData.terms_of_service.text)
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.Wrap
                            }
                        }

                        IconTextSwitch {
                            id: disableNotificationSwitch
                            icon.source: 'image://theme/icon-m-contact'
                            text: qsTr("Notify my contacts")
                            description: qsTr("Notify your contacts that you joined Telegram")
                            checked: true
                        }

                        TextField {
                            id: firstNameField
                            placeholderText: qsTr("First name")
                            acceptableInput: !!text
                            focus: true

                            rightItem: Icon {
                                source: "image://theme/icon-splus-asterisk"
                                color: Theme.highlightColor
                            }

                            EnterKey.iconSource: 'image://theme/icon-m-enter-next'
                            EnterKey.enabled: acceptableInput
                            EnterKey.onClicked: lastNameField.focus = true
                        }

                        TextField {
                            id: lastNameField
                            placeholderText: qsTr("Last name")

                            EnterKey.iconSource: 'image://theme/icon-m-enter-accept'
                            EnterKey.enabled: firstNameField.acceptableInput
                            EnterKey.onClicked: accept()
                        }

                        Binding {
                            target: dialog
                            property: 'canAccept'
                            value: firstNameField.acceptableInput
                        }
                        Connections {
                            target: dialog
                            onDoneAccepted:
                                tdLibWrapper.registerUser(firstNameField.text, lastNameField.text, !disableNotificationSwitch.checked)
                        }
                    }
                }

                Component {
                    id: unsupportedComponent
                    Item {
                        width: parent.width
                        height: flickable.height

                        ViewPlaceholder {
                            text: qsTr("Unsupported authorization mode")
                            hintText: qsTr("Sorry, this authorization mode is not yet supported: %1").arg(tdLibWrapper.authorizationStateData['@type'])
                        }
                    }
                }
            }
        }
    }
}
