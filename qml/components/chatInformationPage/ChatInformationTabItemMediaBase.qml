ChatInformationTabItemBase {
    loading: scrollableView.count == 0

    function jumpToMessage(id) {
        chatManager.model.loadHistoryForMessage(id) // FIXME: need to use chatPage.showMessage (improves performance in case message is already loaded and shows an animation after message is shown). Need to map album messages to main album message though
        appWindow.pageStack.navigateBack()
    }
}
