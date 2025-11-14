import QtQuick 2.0
import WerkWolf.Fernschreiber 1.0

ChatInformationTabItemMediaBase {
    model: chatManager.photoAndVideoMessagesModel
    viewModel: InvertedProxyModel {
        sourceModel: model
    }
}