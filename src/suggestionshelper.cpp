#include "suggestionshelper.h"
#include <QGuiApplication>

SuggestionsHelper::SuggestionsHelper(QObject *parent) : QObject(parent) {
    trySetInputItemFromParent();
}

SuggestionsHelper::~SuggestionsHelper() {
    applySuggestions({});
}

void SuggestionsHelper::trySetInputItemFromParent() {
    if (inputItem) return;

    QQuickItem *parentItem = qobject_cast<QQuickItem*>(parent());
    inputItem = findChildWithContents(parentItem);
    updateMetaProperty();
    if ((!inputItem || !textProperty.isValid()) && parentItem) { // for QML Loader
        parentItem = qobject_cast<QQuickItem*>(parentItem->parent());
        inputItem = findChildWithContents(parentItem);
        updateMetaProperty();
    }
    processSetInputItem();
}

void SuggestionsHelper::setInputItem(QObject *obj) {
    QQuickItem *item = qobject_cast<QQuickItem*>(obj);
    if (inputItem != item) {
        if (inputItem) {
            applySuggestions({});
            inputItem->removeEventFilter(this);
        }
        inputItem = item;
        updateMetaProperty();
        processSetInputItem();
        emit inputItemChanged();
    }
}

void SuggestionsHelper::processSetInputItem() {
    if (inputItem) {
        inputItem->installEventFilter(this);
        if (!suggestions.isEmpty()) applySuggestions();
    }
}

QQuickItem *SuggestionsHelper::findChildWithContents(QQuickItem *item) {
    if (item && !(item->flags() & QQuickItem::ItemAcceptsInputMethod)) {
        QList<QQuickItem *> children = item->childItems();
        for (QQuickItem *child : children) {
            QQuickItem *result = findChildWithContents(child);
            if (result) return result;
        }
    }

    return item;
}

void SuggestionsHelper::updateMetaProperty() {
    this->textProperty = {};
    disconnect(this->textChangedConnection);
    if (!autoFilter || !inputItem || suggestions.isEmpty()) return;

    const QMetaObject *metaObject = inputItem->metaObject();
    int index = metaObject->indexOfProperty("text");
    if (index != -1)
        this->textProperty = metaObject->property(index);
    if (!textProperty.isValid()) return;

    QMetaMethod signal = textProperty.notifySignal();
    if (signal.isValid()) {
        const QMetaObject *thisMetaObject = this->metaObject();
        int slotIndex = thisMetaObject->indexOfMethod("applySuggestions()");
        if (slotIndex != -1) {
            QMetaMethod slot = thisMetaObject->method(slotIndex);
            this->textChangedConnection = connect(inputItem, signal, this, slot);
        }
    }
}

void SuggestionsHelper::setSuggestions(const QStringList &suggestions) {
    this->suggestions = suggestions;
    emit suggestionsChanged();
    applySuggestions();
    updateMetaProperty();
}

void SuggestionsHelper::clear() {
    if (!suggestions.isEmpty()) setSuggestions({});
}

void SuggestionsHelper::setCanRemove(bool canRemove) {
    if (this->canRemove != canRemove) {
        this->canRemove = canRemove;
        emit canRemoveChanged();
        applySuggestions();
    }
}

void SuggestionsHelper::setAutoFilter(bool autoFilter) {
    if (this->autoFilter != autoFilter) {
        this->autoFilter = autoFilter;
        emit autoFilterChanged();
        if (!suggestions.isEmpty()) applySuggestions();
        updateMetaProperty();
    }
}

void SuggestionsHelper::applySuggestions(const QStringList &suggestions) {
    if (!inputItem) return;
    QStringList filteredSuggestions = suggestions;
    if (autoFilter && !suggestions.isEmpty()) {
        QString text = textProperty.read(inputItem).toString();
        if (!text.isEmpty()) {
            filteredSuggestions.clear();
            filteredSuggestions.reserve(suggestions.length());
            for (const QString &suggestion : suggestions)
                if (suggestion.startsWith(text) && suggestion != text)
                    filteredSuggestions.append(suggestion);
        }
    }

    inputItem->setProperty("__inputMethodExtensions", QVariantMap{
                               {"autoFillSuggestions", filteredSuggestions},
                               {"autoFillCanRemove", canRemove}
                           });

    if (inputItem->hasActiveFocus())
        QGuiApplication::inputMethod()->update(Qt::ImPlatformData);
}

bool SuggestionsHelper::eventFilter(QObject *obj, QEvent *event) {
    if (!inputItem || obj != inputItem)
        return QObject::eventFilter(obj, event);

    if (event->type() == QEvent::FocusIn) {
        applySuggestions();
        // should we do anything else here?
    } else if (event->type() == QEvent::KeyPress) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
        if (keyEvent->key() == Qt::Key_Delete && keyEvent->modifiers() == Qt::NoModifier) {
            emit suggestionRemoved(keyEvent->text());
            return true;
        }
    }

    return QObject::eventFilter(obj, event);
}
