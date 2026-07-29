//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <notificationmanager.h>

class MyNotificationManager : public NotificationManager {
    Q_OBJECT
public:
    using NotificationManager::NotificationManager;

protected:
    virtual void playInChatSound(bool incoming, const QVariantMap &message) override;
};
