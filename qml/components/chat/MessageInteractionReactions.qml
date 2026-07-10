import QtQuick 2.0
import Sailfish.Silica 1.0
import '..'
import '../../js/functions.js' as Functions

Loader {
    // TODO: animate choosing a reaction

    property var reactions
    property bool invertLayout

    width: parent.width
    asynchronous: true
    active: reactions.length > 0
    height: active ? implicitHeight : 0

    sourceComponent: Component {
        Flow {
            width: parent.width
            spacing: Theme.paddingSmall
            layoutDirection: invertLayout ? Qt.RightToLeft : Qt.LeftToRight
            Repeater {
                model: reactions
                Rectangle {
                    visible: reactionLoader.supported
                    height: Theme.fontSizeSmall + Theme.paddingSmall
                    width: childrenRect.width + Theme.paddingSmall
                    radius: width

                    color: modelData.is_chosen ? Theme.rgba(Theme.highlightBackgroundColor, 0.6) : Theme.rgba(Theme.secondaryColor, Theme.highlightBackgroundOpacity)

                    MessageReaction {
                        id: reactionLoader
                        x: Theme.paddingSmall
                        y: x
                        height: parent.height - y*2
                        width: height
                        type: modelData.type
                    }

                    RecentActorsList {
                        id: recentReactors
                        height: parent.height
                        anchors {
                            left: reactionLoader.right
                            leftMargin: Theme.paddingSmall/2
                        }
                        inverted: true
                        model: modelData.recent_sender_ids.reverse()
                    }

                    Text {
                        anchors {
                            left: reactionLoader.right
                            leftMargin: visible ? (recentReactors.count > 0 ? (Theme.paddingSmall + parent.height + Math.max(0, Theme.paddingMedium*(recentReactors.count - 1))) : Theme.paddingSmall/2) : 0
                        }
                        visible: (modelData.total_count - recentReactors.count) > 0
                        width: visible ? implicitWidth : 0
                        text: Functions.getShortenedCount(modelData.total_count)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: modelData.is_chosen ? Theme.highlightColor : Theme.primaryColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        // TODO: check if you can actually add the reaction
                        onClicked:
                            switch (modelData.type['@type']) {
                            case 'reactionTypeEmoji':
                            case 'reactionTypeCustomEmoji':
                                if (modelData.is_chosen)
                                    tdLibWrapper.removeMessageReaction(chatId, messageId, modelData.type)
                                else
                                    tdLibWrapper.addMessageReaction(chatId, messageId, modelData.type)
                                break
                            //case 'reactionTypePaid':
                            //    ...
                            }
                    }
                }
            }
        }
    }
}
