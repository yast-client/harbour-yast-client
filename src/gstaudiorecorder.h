#pragma once

#include <QObject>
#include <QThread>

typedef struct _GstElement GstElement;
typedef struct _GstMessage GstMessage;

class GstAudioRecorder : public QThread {
    Q_OBJECT

public:
    enum GstRecordingState {
        Ready,
        Paused,
        Recording,
        Starting,
        Stopping,
        Unavailable
    };
    Q_ENUM(GstRecordingState);

    explicit GstAudioRecorder(int argc, char **argv, bool *error = nullptr, QObject *parent = nullptr);
    ~GstAudioRecorder();

    void record(const QString &location);
    void pause();
    void stop();

    inline GstRecordingState getState() { return state; }
    inline QString getLocation() { return location; }
    inline int64_t getDuration() { return duration; }
    void setVolume(qreal newVolume);

signals:
    void durationChanged();
    void stateChanged();
    void locationChanged();

private:
    bool initializePipeline();
    void run() Q_DECL_OVERRIDE;
    void handleMessage(GstMessage *msg);

private:
    GstElement *pipeline;

    bool needTerminate;
    GstRecordingState state;
    int64_t duration; // duration means duration recorded so far
    QString location;
};
