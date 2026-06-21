import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../pages"
import "../"
import "../../modules/Opal/Tabs"

TabItem {
    id: tabItem
    property bool loading
    property bool _loading: true
    //overrideable:
    property alias loadingVisible: busyLabel.running
    property alias loadingText: busyLabel.text

    property bool tabActive: tabIndex === tabView.currentIndex
    property bool active: Qt.application.active && chatInformationPage.status === PageStatus.Active && tabActive

    property Item scrollableView

    // FIXME: ideally we should rely on something more stable than timers with guessed intervals
    // also, this doesn't seem to really work generally
    Timer {
        id: loadingTimer
        interval: 150
        running: true // Run at startup
        onTriggered:
            _loading = loading
    }
    onLoadingChanged: {
        if (loading) {
            _loading = true
            loadingTimer.stop()
        } else
            loadingTimer.restart()
    }

    function handleScrollIntoView(force) {
        if (!_loading && !scrollableView.dragging && !scrollableView.quickScrollAnimating) {
            if (!scrollableView.atYBeginning)
                pageContent.scrollDown()
            //else pageContent.scrollUp(force)
        }
    }

    Connections {
        target: scrollableView
        ignoreUnknownSignals: true

        onDraggingChanged: handleScrollIntoView()
        onAtYBeginningChanged: handleScrollIntoView()
        onQuickScrollAnimatingChanged: handleScrollIntoView(true)
    }

    BusyLabel {
        id: busyLabel
        running: tabItem.loading
        visible: tabItem.loading
    }
}
