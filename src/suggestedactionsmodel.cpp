#include "suggestedactionsmodel.h"

namespace {
    const QString _TYPE("@type");
    const QString TYPE_SUGGESTED_ACTION_CONVERT_TO_BROADCAST_GROUP("suggestedActionConvertToBroadcastGroup");
    const QString SUPERGROUP_ID("supergroup_id");

    // special case for: suggestedActionConvertToBroadcastGroup
    const QStringList SUPPORTED_SUGGESTED_ACTIONS{}; // currently none (TODO)
}

SuggestedActionsModel::SuggestedActionsModel(TDLibWrapper *tdLibWrapper, QObject *parent) :
    QAbstractListModel(parent),
    tdLibWrapper(tdLibWrapper) {
    connect(tdLibWrapper, &TDLibWrapper::suggestedActionsUpdated, this, &SuggestedActionsModel::handleSuggestedActionsUpdated);
}

QHash<int, QByteArray> SuggestedActionsModel::roleNames() const {
    return QHash<int,QByteArray>{
        {SuggestedActionRole::RoleDisplay, "display"},
        {SuggestedActionRole::RoleType, "type"}
    };
}

int SuggestedActionsModel::rowCount(const QModelIndex &) const {
    return suggestedActions.size();
}

QVariant SuggestedActionsModel::data(const QModelIndex &index, int role) const {
    if (index.isValid()) {
        const QVariantMap suggestedAction = suggestedActions.value(index.row()).toMap();
        switch (static_cast<SuggestedActionRole>(role)) {
            case SuggestedActionRole::RoleDisplay: return suggestedAction;
            case SuggestedActionRole::RoleType: return suggestedAction.value(_TYPE).toString();
        }
    }
    return QVariant();
}

void SuggestedActionsModel::handleSuggestedActionsUpdated(const QVariantList added, const QVariantList removed) {
    for (const QVariant &removedVariant : removed) {
        const QVariantMap action = removedVariant.toMap();
        const QString actionType = action.value(_TYPE).toString();

        if (actionType == TYPE_SUGGESTED_ACTION_CONVERT_TO_BROADCAST_GROUP)
            this->conversionToBroadcastGroupsSuggestions.remove(action.value(SUPERGROUP_ID).toLongLong());

        if (SUPPORTED_SUGGESTED_ACTIONS.contains(actionType))
            this->suggestedActions.removeAll(action);
    }

    for (const QVariant &addedVariant : added) {
        const QVariantMap action = addedVariant.toMap();
        const QString actionType = action.value(_TYPE).toString();

        if (actionType == TYPE_SUGGESTED_ACTION_CONVERT_TO_BROADCAST_GROUP)
            this->conversionToBroadcastGroupsSuggestions.insert(action.value(SUPERGROUP_ID).toLongLong());

        if (SUPPORTED_SUGGESTED_ACTIONS.contains(actionType))
            this->suggestedActions.append(action);
    }
}

bool SuggestedActionsModel::isConversionToBroadcastGroupSuggested(qlonglong supergroupId) {
    return this->conversionToBroadcastGroupsSuggestions.contains(supergroupId);
}
