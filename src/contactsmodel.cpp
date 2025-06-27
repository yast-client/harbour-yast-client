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

#include "contactsmodel.h"
#include <QListIterator>

#define DEBUG_MODULE ContactsModel
#include "debuglog.h"

namespace {
    const QString STATUS("status");
    const QString ID("id");
    const QString TYPE("type");
    const QString FIRST_NAME("first_name");
    const QString LAST_NAME("last_name");
    const QString USERNAME("username");
    const QString _TYPE("@type");
    const QString _EXTRA("@extra");
}

ContactsModel::ContactsModel(TDLibWrapper *tdLibWrapper, QObject *parent)
    : QAbstractListModel(parent)
{
    this->tdLibWrapper = tdLibWrapper;
    connect(this->tdLibWrapper, &TDLibWrapper::usersReceived, this, &ContactsModel::handleUsersReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::userUpdated, this, &ContactsModel::handleUserUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::contactsImported, this, &ContactsModel::handleContactsImported);
    connect(this->tdLibWrapper, &TDLibWrapper::okMapReceived, this, &ContactsModel::handleOkMapReceived);
}

QHash<int, QByteArray> ContactsModel::roleNames() const {
    QHash<int,QByteArray> roles;
    roles.insert(ContactRole::RoleDisplay, "display");
    roles.insert(ContactRole::RoleTitle, "title");
    roles.insert(ContactRole::RoleUserId, "user_id");
    roles.insert(ContactRole::RoleUsername, "username");
    roles.insert(ContactRole::RolePhotoSmall, "photo_small");
    roles.insert(ContactRole::RoleUserStatus, "user_status");
    roles.insert(ContactRole::RoleUserLastOnline, "user_last_online");
    roles.insert(ContactRole::RoleFilter, "filter");
    return roles;
}

int ContactsModel::rowCount(const QModelIndex &) const {
    return this->contactIds.size();
}

QVariant ContactsModel::data(const QModelIndex &index, int role) const {
    if (index.isValid()) {
        QVariantMap requestedContact = this->tdLibWrapper->getUserInformation(this->contactIds.value(index.row()));
        switch (static_cast<ContactRole>(role)) {
            case ContactRole::RoleDisplay: return requestedContact;
            case ContactRole::RoleTitle: return QString(requestedContact.value("first_name").toString() + " " + requestedContact.value("last_name").toString()).trimmed();
            case ContactRole::RoleUserId: return requestedContact.value("id");
            case ContactRole::RoleUsername: return requestedContact.value("usernames").toMap().value("editable_username").toString();
            case ContactRole::RolePhotoSmall: return requestedContact.value("profile_photo").toMap().value("small");
            case ContactRole::RoleUserStatus: return requestedContact.value("status").toMap().value("@type");
            case ContactRole::RoleUserLastOnline: return requestedContact.value("status").toMap().value("was_online");
            case ContactRole::RoleFilter: return QString(requestedContact.value("first_name").toString() + " " + requestedContact.value("last_name").toString() + " " + requestedContact.value("usernames").toMap().value("editable_username").toString()).trimmed();
        }
    }
    return QVariant();
}

void ContactsModel::addUser(const QString &userId) {
    if (!this->tdLibWrapper->hasUserInformation(userId)) {
        this->tdLibWrapper->getUserFullInfo(userId);
    }
    this->contactIds.append(userId);
}

void ContactsModel::handleUsersReceived(const QString &extra, const QVariantList &userIds, int totalUsers)
{
    if (extra == "contactsRequested") {
        LOG("Received contacts list..." << totalUsers);
        this->contactIds.clear();
        for (const QVariant &userIdVariant : userIds)
            addUser(userIdVariant.toString());

        std::sort(this->contactIds.begin(), this->contactIds.end(),
                  [this](const QString &a, const QString &b) { return compareUsers(a, b); }
        );
    }
}

void ContactsModel::handleUserUpdated(const QString &userId) {
    int i = contactIds.indexOf(userId);
    if (i > -1) {
        const QModelIndex modelIndex = index(i);
        emit dataChanged(modelIndex, modelIndex);
        LOG("Updated user" << userId << data(modelIndex, ContactRole::RoleUserStatus));


        //auto newIndex = std::upper_bound(contactIds.begin(), contactIds.end(), i);//, [this](const QString &a, const QString &b) { return compareUsers(a, b); });
        //newIndex;
        //QModelIndex parent;
        //beginMoveRows(parent, a, b, parent, c);
        // todo: sort, and somehow notify the model about this...
    }
}

void ContactsModel::handleContactsImported(const QVariantList &/*importerCount*/, const QVariantList &userIds, bool /*single*/) {
    LOG("Imported" << userIds.size() << "contacts");
    for (const QVariant &userIdVariant : userIds) {
        beginInsertRows(QModelIndex(), contactIds.size(), contactIds.size());
        addUser(userIdVariant.toString());
        endInsertRows();
    }
    // todo: sort
}

void ContactsModel::handleOkMapReceived(const QString &type, const QVariantMap &extra) {
    if (type == "removeContacts") {
        QStringList list = extra["user_ids"].toStringList();
        LOG("Removed" << list.size() << "contacts");
        if (list.isEmpty()) return;

        for (QString userId : list) {
            int i = contactIds.indexOf(userId);
            if (i < 0) return;
            beginRemoveRows(QModelIndex(), i, i);
            contactIds.removeAt(i);
            endRemoveRows();
            // here no need to sort
        }
        contactsRemoved(list.size() == 1);
    }
}

bool ContactsModel::compareUsers(const QString &userId1, const QString &userId2) {
    const QVariantMap user1 = this->tdLibWrapper->getUserInformation(userId1);
    const QVariantMap user2 = this->tdLibWrapper->getUserInformation(userId2);

    const QString lastName1 = user1.value(LAST_NAME).toString();
    const QString lastName2 = user2.value(LAST_NAME).toString();
    if (!lastName1.isEmpty()) {
        if (lastName1 < lastName2) {
            return true;
        } else if (lastName1 > lastName2) {
            return false;
        }
    }

    const QString firstName1 = user1.value(FIRST_NAME).toString();
    const QString firstName2 = user2.value(FIRST_NAME).toString();
    if (firstName1 < firstName2) {
        return true;
    } else if (firstName1 > firstName2) {
        return false;
    }
    const QString userName1 = user1.value(USERNAME).toString();
    const QString userName2 = user2.value(USERNAME).toString();
    if (userName1 < userName2) {
        return true;
    } else if (userName1 > userName2) {
        return false;
    }
    return user1.value(ID).toLongLong() < user2.value(ID).toLongLong();
}

void ContactsModel::startImportingContacts()
{
    this->deviceContacts.clear();
}

void ContactsModel::stopImportingContacts(bool singleContact) {
    if (!deviceContacts.isEmpty()) {
        LOG("Importing found contacts" << deviceContacts.size());
        this->tdLibWrapper->importContacts(deviceContacts, singleContact);
    }
}

void ContactsModel::importContact(const QString &firstName, const QString &lastName, const QString &phoneNumber) {
    deviceContacts.append(QVariantMap{{FIRST_NAME, firstName}, {LAST_NAME, lastName}, {"phone_number", phoneNumber}});
    LOG("Found contact" << firstName << lastName << phoneNumber);
}

void ContactsModel::importContact(const QVariantMap &singlePerson)
{
    QString firstName = singlePerson.value("firstName").toString();
    QVariantList phoneNumbers = singlePerson.value("phoneNumbers").toList();
    if (!firstName.isEmpty() && !phoneNumbers.isEmpty()) {
        for (const QVariant &phoneNumber : phoneNumbers) {
            importContact(firstName, singlePerson.value("lastName").toString(), phoneNumber.toString());
        }
    }
}
