//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QAudioRecorder>

#include "settings.h"

#ifdef NO_HARBOUR_COMPLIANCE
#include "gstaudiorecorder.h"
#endif

class VoiceNoteRecorder : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool forceQtAudioRecorder MEMBER forceQtAudioRecorder WRITE setForceQtAudioRecorder NOTIFY forceQtAudioRecorderChanged)
    Q_PROPERTY(qreal volume MEMBER volume WRITE setVolume NOTIFY volumeChanged)

    Q_PROPERTY(VoiceNoteRecordingState voiceNoteRecordingState READ getVoiceNoteRecordingState NOTIFY voiceNoteRecordingStateChanged)
    Q_PROPERTY(QString voiceNotePath READ getVoiceNotePath)
    Q_PROPERTY(qlonglong voiceNoteDuration READ getVoiceNoteDuration NOTIFY voiceNoteDurationChanged)
public:
    explicit VoiceNoteRecorder(int argc, char *argv[], QObject *parent = nullptr);
    ~VoiceNoteRecorder();

    enum VoiceNoteRecordingState {
        Unavailable,
        Ready,
        Starting,
        Recording,
        Stopping
    };
    Q_ENUM(VoiceNoteRecordingState)

    void setForceQtAudioRecorder(bool value);
    void setVolume(qreal value);

    VoiceNoteRecordingState getVoiceNoteRecordingState() const;
    QString getVoiceNotePath() const;
    qlonglong getVoiceNoteDuration() const;

    Q_INVOKABLE void startRecordingVoiceNote();
    Q_INVOKABLE void stopRecordingVoiceNote();

signals:
    void forceQtAudioRecorderChanged();
    void volumeChanged();

    void voiceNoteDurationChanged();
    void voiceNoteRecordingStateChanged();

private:
    void setupAudioRecorder();

private:
    bool forceQtAudioRecorder = false;
    qreal volume = 1;

    int argc;
    char **argv;

#ifdef NO_HARBOUR_COMPLIANCE
    GstAudioRecorder *gstAudioRecorder;
#endif
    QAudioRecorder *qAudioRecorder;

    QString getTemporaryDirectoryPath();
};
