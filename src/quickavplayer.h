//@ SPDX-FileCopyrightText: 2026-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QThread>
#include <QAbstractVideoSurface>
#include <QVideoSurfaceFormat>
#include <QUrl>
#include <QMediaPlayer>

#include <QtAVPlayer/qavplayer.h>
#include <QtAVPlayer/qavvideoframe.h>
#include <QtAVPlayer/qavaudiooutput.h>
#include <QtAVPlayer/qavmuxerframes.h>
#include <QtAVPlayer/qaviodevice.h>

// QAVPlayer exposed to QML with a MediaPlayer-compatible API

class QuickAVPlayer : public QAVPlayer {
    Q_OBJECT

    Q_PROPERTY(QAbstractVideoSurface *videoSurface MEMBER surface WRITE setSurface)
    Q_PROPERTY(bool autoPlay MEMBER autoPlay WRITE setAutoPlay NOTIFY autoPlayChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)

    Q_PROPERTY(QAVPlayer::State playbackState READ state NOTIFY stateChanged) // compatible with QMediaPlayer::State
    Q_PROPERTY(QMediaPlayer::MediaStatus status READ playerStatus NOTIFY statusChanged)
    Q_PROPERTY(QMediaPlayer::Error error MEMBER playerError NOTIFY error)
    Q_PROPERTY(QString errorString MEMBER errorString NOTIFY error)
    Q_PROPERTY(bool seekable READ isSeekable NOTIFY seekableChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qreal playbackRate READ speed WRITE setSpeed NOTIFY speedChanged)

    Q_PROPERTY(qreal volume MEMBER volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted MEMBER muted WRITE setMuted NOTIFY mutedChanged)

public:
    explicit QuickAVPlayer(QObject *parent = nullptr);
    ~QuickAVPlayer();

    void setAutoPlay(bool value);
    void setSurface(QAbstractVideoSurface *surface);

    QMediaPlayer::MediaStatus playerStatus() const;

    void setVolume(qreal value);
    void setMuted(bool value);

signals:
    void autoPlayChanged();

    void error(QMediaPlayer::Error error, const QString &errorString);
    void playing();
    void positionChanged();

    // need to explicitly put these here
    void sourceChanged();
    void stateChanged();
    void statusChanged();
    void seekableChanged();
    void durationChanged();
    void speedChanged();

    void volumeChanged();
    void mutedChanged();

private slots:
    void tryAutoPlay();
    void handleFrameDecoded(const QAVVideoFrame &frame);

private:
    QAbstractVideoSurface *surface = nullptr;
    bool autoPlay = true;
    QVideoSurfaceFormat currentFormat;
    QMediaPlayer::Error playerError = QMediaPlayer::NoError;
    QString errorString;
    QAVAudioOutput audioOutput;
    qreal volume = 1.0;
    bool muted = false;
};
