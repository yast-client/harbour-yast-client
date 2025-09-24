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

#include "stickermanager.h"
#include <QListIterator>

#define DEBUG_MODULE StickerManager
#include "debuglog.h"

StickerManager::StickerManager(TDLibWrapper *tdLibWrapper, QObject *parent) : QObject(parent)
{
    LOG("Initializing...");
    this->tdLibWrapper = tdLibWrapper;
    this->reloadNeeded = false;

    connect(this->tdLibWrapper, &TDLibWrapper::recentStickersUpdated, this, &StickerManager::handleRecentStickersUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::stickersReceived, this, &StickerManager::handleStickersReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::installedStickerSetsUpdated, this, &StickerManager::handleInstalledStickerSetsUpdated);
    connect(this->tdLibWrapper, &TDLibWrapper::stickerSetsReceived, this, &StickerManager::handleStickerSetsReceived);
    connect(this->tdLibWrapper, &TDLibWrapper::stickerSetReceived, this, &StickerManager::handleStickerSetReceived);
}

StickerManager::~StickerManager()
{
    LOG("Destroying myself...");
}

QVariantList StickerManager::getRecentStickers() {
    return this->recentStickers;
}

QVariantList StickerManager::getInstalledStickerSets() {
    return this->installedStickerSets;
}

QVariantMap StickerManager::getStickerSet(qlonglong stickerSetId) {
    return this->stickerSets.value(stickerSetId);
}

bool StickerManager::hasStickerSet(qlonglong stickerSetId) {
    return this->stickerSets.contains(stickerSetId);
}

bool StickerManager::isStickerSetInstalled(qlonglong stickerSetId) {
    return this->installedStickerSetIds.contains(stickerSetId);
}

bool StickerManager::needsReload() {
    return this->reloadNeeded;
}

void StickerManager::setNeedsReload(const bool &reloadNeeded)
{
    this->reloadNeeded = reloadNeeded;
}

void StickerManager::handleRecentStickersUpdated(const QVariantList &stickerIds) {
    LOG("Receiving recent stickers...." << stickerIds);
    this->recentStickerIds.clear();
    for (QVariant stickerId : stickerIds)
        this->recentStickerIds.append(stickerId.toLongLong());
}

void StickerManager::handleStickersReceived(const QVariantList &stickers)
{
    LOG("Receiving stickers....");
    QListIterator<QVariant> stickersIterator(stickers);
    while (stickersIterator.hasNext()) {
        QVariantMap newSticker = stickersIterator.next().toMap();
        int fileId = newSticker.value("sticker").toMap().value("id").toInt();
        this->stickers.insert(fileId, newSticker);
    }

    this->recentStickers.clear();
    for (int stickerId : this->recentStickerIds) {
        this->recentStickers.append(this->stickers.value(stickerId));
    }
}

void StickerManager::handleInstalledStickerSetsUpdated(const QVariantList &stickerSetIds) {
    LOG("Receiving installed sticker IDs...." << stickerSetIds);
    this->installedStickerSetIds.clear();
    for (QVariant setId : stickerSetIds)
        this->installedStickerSetIds.append(setId.toLongLong());
}

void StickerManager::handleStickerSetsReceived(const QVariantList &stickerSets)
{
    LOG("Receiving sticker sets....");
    QListIterator<QVariant> stickerSetsIterator(stickerSets);
    while (stickerSetsIterator.hasNext()) {
        QVariantMap newStickerSet = stickerSetsIterator.next().toMap();
        qlonglong newSetId = newStickerSet.value("id").toLongLong();
        bool isInstalled = newStickerSet.value("is_installed").toBool();
        if (isInstalled && !this->installedStickerSetIds.contains(newSetId)) {
            this->installedStickerSetIds.append(newSetId);
        }
        if (!isInstalled && this->installedStickerSetIds.contains(newSetId)) {
            this->installedStickerSetIds.removeAll(newSetId);
        }
        if (!this->stickerSets.contains(newSetId)) {
            this->stickerSets.insert(newSetId, newStickerSet);
        }
    }

    this->installedStickerSets.clear();
    int i = 0;
    this->stickerSetMap.clear();
    for (qlonglong setId : this->installedStickerSetIds) {
        if (this->stickerSets.contains(setId)) {
            this->installedStickerSets.append(this->stickerSets.value(setId));
            this->stickerSetMap.insert(setId, i);
            i++;
        }
    }
    emit stickerSetsReceived();
}

void StickerManager::handleStickerSetReceived(const QVariantMap &stickerSet) {
    qlonglong stickerSetId = stickerSet.value("id").toLongLong();
    this->stickerSets.insert(stickerSetId, stickerSet);
    if (this->installedStickerSetIds.contains(stickerSetId)) {
        LOG("Receiving installed sticker set...." << stickerSetId);
        int setIndex = this->stickerSetMap.value(stickerSetId);
        this->installedStickerSets.replace(setIndex, stickerSet);
    } else {
        LOG("Receiving new sticker set...." << stickerSetId);
    }
    QVariantList stickerList = stickerSet.value("stickers").toList();
    QListIterator<QVariant> stickerIterator(stickerList);
    while (stickerIterator.hasNext()) {
        QVariantMap singleSticker = stickerIterator.next().toMap();
        QVariantMap thumbnailFile = singleSticker.value("thumbnail").toMap().value("file").toMap();
        QVariantMap thumbnailLocalFile = thumbnailFile.value("local").toMap();
        if (!thumbnailLocalFile.value("is_downloading_completed").toBool()) {
            tdLibWrapper->downloadFile(thumbnailFile.value("id").toInt());
        }
    }
}
