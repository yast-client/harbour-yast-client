import QtQuick 2.6
import Sailfish.Silica 1.0

ListItem {
    id: listItem
    width: parent.width

    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    property string name

    property bool active: true
    property bool transitionRunning: transition.running

    contentHeight: column.height

    opacity: active ? 1 : 0
    height: active ? implicitHeight : 0

    states: [
        State {
            name: "active"
            PropertyChanges {
                target: listItem
                opacity: 1
                height: listItem.implicitHeight
            }
        },
        State {
            name: "inactive"
            PropertyChanges {
                target: listItem
                opacity: 0
                height: 0
            }
        }

    ]

    transitions: Transition {
        id: transition
        FadeAnimator {}
        NumberAnimation {
            property: 'height'
            duration: 200
        }
    }

    function hide() {
        tdLibWrapper.hideSuggestedAction(name)
    }

    onClicked: openMenu()

    Column {
        id: column
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        spacing: Theme.paddingMedium
        bottomPadding: Theme.paddingMedium

        Label {
            id: titleLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeMedium
            //color: Theme.highlightColor
            font.bold: true
        }

        Label {
            id: descriptionLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
