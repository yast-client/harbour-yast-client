// Some things from sailfishapp which don't exist in asteroidapp (because we use some things asteroidapp doesn't generally recommend, like storing QML files in separate directory)

namespace SailfishyAsteroidApp {
    QString appName();
    QString dataDir();
    QUrl pathTo(const QString &filename);
    QUrl pathToMainQml();
    void configureApp(QSharedPointer<QGuiApplication> app);
}
#endif