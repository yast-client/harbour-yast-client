import QtQuick 2.6
import QtMultimedia 5.6
import App.Logic 1.0

// An alternative to Video from QtMultimedia with support for QuickAVPlayer

Item {
    id: video

    // Not implemented: autoLoad, bufferProgress, availability,
    // hasAudio, hasVideo, metaData, audioRole, playlist and supportedAudioRoles()

    property alias fillMode: videoOut.fillMode
    property alias orientation: videoOut.orientation

    property bool useAv
    property alias player: loader.item

    property bool autoPlay: true
    property url source
    property real playbackRate: 1.0
    property real volume: 1.0
    property bool muted

    readonly property int playbackState: player ? player.playbackState : MediaPlayer.StoppedState
    readonly property var duration: player ? player.duration : 0
    readonly property int error: player ? player.error : MediaPlayer.NoError
    readonly property string errorString: player ? player.errorString : ''
    readonly property var position: player ? player.position : 0
    readonly property bool seekable: player ? player.seekable : false
    readonly property int status: player ? player.status : MediaPlayer.NoMedia

    /*Instantiator {
        model: ['autoPlay', 'source', 'playbackRate', 'volume', 'muted']
        Binding {
            target: player
            property: modelData
            value: video[modelData]
        }
    }*/

    signal paused
    signal stopped
    signal playing

    VideoOutput {
        id: videoOut
        anchors.fill: video
        source: player
    }

    Loader {
        id: loader
        sourceComponent: useAv ? avPlayerComponent : mediaPlayerComponent

        Component {
            id: mediaPlayerComponent
            MediaPlayer {
                autoPlay: video.autoPlay
                source: video.source
                playbackRate: video.playbackRate
                volume: video.volume
                muted: video.muted
            }
        }
        Component {
            id: avPlayerComponent
            AVPlayer {
                autoPlay: video.autoPlay
                source: video.source
                playbackRate: video.playbackRate
                volume: video.volume
                muted: video.muted
            }
        }
    }

    Connections {
        target: player
        ignoreUnknownSignals: true

        onPaused: video.paused()
        onStopped: video.stopped()
        onPlaying: video.playing()
    }

    function play() {
        if (player) player.play()
    }
    function pause() {
        if (player) player.pause()
    }
    function stop() {
        if (player) player.stop()
    }
    function seek(offset) {
        if (player) player.seek(offset)
    }
}
