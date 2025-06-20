import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

RadialGradient {
    // white background = invisible button. I can't tell since which SFOS version the opaque button is available, so:
    id: buttonBg
    width: Theme.iconSizeLarge
    height: Theme.iconSizeLarge

    property color baseColor: Theme.rgba(palette.overlayBackgroundColor, 0.2)
    gradient: Gradient {
        GradientStop { position: 0.0; color: buttonBg.baseColor }
        GradientStop { position: 0.3; color: buttonBg.baseColor }
        GradientStop { position: 0.5; color: 'transparent' }
    }

    property alias button: button
    property alias down: button.down
    property alias icon: button.icon
    property alias highlighted: button.highlighted
    signal clicked

    IconButton {
        id: button
        anchors.fill: parent
        onClicked: buttonBg.clicked()

        icon {
            asynchronous: true
            sourceSize {
                width: buttonBg.width
                height: buttonBg.height
            }
        }
    }
}
