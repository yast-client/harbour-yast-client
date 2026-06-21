import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../js/functions.js" as Functions

Grid {
    width: parent.width - ( 2 * x )
    columns: Functions.isWidescreen(appWindow) ? 2 : 1
    readonly property real columnWidth: width/columns
}
