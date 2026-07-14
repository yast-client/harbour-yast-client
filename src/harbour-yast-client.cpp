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
// QT_LOGGING_RULES="yaqtlib.*=true;yast-client.*=true" harbour-yast-client
#if defined (QT_DEBUG) || defined(DEBUG)
#  define DEFAULT_LOG_FILTER "yaqtlib.*=true\nyast-client.*=true"
#else
#  define DEFAULT_LOG_FILTER "yaqtlib.*=false\nyast-client.*=false"
#endif

#define JS_DEBUG_ROOT_MODULE "yast-client.JS"
#include "mainhelper.h"

#include "voicenoterecorder.h"

int main(int argc, char *argv[]) {
    QLoggingCategory::setFilterRules(DEFAULT_LOG_FILTER);

    QSharedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QSharedPointer<QQuickView> view(SailfishApp::createView());

    QQmlContext *context = view->rootContext();

    const QString dbusPath = "/io/roundedrectangle/yast";
    const QString dbusServiceName = "io.roundedrectangle.yast-client";

    const QUrl appIconPath = SailfishApp::pathTo("images/yast-client-notification.png"),
            incomingSoundPath = SailfishApp::pathTo("assets/message_incoming.wav"),
            outgoingSoundPath = SailfishApp::pathTo("assets/message_outgoing.wav");
    QScopedPointer<MainHelper::AppContext> appContext(MainHelper::registerTypes(argc, argv, view, "YAST", appIconPath, dbusPath, dbusServiceName, true,
                                                                                incomingSoundPath, outgoingSoundPath));

    QObject::connect(app.data(), &QGuiApplication::aboutToQuit, [&appContext]() {
        LOG("Disabling signal actions");
        // FIXME: activating some actions with app closed is still broken because of a race condition
        appContext->notificationManager.setUseSignalActions(false);
    });

    MainHelper::registerDBusService(app, view, dbusServiceName, dbusPath);

    MainHelper::registerDebugLogJS(appContext.data());

    const char *uri = "App.Logic";

    VoiceNoteRecorder *voiceNoteRecorder = new VoiceNoteRecorder(argc, argv, view.data());
    context->setContextProperty("voiceNoteRecorder", voiceNoteRecorder);
    qmlRegisterUncreatableType<VoiceNoteRecorder>(uri, 1, 0, "VoiceNoteRecorder", QString());

    view->rootContext()->setContextProperty("APP_VERSION", QString(APP_VERSION));
    view->rootContext()->setContextProperty("APP_RELEASE", QString(APP_RELEASE));

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
