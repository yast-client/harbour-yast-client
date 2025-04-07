import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../js/functions.js" as Functions

Item {
    id: wallpaper
    property var background
    property bool highlighted
    //property alias highlighted: photo.highlighted
    //property alias photo: photo

    //property alias typePattern: typePattern

    readonly property string backgroundType: background ? background.type['@type'] : ''
    Component.onCompleted: if (backgroundType) console.log(JSON.stringify(background.type))

    BackgroundImage {
        visible: baseLoader.status != Loader.Ready
    }

    Loader {
        id: baseLoader
        anchors.fill: parent
        sourceComponent:
            switch(backgroundType) {
            case 'backgroundTypeWallpaper':
                return typeWallpaper
            case 'backgroundTypeFill':
            case 'backgroundTypePattern':
                switch(background.type.fill['@type']) {
                case 'backgroundFillSolid':
                    return typeFillSolid
                case 'backgroundFillGradient':
                    return typeFillGradient
                case 'backgroundFillFreeformGradient':
                    return typeFillFreeformGradient
                }
            }
    }

    Component {
        id: typeWallpaper
        TDLibPhoto {
            id: photo
            anchors.fill: parent
            highlighted: wallpaper.highlighted
            minithumbnail: background.document && background.document.minithumbnail ? background.document.minithumbnail : null
            image.fileInformation: background.document && background.document.document ? background.document.document : {}
            showPlaceholder: backgroundType != 'backgroundTypePattern'
            image.opacity: image.status === Image.Ready ? (backgroundType == 'backgroundTypePattern' ? background.type.intensity/100 : 1.0) : 0.0
        }
    }

    Component {
        id: typeFillSolid
        Rectangle {
            anchors.fill: parent
            color: Functions.rrggbb(background.type.fill.color)
        }
    }

    Component {
        id: typeFillGradient
        Rectangle {
            anchors.fill: parent
            rotation: background.type.fill.rotation_angle
            gradient: Gradient {
                GradientStop {
                    color: Functions.rrggbb(background.type.fill.bottom_color)
                    position: 0
                }
                GradientStop {
                    color: Functions.rrggbb(background.type.fill.top_color)
                    position: 1
                }
            }
            Component.onCompleted: console.log(Functions.rrggbb(background.type.fill.bottom_color),Functions.rrggbb(background.type.fill.top_color))
        }
    }

    Component {
        id: gradientStopComponent
        GradientStop{}
    }

    Component {
        id: typeFillFreeformGradient
        ConicalGradient {
            anchors.fill: parent
            gradient: Gradient {
                id: freeformGradient
                property real positionDecimial: background.type.fill.colors.length > 2 ? 1/(background.type.fill.colors.length-1) : 0
                /*Repeater {
                    model: background.type.fill.colors
                    GradientStop {
                        color: Functions.rrggbb(modelData)
                        position: switch(index) {
                                  case 0: return 0
                                  case background.type.fill.colors.length-1: return 1
                                  default: return freeformGradient.positionDecimial*index
                                  }
                    }
                }*/
                // Repeater{} does not work...
                Component.onCompleted: {
                    var list=[]
                    background.type.fill.colors.forEach(function(color, i) {
                        var index
                        switch(i) {
                        case 0: index=0;break
                        case background.type.fill.colors.length-1: index=1;break
                        default: index = freeformGradient.positionDecimial*i
                        }

                        list.push(gradientStopComponent.createObject(null,
                            {color: Functions.rrggbb(color), position: index}
                        ))
                    })
                    stops=list
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: backgroundType === 'backgroundTypeWallpaper' && baseLoader.item && baseLoader.item.image.visible && background.type.is_blurred
        sourceComponent: Component {
            FastBlur {
                anchors.fill: parent
                source: baseLoader
                // tdlib documentation recommends this: https://core.telegram.org/tdlib/docs/classtd_1_1td__api_1_1background_type_wallpaper.html#ae467b6442a914d5c39acf198c67c2805
                radius: Theme.itemSizeSmall
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: backgroundType == 'backgroundTypePattern'
        sourceComponent: typeWallpaper
    }
}
