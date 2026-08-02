//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "quickavplayer.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

#define DEBUG_MODULE QuickAVPlayer
#include "debuglog.h"

QuickAVPlayer::QuickAVPlayer(QObject *parent) : QAVPlayer(parent) {
    connect(this, &QAVPlayer::errorOccurred, this, [this](QAVPlayer::Error avError, const QString &errorString) {
        switch (avError) {
        case QAVPlayer::NoError:
            playerError = QMediaPlayer::NoError;
            break;
        case QAVPlayer::ResourceError:
            playerError = QMediaPlayer::ResourceError;
            break;
        default:
            playerError = QMediaPlayer::FormatError;
        }
        this->errorString = errorString;

        emit error(playerError, errorString);
    });
    connect(this, &QAVPlayer::played, this, &QuickAVPlayer::playing);

    connect(this, &QAVPlayer::sourceChanged, this, &QuickAVPlayer::sourceChanged);
    connect(this, &QAVPlayer::stateChanged, this, &QuickAVPlayer::stateChanged);
    connect(this, &QAVPlayer::mediaStatusChanged, this, &QuickAVPlayer::statusChanged);
    connect(this, &QAVPlayer::seekableChanged, this, &QuickAVPlayer::seekableChanged);
    connect(this, &QAVPlayer::durationChanged, this, &QuickAVPlayer::durationChanged);
    connect(this, &QAVPlayer::speedChanged, this, &QuickAVPlayer::speedChanged);

    // TODO: actually implement this if audio will ever be needed here
    /*connect(this, &QAVPlayer::played, this, [this]() { audioOutput.resume(); });
    connect(this, &QAVPlayer::paused, this, [this]() {
        audioOutput.setVolume(0);
        audioOutput.suspend();
    });*/

    connect(this, &QAVPlayer::sourceChanged, this, &QuickAVPlayer::tryAutoPlay);

    connect(this, &QAVPlayer::videoFrame, this, &QuickAVPlayer::handleFrameDecoded, Qt::DirectConnection);
    connect(this, &QAVPlayer::audioFrame, this, [this](const QAVAudioFrame &frame) {
        audioOutput.play(frame);
    }, Qt::DirectConnection);
    connect(this, &QAVPlayer::seeked, this, &QuickAVPlayer::positionChanged);

    //setInputVideoCodec("software");
}

QuickAVPlayer::~QuickAVPlayer() {
    LOG("Destroying");
    if (surface && surface->isActive())
        surface->stop();
}

void QuickAVPlayer::setAutoPlay(bool value) {
    if (autoPlay != value) {
        autoPlay = value;
        emit autoPlayChanged();
    }
}

void QuickAVPlayer::tryAutoPlay() {
    if (autoPlay && surface && !source().isEmpty() && state() == QAVPlayer::StoppedState) {
        LOG("Auto-playing");
        play();
    }
}

void QuickAVPlayer::setSurface(QAbstractVideoSurface *surface) {
    if (this->surface != surface) {
        this->surface = surface;
        tryAutoPlay();
    }
}
void QuickAVPlayer::handleFrameDecoded(const QAVVideoFrame &avFrame) {
    emit positionChanged();
    if (!surface) return;

    QVideoFrame frame = avFrame;
    if (!surface->isActive())
        surface->start({frame.size(), frame.pixelFormat(), frame.handleType()});
    if (surface->isActive())
        surface->present(frame);

    surface->present(frame);
}

QMediaPlayer::MediaStatus QuickAVPlayer::playerStatus() const {
    switch (QAVPlayer::mediaStatus()) {
    case NoMedia:
        return QMediaPlayer::MediaStatus::NoMedia;
    case LoadedMedia:
        return QMediaPlayer::MediaStatus::LoadedMedia;
    case EndOfMedia:
        return QMediaPlayer::MediaStatus::EndOfMedia;
    case InvalidMedia:
        return QMediaPlayer::MediaStatus::InvalidMedia;
    }
    return QMediaPlayer::MediaStatus::NoMedia;
}

void QuickAVPlayer::setVolume(qreal value) {
    if (volume != value) {
        volume = value;
        emit volumeChanged();
        audioOutput.setVolume(muted ? 0 : volume);
    }
}

void QuickAVPlayer::setMuted(bool value) {
    if (muted != value) {
        muted = value;
        emit mutedChanged();
        audioOutput.setVolume(muted ? 0 : volume);
    }
}
