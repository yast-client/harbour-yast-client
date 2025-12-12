#ifdef EDITION_ASTEROID
/*
 * Copyright (C) 2025 roundedrectangle
 * Copyright (C) 2013 - 2014 Jolla Ltd.
 * Contact: Thomas Perl <thomas.perl@jollamobile.com>
 * All rights reserved.
 *
 * This file is part of Fernschreiber2
 *
 * You may use this file under the terms of the GNU Lesser General
 * Public License version 2.1 as published by the Free Software Foundation
 * and appearing in the file license.lgpl included in the packaging
 * of this file.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 * and appearing in the file license.lgpl included in the packaging
 * of this file.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 */

#include "platformapp.h"

#include <QLocale>
#include <QTranslator>
#include <QDir>
#include <QCoreApplication>

static QString applicationPath() {
    QString argv0 = QCoreApplication::arguments()[0];

    if (argv0.startsWith(QChar('/'))) {
        // First, try argv[0] if it's an absolute path (needed for booster)
        return argv0;
    } else {
        // If that doesn't give an absolute path, use /proc-based detection
        return QCoreApplication::applicationFilePath();
    }
}

static QString appName() {
    return QFileInfo(applicationPath()).fileName();
}

static QString dataDir() {
    return applicationPath().section('/', 0, -3) + "/share/" + appName();
}

namespace PlatformApp {
    QUrl pathTo(const QString &filename) {
        return QUrl::fromLocalFile(QDir::cleanPath(dataDir() + '/' + filename));
    }

    QUrl pathToMainQml() {
        return pathTo("qml/" + appName() + ".qml");
    }
}

namespace SailfishyAsteroidApp {
    void configureApp(QSharedPointer<QGuiApplication> app) {
        QString translations = PlatformApp::pathTo("translations").toString();
        if (QDir(translations).exists()) {
            QTranslator *translator = new QTranslator();
            translator->load(QLocale::system(), appName(), "-", translations, ".qm");
            app->installTranslator(translator);
        }
    }
}
#endif
