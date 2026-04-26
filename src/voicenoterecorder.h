/*
    Copyright (C) 2020-present roundedrectangle, Sebastian J. Wolf and other contributors

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

#ifndef VOICENOTERECORDER_H
#define VOICENOTERECORDER_H

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

#endif // VOICENOTERECORDER_H
