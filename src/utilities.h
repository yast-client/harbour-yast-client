/*
    Copyright (C) 2020-21 Sebastian J. Wolf and other contributors

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

#ifndef UTILITIES_H
#define UTILITIES_H

#include <QObject>
#include <QAudioRecorder>
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
#include <QNetworkAccessManager>
#include "tdlibwrapper.h"

class Utilities : public QObject
{
    Q_OBJECT

    Q_PROPERTY(VoiceNoteRecordingState voiceNoteRecordingState READ getVoiceNoteRecordingState NOTIFY voiceNoteRecordingStateChanged)
    Q_PROPERTY(QString voiceNotePath READ getVoiceNotePath)
    Q_PROPERTY(qlonglong voiceNoteDuration READ getVoiceNoteDuration NOTIFY voiceNoteDurationChanged)
public:
    explicit Utilities(AppSettings *settings = nullptr, TDLibWrapper *tdLibWrapper = nullptr, QObject *parent = nullptr);
    ~Utilities();

    enum VoiceNoteRecordingState {
        Unavailable,
        Ready,
        Starting,
        Recording,
        Stopping
    };
    Q_ENUM(VoiceNoteRecordingState)

    static QString getUserName(const QVariantMap &userInformation);
    
    Q_INVOKABLE static QString fixReservedHtmlCharacters(const QString &text);
    Q_INVOKABLE static void handleHtmlEntity(const QString &messageText, QList<QVariantMap> &messageInsertions, const QString &originalString, const QString &replacementString);
    Q_INVOKABLE static QString enhanceMessageText(const QVariantMap &formattedText, bool ignoreEntities = false, bool escapeReserved = true);
    Q_INVOKABLE QString getMessageText(const QVariantMap &message, bool simple = false, bool ignoreEntities = false, bool escapeReserved = true) const;
    Q_INVOKABLE QVariantMap getFormattedMessageText(const QVariantMap &message, bool simple = false) const;
    Q_INVOKABLE QString getMessageContentText(const QVariantMap messageContent, bool simple = false, bool ignoreEntities = false, bool escapeReserved = true) const;

    Q_INVOKABLE static QVariantMap newFormattedText(const QString &text, const QVariantList &entities = QVariantList());
    Q_INVOKABLE static QVariantList formattedTextEntitiesFromReplacements(QList<QVariantMap> &replacements, QString &text);
    Q_INVOKABLE static QList<QVariantMap> findFormattedTextReplacements(const QRegularExpression &re, const QString &text, const QString &entityType, const QString &typeParameter);
    Q_INVOKABLE static QVariantMap enhanceInputText(const QString &text);


    inline QString getVoiceNotePath() const { return audioRecorder.outputLocation().toLocalFile(); }
    VoiceNoteRecordingState getVoiceNoteRecordingState() const;
    inline qlonglong getVoiceNoteDuration() const { return audioRecorder.duration(); }

    Q_INVOKABLE void startRecordingVoiceNote();
    Q_INVOKABLE void stopRecordingVoiceNote();
    Q_INVOKABLE void startGeoLocationUpdates();
    Q_INVOKABLE void stopGeoLocationUpdates();
    Q_INVOKABLE inline bool supportsGeoLocation() const { return this->geoPositionInfoSource; }
    Q_INVOKABLE void initiateReverseGeocode(double latitude, double longitude);

signals:
    void voiceNoteDurationChanged();
    void voiceNoteRecordingStateChanged();
    void newPositionInformation(const QVariantMap &positionInformation);
    void newGeocodedAddress(const QString &geocodedAddress);

private slots:
    void handleGeoPositionUpdated(const QGeoPositionInfo &info);
    void handleReverseGeocodeFinished();

private:
    AppSettings *appSettings;
    TDLibWrapper *tdLibWrapper;

    QAudioRecorder audioRecorder;

    QGeoPositionInfoSource *geoPositionInfoSource;
    QNetworkAccessManager *manager;

    QString getTemporaryDirectoryPath();

    QVariant getMaybeFormattedMessageText(const QVariantMap &messageContent, const QString &messageSenderType, qlonglong messageSenderUserId, bool isSponsored, bool simple) const;
    QVariant inline getMaybeFormattedMessageText(const QVariantMap &message, bool simple = false) const;
};

#endif // UTILITIES_H
