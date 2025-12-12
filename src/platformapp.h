#ifdef EDITION_SAILFISH
#include "sailfishapp.h"
#define PlatformApp SailfishApp
#endif

#ifdef EDITION_ASTEROID
#include <QSharedPointer>
#include <QGuiApplication>
#include <QUrl>

// Some things from sailfishapp which don't exist in asteroidapp (because we use some things asteroidapp doesn't generally recommend, like storing QML files in separate directory)

namespace PlatformApp {
    QUrl pathTo(const QString &filename);
    QUrl pathToMainQml();
}

namespace SailfishyAsteroidApp {
    void configureApp(QSharedPointer<QGuiApplication> app);
}
#endif
