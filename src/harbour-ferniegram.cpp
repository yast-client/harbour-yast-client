#include <sailfishapp.h>
#include <QQuickView>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QSysInfo>
#include <QSettings>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

// The default filter can be overridden by QT_LOGGING_RULES envinronment variable, e.g.
// QT_LOGGING_RULES="libfernie.*=true;ferniegram.*=true" harbour-ferniegram
#if defined (QT_DEBUG) || defined(DEBUG)
#  define DEFAULT_LOG_FILTER "libfernie.*=true\nferniegram.*=true"
#else
#  define DEFAULT_LOG_FILTER "libfernie.*=false\nferniegram.*=false"
#endif

#define JS_DEBUG_ROOT_MODULE "ferniegram.JS"
#include "ferniemain.h"

#include "voicenoterecorder.h"

int main(int argc, char *argv[]) {
    QLoggingCategory::setFilterRules(DEFAULT_LOG_FILTER);

    QSharedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QSharedPointer<QQuickView> view(SailfishApp::createView());

    QQmlContext *context = view->rootContext();

    const QString dbusPath = "/io/ferniegram/ferniegram",
            dbusServiceName = "io.ferniegram.ferniegram",
            // Lipstick opens the app when DBus service name matches the one in the .desktop file
            dbusServiceName2 = "io.ferniegram.ferniegram2";

    const QUrl appIconPath = SailfishApp::pathTo("images/ferniegram-notification.png");
    QScopedPointer<FernieMain::AppContext> appContext(FernieMain::registerTypes(argc, argv, view, "Ferniegram", appIconPath, dbusPath, dbusServiceName2));

    QObject::connect(app.data(), &QGuiApplication::aboutToQuit, [&appContext, dbusServiceName]() {
        LOG("Setting normal DBus service name");
        // TODO: mark as read and reply with app closed still doesn't work because of a race condition
        appContext->notificationManager.setDbusServiceName(dbusServiceName);
    });

    FernieMain::registerDBusService(app, view, dbusServiceName, dbusPath);
    FernieMain::registerDBusService(app, view, dbusServiceName2);

    FernieMain::registerDebugLogJS(appContext.data());

    const char *uri = "App.Logic";

    VoiceNoteRecorder *voiceNoteRecorder = new VoiceNoteRecorder(argc, argv, view.data());
    context->setContextProperty("voiceNoteRecorder", voiceNoteRecorder);
    qmlRegisterUncreatableType<VoiceNoteRecorder>(uri, 1, 0, "VoiceNoteRecorder", QString());

#ifdef NO_HARBOUR_COMPLIANCE
    context->setContextProperty("NO_HARBOUR_COMPLIANCE", true);
#else
    context->setContextProperty("NO_HARBOUR_COMPLIANCE", false);
#endif

    // Disable quitOnLastWindowClosed so closing a call window wouldn't quit the application
    app->setQuitOnLastWindowClosed(false);
    QObject::connect(view.data(), SIGNAL(closing(QQuickCloseEvent*)), app.data(), SLOT(quit()));

    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
