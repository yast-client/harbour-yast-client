//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "sailfishwebproxymanager.h"
#include "sailfishapp.h"

#include <QQmlComponent>
#include <QQuickItem>
#include <QTimer>

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
    if (!webView) return;
    if (dataEverProcessed && sendWebViewData(CLOSE_DATA))
        QTimer::singleShot(200, webView, &QObject::deleteLater);
    else
        webView->deleteLater();
}

bool SailfishWebProxyCarrier::sendWebViewData(const QString &data) {
    return QMetaObject::invokeMethod(webView, "postMessage", Q_ARG(QVariant, data));
}

void SailfishWebProxyCarrier::processData(const QString &data) {
    if (webView && sendWebViewData(data))
        dataEverProcessed = true;
    else
        qobject_cast<SailfishWebProxyManager*>(parent())->tdLibWrapper->reportWebProxyCarrierError(id);
}

SailfishWebProxyManager::SailfishWebProxyManager(QSharedPointer<QQuickView> view, TDLibWrapper *tdLibWrapper, QObject *parent)
    : WebProxyManager(tdLibWrapper, parent), view(view)
{}
