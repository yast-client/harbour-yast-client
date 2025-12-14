import QtQuick 2.0
import App.Logic 1.0

ChatInformationTabItemMediaBase {
    model: chatManager.animationMessagesModel
    viewModel: InvertedProxyModel {
        sourceModel: model
    }
}
