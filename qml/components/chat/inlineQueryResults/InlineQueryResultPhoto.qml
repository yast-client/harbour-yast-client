import QtQuick 2.6
import "../../"

InlineQueryResult {
    id: queryResultItem

    TDLibPhoto {
        anchors.fill: parent
        photo: model.photo
    }
}
