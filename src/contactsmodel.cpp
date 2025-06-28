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

ContactsListModel::ContactsListModel(TDLibWrapper *tdLibWrapper, QObject *parent)
    : QAbstractListModel(parent) {
    this->tdLibWrapper = tdLibWrapper;
    connect(this->tdLibWrapper, &TDLibWrapper::usersReceived, this, &ContactsListModel::handleUsersReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::userUpdated, this, &ContactsListModel::handleUserUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::contactsImported, this, &ContactsListModel::handleContactsImported);
    connect(this->tdLibWrapper, &TDLibWrapper::okMapReceived, this, &ContactsListModel::handleOkMapReceived);
}

QHash<int, QByteArray> ContactsListModel::roleNames() const {
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

int ContactsListModel::rowCount(const QModelIndex &) const {
    return this->contactIds.size();
}

QVariant ContactsListModel::data(const QModelIndex &index, int role) const {
    if (index.isValid()) {
        QVariantMap requestedContact = this->tdLibWrapper->getUserInformation(this->contactIds.value(index.row()));
        switch (static_cast<ContactRole>(role)) {
            case ContactRole::RoleDisplay: return requestedContact;
            case ContactRole::RoleTitle: return QString(requestedContact.value(FIRST_NAME).toString() + " " + requestedContact.value(LAST_NAME).toString()).trimmed();
            case ContactRole::RoleUserId: return requestedContact.value("id");
            case ContactRole::RoleUsername: return requestedContact.value("usernames").toMap().value("editable_username").toString();
            case ContactRole::RolePhotoSmall: return requestedContact.value("profile_photo").toMap().value("small");
            case ContactRole::RoleUserStatus: return requestedContact.value(STATUS).toMap().value(_TYPE);
            case ContactRole::RoleUserLastOnline: return requestedContact.value(STATUS).toMap().value("was_online");
            case ContactRole::RoleFilter: return QString(requestedContact.value(FIRST_NAME).toString() + " " + requestedContact.value(LAST_NAME).toString() + " " + requestedContact.value("usernames").toMap().value("editable_username").toString()).trimmed();
        }
    }
    return QVariant();
}

void ContactsListModel::addUser(const QString &userId) {
    if (!this->tdLibWrapper->hasUserInformation(userId)) {
        this->tdLibWrapper->getUserFullInfo(userId);
    }
    beginInsertRows(QModelIndex(), contactIds.size(), contactIds.size());
    this->contactIds.append(userId);
    endInsertRows();
}

void ContactsListModel::handleUsersReceived(const QString &extra, const QVariantList &userIds, int totalUsers)
{
    if (extra == "contactsRequested") {
        LOG("Received contacts list..." << totalUsers);
        this->contactIds.clear();
        for (const QVariant &userIdVariant : userIds)
            addUser(userIdVariant.toString());
    }
}

void ContactsListModel::handleUserUpdated(const QString &userId) {
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

void ContactsListModel::handleContactsImported(const QVariantList &/*importerCount*/, const QVariantList &userIds, bool single) {
    LOG("Imported" << userIds.size() << "contacts");
    for (const QVariant &userIdVariant : userIds) {
        const QString userId = userIdVariant.toString();
        if (userId == "0") continue;
        addUser(userId);
    }
    if (single) {
        QString userId = userIds.value(0).toString();
        if (userId == "0")
            emit contactNotFound();
        else emit singleContactAdded(userId);
    } else emit contactsImported();
    // todo: sort
}

void ContactsListModel::handleOkMapReceived(const QString &type, const QVariantMap &extra) {
    if (type == "removeContacts") {
        LOG("Removing contacts");
        for (QString userId : extra.value("user_ids").toStringList()) {
            int i = contactIds.indexOf(userId);
            if (i < 0) return;
            beginRemoveRows(QModelIndex(), i, i);
            contactIds.removeAt(i);
            endRemoveRows();
            // here no need to sort
        }
    }
}

bool ContactsListModel::compareUsersByName(const QVariantMap &user1, const QVariantMap &user2) const {
    const QString firstName1 = user1.value(FIRST_NAME).toString();
    const QString firstName2 = user2.value(FIRST_NAME).toString();
    if (firstName1 != firstName2)
        return firstName1 < firstName2;

    const QString lastName1 = user1.value(LAST_NAME).toString();
    const QString lastName2 = user2.value(LAST_NAME).toString();
    if (!lastName1.isEmpty() && lastName1 != lastName2)
        return lastName1 < lastName2;

    const QString username1 = user1.value(USERNAME).toString();
    const QString username2 = user2.value(USERNAME).toString();
    if (!username1.isEmpty())
        return username1 < username2;

    return user1.value(ID).toLongLong() < user2.value(ID).toLongLong();
}

bool ContactsListModel::compare(const QModelIndex &index1, const QModelIndex &index2) const {
    const QVariantMap user1 = tdLibWrapper->getUserInformation(contactIds.value(index1.row()));
    const QVariantMap user2 = tdLibWrapper->getUserInformation(contactIds.value(index2.row()));

    // todo: compare by status (and add an option to compare by name, like right now)
    return compareUsersByName(user1, user2);
}



ContactsModel::ContactsModel(TDLibWrapper *tdLibWrapper, QObject *parent)
    : QSortFilterProxyModel(parent),
    tdLibWrapper(tdLibWrapper),
    contactsListModel(tdLibWrapper, parent)
{
    this->tdLibWrapper = tdLibWrapper;

    setSourceModel(&contactsListModel);
    setFilterRole(ContactsListModel::RoleFilter);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setDynamicSortFilter(true);
    sort(0); // initial sort

    connect(&contactsListModel, &ContactsListModel::contactsImported, this, &ContactsModel::contactsImported);
    connect(&contactsListModel, &ContactsListModel::singleContactAdded, this, &ContactsModel::singleContactAdded);
    connect(&contactsListModel, &ContactsListModel::contactNotFound, this, &ContactsModel::contactNotFound);
}

bool ContactsModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const {
    return contactsListModel.compare(source_left, source_right);
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
