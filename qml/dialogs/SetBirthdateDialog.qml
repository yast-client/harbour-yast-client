import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property alias date: datePicker.date

    function yearIsValid(year) {
        var currentYear = new Date().getFullYear()
        return year >= (currentYear - 150) && year <= currentYear
    }

    readonly property bool validYear: yearIsValid(datePicker.year)

    property bool canRemove: true
    property bool remove

    onAccepted: {
        if (remove)
            tdLibWrapper.setBirthdate()
        else
            tdLibWrapper.setBirthdate(datePicker.day, datePicker.month, validYear ? datePicker.year : 0)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: canRemove
            MenuItem {
                text: qsTr("Remove birthday")
                onClicked: {
                    remove = true
                    accept()
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                id: header
                title: qsTr("Your birthday")
            }

            BackgroundItem {
                contentHeight: dateLabel.height + 2*Theme.paddingSmall

                Label {
                    id: dateLabel
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: (screen.sizeCategory > Screen.Medium) ? Theme.fontSizeExtraLarge : Theme.fontSizeLarge
                    // FIXME: if Format.DateLongWithoutYear would exist it would fit here more (instead of DateFullWithoutYear), ideally this could be achieved with a custom format but we need to ensure it will work fine with all locales and everything
                    text: Format.formatDate(datePicker.date, validYear ? Format.DateLong : Format.DateFullWithoutYear)
                    wrapMode: Text.Wrap
                }

                onClicked: pageStack.push(yearSelectionPageComponent)
            }

            DatePicker {
                id: datePicker
            }
        }
    }

    Component {
        id: yearSelectionPageComponent
        Page {
            id: yearSelectionPage
            allowedOrientations: dialog.allowedOrientations

            property int initialYear
            property int selectedYear

            Component.onCompleted:
                initialYear = datePicker.year

            ListView {
                id: yearSelectionView
                anchors.fill: parent
                orientation: Qt.Vertical

                model: ListModel {
                    Component.onCompleted: {
                        var currentYear = new Date().getFullYear()
                        var start = currentYear - 150
                        for (var i = start; i <= currentYear; i++)
                            append({year: i})
                        append({year: 1800})

                        if (initialYear !== 0 && initialYear >= start && initialYear <= currentYear)
                            yearSelectionView.positionViewAtIndex(initialYear - start, ListView.Center)
                        else
                            yearSelectionView.positionViewAtEnd()
                    }
                }

                delegate: ListItem {
                    id: yearItem

                    width: parent.width
                    contentHeight: yearLabel.height
                    onClicked: {
                        yearSelectionPage.selectedYear = model.year
                        openMenu()
                    }

                    Label {
                        id: yearLabel
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeHuge
                        color: (!yearIsValid(model.year) && !yearIsValid(yearSelectionPage.initialYear)) || model.year === yearSelectionPage.initialYear || highlighted
                               ? Theme.highlightColor : Theme.primaryColor
                        text: yearIsValid(model.year) ? model.year : '—'
                    }

                    menu: Component {
                        ContextMenu {
                            Grid {
                                width: parent.width
                                columns: Screen.sizeCategory > Screen.Medium || !isPortrait ? 6 : 3

                                Repeater {
                                    model: 12
                                    delegate: BackgroundItem {
                                        width: parent.width / parent.columns
                                        height: Theme.itemSizeHuge

                                        onClicked: {
                                            datePicker.showMonth(index + 1, yearSelectionPage.selectedYear)
                                            yearItem.closeMenu()
                                            pageStack.pop()
                                        }

                                        Label {
                                            id: monthNumberLabel
                                            anchors {
                                                centerIn: parent
                                                verticalCenterOffset: -monthNameLabel.height/2
                                            }
                                            font.pixelSize: Theme.fontSizeHuge
                                            color: highlighted ? Theme.highlightColor : Theme.secondaryHighlightColor
                                            text: (index >= 9 ? '' : '0') + (index + 1)
                                        }
                                        Label {
                                            id: monthNameLabel

                                            anchors.top: monthNumberLabel.bottom
                                            x: Theme.paddingSmall / 2
                                            width: parent.width - 2*x
                                            horizontalAlignment: Text.AlignHCenter
                                            fontSizeMode: Text.HorizontalFit
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: highlighted ? Theme.highlightColor : Theme.secondaryHighlightColor
                                            text: Format.formatDate(new Date(2000, index, 2), Format.MonthNameStandalone)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
