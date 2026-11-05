#pragma once

#include <QObject>
#include <QQuickItem>
#include <QBasicTimer>

// TODO: package this as an Opal module

// See https://github.com/sailfishos/maliit-framework/tree/master/rpm/0006-Forward-arbitrary-extension-properties-to-QML-input-.patch
// https://github.com/sailfishos/qtmozembed/blob/5e4216ec497837399de731cf76558ee1b10f5496/src/qmozview_p.cpp#L2949

class SuggestionsHelper : public QObject, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(QObject *inputItem MEMBER inputItem WRITE setInputItem NOTIFY inputItemChanged)
    Q_PROPERTY(QStringList suggestions MEMBER suggestions WRITE setSuggestions NOTIFY suggestionsChanged)
    Q_PROPERTY(bool canRemove MEMBER canRemove WRITE setCanRemove NOTIFY canRemoveChanged)
    Q_PROPERTY(bool autoFilter MEMBER autoFilter WRITE setAutoFilter NOTIFY autoFilterChanged)
public:
    explicit SuggestionsHelper(QObject *parent = nullptr);
    ~SuggestionsHelper();

    void setInputItem(QObject *item);
    void setSuggestions(const QStringList &suggestions);
    Q_INVOKABLE void clear();
    void setCanRemove(bool canRemove);
    void setAutoFilter(bool autoFilter);

    inline virtual void classBegin() override {}
    inline virtual void componentComplete() override { trySetInputItemFromParent(); }

public slots:
    void applySuggestions(const QStringList &suggestions);
    inline void applySuggestions() { applySuggestions(this->suggestions); }

signals:
    void inputItemChanged();
    void suggestionsChanged();
    void canRemoveChanged();
    void suggestionRemoved(const QString &suggestion);
    void autoFilterChanged();

protected:
    virtual bool eventFilter(QObject *obj, QEvent *event) override;

private:
    void trySetInputItemFromParent();
    static QQuickItem *findChildWithContents(QQuickItem *parent);
    void processSetInputItem();
    void updateMetaProperty();

    QQuickItem *inputItem = nullptr;
    QStringList suggestions;
    bool canRemove = true;
    bool autoFilter = false;
    QMetaProperty textProperty;
    QMetaObject::Connection textChangedConnection;
};
