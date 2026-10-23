//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "webproxymanager.h"
#include <QQuickView>

class SailfishWebProxyManager;

class SailfishWebProxyCarrier : public WebProxyCarrier {
public:
    explicit SailfishWebProxyCarrier(int id, const QString &url, const QString &origin, const QString &pathPrefix, SailfishWebProxyManager *parent);
    ~SailfishWebProxyCarrier();

    virtual void processData(const QString &data) override;

private:
    int id;
    QObject *webView;
};

class SailfishWebProxyManager : public WebProxyManager {
    Q_OBJECT
public:
    explicit SailfishWebProxyManager(QSharedPointer<QQuickView> view, TDLibWrapper *tdLibWrapper, QObject *parent = nullptr);

    friend class SailfishWebProxyCarrier;

protected:
    virtual inline WebProxyCarrier *createCarrier(int id, const QString &url, const QString &origin, const QString &pathPrefix) override {
        return new SailfishWebProxyCarrier(id, url, origin, pathPrefix, this);
    }

private:
    QSharedPointer<QQuickView> view;
};
