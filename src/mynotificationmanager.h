#ifndef MYNOTIFICATIONMANAGER_H
#define MYNOTIFICATIONMANAGER_H

#include <notificationmanager.h>

class MyNotificationManager : public NotificationManager {
    Q_OBJECT
public:
    using NotificationManager::NotificationManager;

protected:
    virtual void playInChatSound(bool incoming, const QVariantMap &message) override;
};

#endif // MYNOTIFICATIONMANAGER_H
