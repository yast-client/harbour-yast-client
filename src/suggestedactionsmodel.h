#ifndef SUGGESTEDACTIONSMODEL_H
#define SUGGESTEDACTIONSMODEL_H

#include <QAbstractListModel>
#include "tdlibwrapper.h"

class SuggestedActionsModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum SuggestedActionRole {
        RoleDisplay = Qt::DisplayRole,
        RoleType
    };

    explicit SuggestedActionsModel(TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    virtual QHash<int,QByteArray> roleNames() const override;
    virtual int rowCount(const QModelIndex &) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE bool isConversionToBroadcastGroupSuggested(qlonglong supergroupId);

signals:
    void conversionToBroadcastGroupSuggested(qlonglong supergroupId);

private:
    TDLibWrapper* tdLibWrapper;
    QVariantList suggestedActions;
    QSet<qlonglong> conversionToBroadcastGroupsSuggestions;

    void handleSuggestedActionsUpdated(const QVariantList added, const QVariantList removed);
};

#endif // SUGGESTEDACTIONSMODEL_H
