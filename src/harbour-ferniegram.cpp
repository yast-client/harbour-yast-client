/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/

#include "ferniemain.h"

#include <sailfishapp.h>
#include <QQuickView>
//#include <QtQml>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QSysInfo>
#include <QSettings>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

#include "voicenoterecorder.h"

int main(int argc, char *argv[]) {
    FernieMain::setupLogging();

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QSharedPointer<QQuickView> view(SailfishApp::createView());

    QQmlContext *context = view->rootContext();

    const QString dbusPath = "/io/ferniegram/ferniegram";
    const QString dbusServiceName = "io.ferniegram.ferniegram";

    QScopedPointer<FernieMain::AppContext> appContext(FernieMain::registerTypes(argc, argv, view, dbusPath, dbusServiceName));

    FernieMain::registerDBusService(view, dbusPath, dbusServiceName);
    // FIXME: there's a short period of time when the application closes (waiting for tdlib to close),
    // but the dbus service isn't unregistered yet, in which clicking the application doesn't open it.
    // Seems like SailfishOS uses X-Maemo-Method not only for opening URLs, but for opening the app itself too

    VoiceNoteRecorder *voiceNoteRecorder = new VoiceNoteRecorder(argc, argv, view.data());
    context->setContextProperty("voiceNoteRecorder", voiceNoteRecorder);
    qmlRegisterUncreatableType<VoiceNoteRecorder>(appContext->uri, 1, 0, "VoiceNoteRecorder", QString());

#ifdef NO_HARBOUR_COMPLIANCE
    context->setContextProperty("NO_HARBOUR_COMPLIANCE", true);
#else
    context->setContextProperty("NO_HARBOUR_COMPLIANCE", false);
#endif

    view->setSource(SailfishApp::pathTo("qml/harbour-ferniegram.qml"));
    view->show();
    return app->exec();
}
