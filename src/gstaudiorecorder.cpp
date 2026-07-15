//@ SPDX-FileCopyrightText: 2024-present roundedrectangle
//@ SPDX-License-Identifier: GPL-3.0-or-later

#include "gstaudiorecorder.h"

#include <QCoreApplication>

#include <gst/gst.h>
//#include <gst/pbutils/pbutils.h>

#define DEBUG_MODULE GstAudioRecorder
#include "debuglog.h"

#define LOG_GERROR(m, e) if (e) \
    LOG(m << e->domain << e->code << e->message); \
    else LOG(m)
#define CLEAN_GERROR(e) if (e) { \
        g_clear_error(&e); \
        e = nullptr; \
    }

GstAudioRecorder::GstAudioRecorder(int argc, char **argv, bool *error, QObject *parent) :
    QThread(parent),
    pipeline(nullptr),
    needTerminate(false),
    state(Ready),
    duration(-1)
{
    GError *gError = nullptr;
    if (!gst_init_check(&argc, &argv, &gError)) {
        LOG_GERROR("Unable to initialize GStreamer", gError);
        CLEAN_GERROR(gError);
        if (error) *error = true;
        return;
    }

    if (!initializePipeline())
        if (error) *error = true;
}

GstAudioRecorder::~GstAudioRecorder() {
    LOG("Cleaning up");

    if (pipeline) {
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
    }
}

bool GstAudioRecorder::initializePipeline() {
    if (pipeline) {
        LOG("Pipeline already initialized");
        return true;
    }

    GError *gError = nullptr;

    pipeline = gst_parse_launch("pulsesrc ! audioconvert ! volume name=volume ! opusenc ! oggmux ! filesink name=sink", &gError);
    if (gError) {
        LOG_GERROR("Error occured while creating pipeline (not necessarily critical)", gError);
        CLEAN_GERROR(gError);
    }
    if (!pipeline) {
        WARN("Pipeline could not be created (a critical error occured). See above for details");
        return false;
    }

    LOG("No critical errors occured");
    return true;
}

void GstAudioRecorder::run() {
    if (!pipeline) {
        LOG("Could not listen to the bus: pipeline not initialized");
        return;
    }

    LOG("Listening to pipeline");

    GstBus *bus = gst_element_get_bus(pipeline);
    while (!needTerminate) {
        GstMessage *msg = gst_bus_timed_pop_filtered(bus, 100 * GST_MSECOND,
                                                            static_cast<GstMessageType>(GST_MESSAGE_STATE_CHANGED | GST_MESSAGE_ERROR | GST_MESSAGE_EOS));

        if (msg)
            handleMessage(msg);
        else {
            // We got no message, this means the timeout expired
            if (state == Recording) {
                LOG("Getting position");
                int64_t newDuration;
                if (gst_element_query_position(pipeline, GST_FORMAT_TIME, &newDuration)) {
                    newDuration = GST_TIME_AS_MSECONDS(newDuration);
                    if (duration != newDuration) {
                        duration = newDuration;
                        emit durationChanged();
                    }
                } else {
                    LOG("Couldn't query new position");
                    if (this->duration != -1) {
                        this->duration = -1;
                        emit durationChanged();
                    }
                }
            }
        }
    }

    gst_object_unref(bus);

    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);
    pipeline = nullptr;

    duration = -1;
    emit durationChanged();

    needTerminate = false;
    LOG("Thread terminated");
}

void GstAudioRecorder::handleMessage(GstMessage *msg) {
    switch (GST_MESSAGE_TYPE(msg)) {
    case GST_MESSAGE_ERROR:
        GError *err;
        gchar *debug_info;
        gst_message_parse_error(msg, &err, &debug_info);
        WARN("Error received from element" << GST_OBJECT_NAME (msg->src) << err->message << "debug info" << (debug_info ? debug_info : "none"));
        g_clear_error(&err);
        g_free(debug_info);
        needTerminate = true;
        break;
    case GST_MESSAGE_EOS:
        LOG("End of stream");
        needTerminate = true;
        break;
    case GST_MESSAGE_STATE_CHANGED:
        //We are only interested in state-changed messages from the pipeline
        if (pipeline && GST_MESSAGE_SRC(msg) == GST_OBJECT(pipeline)) {
            GstState oldState, newState, pendingState;
            gst_message_parse_state_changed(msg, &oldState, &newState, &pendingState);
            LOG("Pipeline state was changed from" << oldState << "to" << newState << "pending" << pendingState);
            //LOG("Pipeline state changed from" << gst_state_get_name(oldState) << "to" << gst_state_get_name(newState));

            GstRecordingState newGstState = Unavailable;
            switch (pendingState) {
            case GST_STATE_PLAYING:
                newGstState = Starting;
                break;
            case GST_STATE_NULL:
                newGstState = Stopping;
                break;
            default:
                switch (newState) {
                case GST_STATE_VOID_PENDING:
                    newGstState = Unavailable;
                    break;
                case GST_STATE_NULL:
                    newGstState = Ready;
                    needTerminate = true;
                    break;
                case GST_STATE_PLAYING:
                    newGstState = Recording;
                    break;
                case GST_STATE_PAUSED:
                    newGstState = Paused;
                    break;
                case GST_STATE_READY: // should not usually reach here, Starting or Stopping is set based on pending state
                    newGstState = Starting;
                    break;
                }
            }

            if (this->state != newGstState) {
                this->state = newGstState;
                emit stateChanged();
            }
        }
        break;
    default:
      // We should not reach here
      LOG("Unexpected message received");
      break;
    }
    gst_message_unref(msg);
}

void GstAudioRecorder::record(const QString &location) {
    if (!initializePipeline()) {
        LOG("Could not start recording: can't initialize pipeline");
        return;
    }

    GstElement *filesink = gst_bin_get_by_name(GST_BIN(pipeline), "sink");
    if (!filesink) {
        WARN("File sink could not be retrieved");
        return;
    }
    LOG("Recording to" << location);

    g_object_set(G_OBJECT(filesink), "location", location.toStdString().c_str(), NULL);
    gst_object_unref(filesink);

    GstStateChangeReturn ret = gst_element_set_state(pipeline, GST_STATE_PLAYING);
    switch (ret) {
    case GST_STATE_CHANGE_FAILURE:
        LOG("Could not start recording");
        return;

    case GST_STATE_CHANGE_SUCCESS:
        state = Recording;
        emit stateChanged();
        break;

    default:
        break;
    }

    start();

    this->location = location;
    emit locationChanged();
}

void GstAudioRecorder::pause() {
    if (!pipeline) {
        LOG("Could not pause recording: pipeline not initialized");
        return;
    }

    GstStateChangeReturn ret = gst_element_set_state(pipeline, GST_STATE_PAUSED);
    switch (ret) {
    case GST_STATE_CHANGE_FAILURE:
        LOG("Could not pause recording");
        return;

    case GST_STATE_CHANGE_SUCCESS:
        state = Paused;
        emit stateChanged();
        break;

    default:
        break;
    }
}

void GstAudioRecorder::stop() {
    if (!pipeline) {
        LOG("Could not stop recording: pipeline not initialized");
        return;
    }

    GstStateChangeReturn ret = gst_element_set_state(pipeline, GST_STATE_NULL);
    switch (ret) {
    case GST_STATE_CHANGE_FAILURE:
        LOG("Could not stop recording, terminating anyway");
        break;

    case GST_STATE_CHANGE_SUCCESS:
        state = Ready;
        emit stateChanged();
        break;

    default:
        break;
    }

    needTerminate = true;
}

void GstAudioRecorder::setVolume(qreal newVolume) {
    if (!pipeline) {
        LOG("Could not start recording: pipeline not initialized");
        return;
    }

    GstElement *volume = gst_bin_get_by_name(GST_BIN(pipeline), "volume");
    if (!volume) {
        WARN("Volume element could not be retreived");
        return;
    }

    g_object_set(G_OBJECT(volume), "volume-full-range", newVolume, NULL);
    gst_object_unref(volume);
}
