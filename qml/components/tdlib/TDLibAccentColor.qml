import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../js/functions.js" as Functions

QtObject {
    property int colorId: -1

    readonly property bool builtIn: colorId >= 0 && colorId <= 6
    property var accentColor: tdData.getAccentColor(colorId)
    readonly property bool invalid: !builtIn && !accentColor
    readonly property int builtInColorId: invalid ? -1 : (builtIn ? colorId : accentColor.built_in_accent_color_id)
    readonly property int minChannelChatBoostLevel: accentColor ? accentColor.min_channel_chat_boost_level : -1

    readonly property color builtInColorBase: invalid ? 'black'
                                                        // 0-6: red, orange, purple/violet, green, cyan, blue, pink
                                                      : (['red', 'orangered', 'purple', 'green', 'cyan', 'blue', 'deeppink'][builtInColorId])
    readonly property color builtInColor: Theme.highlightFromColor(builtInColorBase, Theme.colorScheme)
    readonly property color buitInSecondaryColor: Theme.secondaryHighlightFromColor(builtInColorBase, Theme.colorScheme)

    readonly property var colors: {
        if (invalid) return []
        if (builtIn) return [builtInColor, buitInSecondaryColor]

        var rgbColors = Theme.colorScheme == Theme.LightOnDark ? accentColor.dark_theme_colors : accentColor.light_theme_colors
        var result = []
        for (var i=0; i < rgbColors.length; i++)
            result.push(Functions.getRgbColor(rgbColors[i]))
        return result
    }

    readonly property Connections tdListener: Connections {
        target: builtIn || colorId == -1 ? null : tdData
        ignoreUnknownSignals: true
        onAccentColorsUpdated: accentColor = Qt.binding(function() { return tdData.getAccentColor(colorId) })
    }
}
