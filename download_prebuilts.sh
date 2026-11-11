usage() {
cat << EOF 
usage: $0 [-a ARCH] [-v TDLIB_VERSION] [-t TDLIB_TAG] [-w WEBRTC_TAG] [-s SUFFIX] [-h] [-j] [-c]

Download prebuilt libraries for YAST Client.

OPTIONS:
    -a ARCH           The architecture to use when checking if a library needs to be downloaded or not.
    -j                Enable Harbour compatibility. Currently, only skips WebRTC.
    -v TDLIB_VERSION  The TDLib version to use. Defaults to TDLIB_TAG,
                      with leading 'v' and everything after the dash symbol (-) removed.
    -t TDLIB_TAG      The TDLib Git tag to download. If explicitly set empty, defaults to 'v' + TDLIB_VERSION.
    -w WEBRTC_TAG     The Git tag to use for downloading WebRTC.
    -s SUFFIX         The suffix to use when downloading library archives. Defaults to ".2".
    -h                Show this message and exit.

EXAMPLES:
    $0 -a aarch64 -v "1.8.69" -w v3 -s ""
        Download TDLib 1.8.69 and WebRTC tag v3
    $0 -a aarch64 -t "1.8.70-2" -w v4 -s ".1"
        Download TDLib 1.8.70 from tag 1.8.70-2 and WebRTC tag v4 from tdlib.1.zip and tg_owt.1.zip assets
EOF
}

ARCH=aarch64
HARBOUR=false
TDLIB_VERSION=
TDLIB_TAG=v1.8.70-2
WEBRTC_TAG=v4
SUFFIX=".2"

while getopts "hja:t:w:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    j) HARBOUR=true ;;
    a) ARCH=$OPTARG ;;

    v) TDLIB_VERSION=$OPTARG ;;
    t) TDLIB_TAG=$OPTARG ;;
    w) WEBRTC_TAG=$OPTARG ;;

    s) SUFFIX=$OPTARG ;;

    ?)
      usage
      exit
      ;;
  esac
done

TDLIB_VERSION="${TDLIB_VERSION:-$(echo "$TDLIB_TAG" | sed -E 's/^v|-.*//g')}"
TDLIB_TAG="${TDLIB_TAG:-v$TDLIB_VERSION}"

echo "Downloading for $ARCH"

# TDLib
LAST_TDLIB_VERSION_FILE=tdlib/.last_downloaded_version
touch $LAST_TDLIB_VERSION_FILE

if ! grep -Fxq "$TDLIB_TAG $SUFFIX" $LAST_TDLIB_VERSION_FILE || [ ! -f tdlib/$ARCH/lib/libtdjson.so.${TDLIB_VERSION} ]; then
    echo "Downloading TDLib"
    curl -o tdlib.zip -L https://github.com/yast-client/td/releases/download/$TDLIB_TAG/tdlib${SUFFIX}.zip

    # FIXME?
    rm -r tdlib/aarch64
    rm -r tdlib/armv7hl
    rm -r tdlib/i486

    unzip -o tdlib.zip -d ./tdlib
    rm tdlib.zip
    rm tdlib/include -r
else
    echo "TDLib for $ARCH already downloaded"
fi

echo "$TDLIB_TAG $SUFFIX" > $LAST_TDLIB_VERSION_FILE

# tg_owt/WebRTC
if [[ $HARBOUR == true ]]; then
    echo "Skipping WebRTC download for harbour build"
else
    LAST_WEBRTC_VERSION_FILE=tg_owt/.last_downloaded_version
    touch $LAST_WEBRTC_VERSION_FILE

    if ! grep -Fxq "$WEBRTC_TAG $SUFFIX" $LAST_WEBRTC_VERSION_FILE || [ ! -d tg_owt/$ARCH ]; then
        echo "Downloading WebRTC"
        curl -o tg_owt.zip -L https://github.com/yast-client/tg_owt/releases/download/$WEBRTC_TAG/tg_owt${SUFFIX}.zip
        unzip -qq -o tg_owt.zip -d ./tg_owt
        rm tg_owt.zip
        rm tg_owt/include -r
    else
        echo "WebRTC for $ARCH already downloaded"
    fi

    echo "$WEBRTC_TAG $SUFFIX" > $LAST_WEBRTC_VERSION_FILE
fi

# Add anything else here later if needed