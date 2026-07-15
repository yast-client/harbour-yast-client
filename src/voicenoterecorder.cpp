//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-FileCopyrightText: 2020 Sebastian J. Wolf and other contributors
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "voicenoterecorder.h"

#include <QAudioEncoderSettings>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QUrl>
#include <QDateTime>
#include <QStandardPaths>

#define DEBUG_ROOT_MODULE "yast-client"
#define DEBUG_MODULE VoiceNoteRecorder
#include "debuglog.h"

namespace {
    // vorbis cannot be played on Telegram for iOS
    const QString AUDIO_CODEC_OPUS("audio/opus");
    const QString AUDIO_CODEC_VORBIS("audio/vorbis");
}

void VoiceNoteRecorder::setupAudioRecorder() {
    LOG("Initializing audio recorder...");

#ifdef NO_HARBOUR_COMPLIANCE
    this->gstAudioRecorder = nullptr;
#endif

    this->qAudioRecorder = new QAudioRecorder(this);
    const bool opusSupportedByQt = qAudioRecorder->supportedAudioCodecs().contains(AUDIO_CODEC_OPUS);
    bool needSetupQt = true;

#ifdef NO_HARBOUR_COMPLIANCE
    if (!opusSupportedByQt && !forceQtAudioRecorder) {
        LOG("Opus codec not provided by QtMultimedia, trying to setup custom GStreamer backend");
        bool error = false;
        this->gstAudioRecorder = new GstAudioRecorder(argc, argv, &error, this);
        if (!error) {
            LOG("Custom GStreamer backend successfully initialized!");

            needSetupQt = false;
            delete this->qAudioRecorder;
            this->qAudioRecorder = nullptr;

            this->gstAudioRecorder->setVolume(this->volume);
            connect(gstAudioRecorder, &GstAudioRecorder::stateChanged, this, &VoiceNoteRecorder::voiceNoteRecordingStateChanged);
            connect(gstAudioRecorder, &GstAudioRecorder::durationChanged, this, &VoiceNoteRecorder::voiceNoteDurationChanged);
        } else {
            LOG("Could not setup custom GStreamer backend, falling back to Vorbis codec from QtMultimedia");
            delete gstAudioRecorder;
            gstAudioRecorder = nullptr;
        }
    }
#endif

    if (needSetupQt) {
        QAudioEncoderSettings encoderSettings;
        encoderSettings.setCodec(opusSupportedByQt ? AUDIO_CODEC_OPUS : AUDIO_CODEC_VORBIS);
        encoderSettings.setChannelCount(1);
        encoderSettings.setQuality(QMultimedia::LowQuality);

        this->qAudioRecorder->setEncodingSettings(encoderSettings);
        this->qAudioRecorder->setContainerFormat("ogg");
        this->qAudioRecorder->setVolume(this->volume);

        connect(qAudioRecorder, &QAudioRecorder::statusChanged, this, &VoiceNoteRecorder::voiceNoteRecordingStateChanged);
        connect(qAudioRecorder, &QAudioRecorder::durationChanged, this, &VoiceNoteRecorder::voiceNoteDurationChanged);

        LOG("Initialized QtMultimedia-based audio recorder");
    }

    LOG("Audio recorder initialized");
}

VoiceNoteRecorder::VoiceNoteRecorder(int argc, char *argv[], QObject *parent) :
    QObject(parent),
    argc(argc),
    argv(argv)
{
    QString temporaryDirectoryPath = this->getTemporaryDirectoryPath();
    QDir temporaryDirectory(temporaryDirectoryPath);
    if (!temporaryDirectory.exists())
        temporaryDirectory.mkpath(temporaryDirectoryPath);

    this->setupAudioRecorder();
}

VoiceNoteRecorder::~VoiceNoteRecorder() {
    QDirIterator temporaryDirectoryIterator(this->getTemporaryDirectoryPath(), QDir::Files | QDir::NoDotAndDotDot | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (temporaryDirectoryIterator.hasNext()) {
        QString nextFilePath = temporaryDirectoryIterator.next();
        if (QFile::remove(nextFilePath))
            LOG("Temporary file removed" << nextFilePath);
        else LOG("Error removing temporary file" << nextFilePath);
    }
}

void VoiceNoteRecorder::setForceQtAudioRecorder(bool value) {
    if (forceQtAudioRecorder != value) {
        forceQtAudioRecorder = value;
        emit forceQtAudioRecorderChanged();

        setupAudioRecorder();
    }
}

void VoiceNoteRecorder::setVolume(qreal value) {
    if (volume != value) {
        volume = value;
        emit volumeChanged();
        LOG("Volume set" << volume);

#ifdef NO_HARBOUR_COMPLIANCE
        if (gstAudioRecorder)
            this->gstAudioRecorder->setVolume(this->volume);
        else
#endif
        if (qAudioRecorder)
            this->qAudioRecorder->setVolume(this->volume);
    }
}

void VoiceNoteRecorder::startRecordingVoiceNote() {
    LOG("Start recording voice note...");
    const QString location = this->getTemporaryDirectoryPath() + "/voicenote-" + QDateTime::currentDateTime().toString("yyyy-MM-dd-HH-mm-ss") + ".ogg";
#ifdef NO_HARBOUR_COMPLIANCE
    if (gstAudioRecorder)
        gstAudioRecorder->record(location);
    else
#endif
    if (qAudioRecorder) {
        qAudioRecorder->setOutputLocation(location);
        qAudioRecorder->record();
    }
}

void VoiceNoteRecorder::stopRecordingVoiceNote() {
    LOG("Stop recording voice note...");
#ifdef NO_HARBOUR_COMPLIANCE
    if (gstAudioRecorder)
        gstAudioRecorder->stop();
    else
#endif
    if (qAudioRecorder)
        qAudioRecorder->stop();
}

VoiceNoteRecorder::VoiceNoteRecordingState VoiceNoteRecorder::getVoiceNoteRecordingState() const {
#ifdef NO_HARBOUR_COMPLIANCE
    if (gstAudioRecorder) {
        switch(this->gstAudioRecorder->getState()) {
        case GstAudioRecorder::Ready:
        case GstAudioRecorder::Paused: // TODO: add paused state when pausing recording will be implemented
            return VoiceNoteRecordingState::Ready;
        case GstAudioRecorder::Recording:
            return VoiceNoteRecordingState::Recording;
        case GstAudioRecorder::Unavailable:
            return VoiceNoteRecordingState::Unavailable;
        case GstAudioRecorder::Starting:
            return VoiceNoteRecordingState::Starting;
        case GstAudioRecorder::Stopping:
            return VoiceNoteRecordingState::Stopping;
        }
    }
#endif
    if (qAudioRecorder) {
        switch (qAudioRecorder->status()) {
        case QMediaRecorder::LoadedStatus:
        case QMediaRecorder::PausedStatus:
            return VoiceNoteRecordingState::Ready;
        case QMediaRecorder::StartingStatus:
            return VoiceNoteRecordingState::Starting;
        case QMediaRecorder::FinalizingStatus:
            return VoiceNoteRecordingState::Stopping;
        case QMediaRecorder::RecordingStatus:
            return VoiceNoteRecordingState::Recording;
        default:
            return VoiceNoteRecordingState::Unavailable;
        }
    }

    return VoiceNoteRecordingState::Unavailable;
}

QString VoiceNoteRecorder::getVoiceNotePath() const {
#ifdef NO_HARBOUR_COMPLIANCE
    if (gstAudioRecorder) return gstAudioRecorder->getLocation();
#endif
    if (qAudioRecorder) return qAudioRecorder->outputLocation().toString();
    return QString();
}

qlonglong VoiceNoteRecorder::getVoiceNoteDuration() const {
#ifdef NO_HARBOUR_COMPLIANCE
    if (gstAudioRecorder) return gstAudioRecorder->getDuration();
#endif
    if (qAudioRecorder) return qAudioRecorder->duration();
    return 0;
}

QString VoiceNoteRecorder::getTemporaryDirectoryPath() {
    return QStandardPaths::writableLocation(QStandardPaths::TempLocation) +  + "/harbour-yast-client";
}
