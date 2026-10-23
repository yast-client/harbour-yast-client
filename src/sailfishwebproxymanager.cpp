//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "sailfishwebproxymanager.h"
#include "sailfishapp.h"

#include <QQmlComponent>
#include <QQuickItem>

#define DEBUG_ROOT_MODULE "yast-client"
#define DEBUG_MODULE SailfishWebProxyManager
#include "debuglog.h"

SailfishWebProxyCarrier::SailfishWebProxyCarrier(int id, const QString &url, const QString &origin, const QString &pathPrefix, SailfishWebProxyManager *parent)
    : WebProxyCarrier(parent), id(id)
{
    QSharedPointer<QQuickView> view = parent->view;
    QQmlEngine *engine = view->engine();
    QQmlComponent component(engine, SailfishApp::pathTo("qml/components/WebProxyCarrier.qml"));
    this->webView = component.beginCreate(view->rootContext()); // don't use create() just in case

    if (!webView) {
        WARN("Couldn't create web view for the web proxy" << id << component.errors());
        if (component.isError())
            parent->tdLibWrapper->reportWebProxyCarrierError(id, component.errors().first().toString());
        else
            parent->tdLibWrapper->reportWebProxyCarrierError(id, TDLibWrapper::WebProxyCarrierErrorTerminated);
        return;
    }

    QQuickItem *webItem = qobject_cast<QQuickItem*>(webView);
    if (webItem) webItem->setParentItem(view->rootObject());

    webView->setProperty("carrierId", id);
    webView->setProperty("proxyUrl", url);
    webView->setProperty("origin", origin);
    webView->setProperty("pathPrefix", pathPrefix);

    component.completeCreate();
}

SailfishWebProxyCarrier::~SailfishWebProxyCarrier() {
    webView->deleteLater();
}

void SailfishWebProxyCarrier::processData(const QString &data) {
    auto fail = [this]() { qobject_cast<SailfishWebProxyManager*>(parent())->tdLibWrapper->reportWebProxyCarrierError(id); };
    if (!webView) return fail();
    bool ok = QMetaObject::invokeMethod(webView, "postMessage", Q_ARG(QVariant, data));
    if (!ok) fail();
}

SailfishWebProxyManager::SailfishWebProxyManager(QSharedPointer<QQuickView> view, TDLibWrapper *tdLibWrapper, QObject *parent)
    : WebProxyManager(tdLibWrapper, parent), view(view)
{}
