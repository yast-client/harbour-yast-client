import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

RadialGradient {
    // white background = invisible button. I can't tell since which SFOS version the opaque button is available, so:
    id: background
    width: Theme.iconSizeLarge
    height: Theme.iconSizeLarge

    property color baseColor: Theme.rgba(palette.overlayBackgroundColor, 0.2)
    gradient: Gradient {
        GradientStop { position: 0.0; color: background.baseColor }
        GradientStop { position: 0.3; color: background.baseColor }
        GradientStop { position: 0.5; color: 'transparent' }
    }
}
