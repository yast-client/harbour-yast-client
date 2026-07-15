//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "mynotificationmanager.h"
#include "utilities.h"
#include "sailfishapp.h"

void MyNotificationManager::playInChatSound(bool incoming, const QVariantMap &message) {
    const QString text = utilities->getMessageText(message).trimmed().toLower();
    if (text == "sus")
        NotificationManager::playInChatSound(SailfishApp::pathTo("assets/sus.mp3").toLocalFile());
    else
        NotificationManager::playInChatSound(incoming, message);
}
