#include "mainshared.h"

#include <asteroidapp.h>
#include <QQuickView>
//#include <QtQml>
#include <QQmlEngine>
#include <QGuiApplication>
#include "platformapp.h"

int main(int argc, char *argv[]) {
    MainShared::setupLogging();

    QSharedPointer<QGuiApplication> app(AsteroidApp::application(argc, argv));
    QSharedPointer<QQuickView> view(AsteroidApp::createView()); // FIXME: should we actually use QScopedPointer here?

    SailfishyAsteroidApp::configureApp(app);

    //QQmlContext *context = view.data()->rootContext();

    app->setOrganizationName("io.github.roundedrectangle");
    app->setOrganizationDomain("io.github.roundedrectangle");
    app->setApplicationName("fernschreiber2");

    QScopedPointer<MainShared::AppContext> appContext(MainShared::registerTypes(argc, argv, view));

    view->setSource(PlatformApp::pathToMainQml());
    view->show();
    return app->exec();
}
