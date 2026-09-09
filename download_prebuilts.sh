usage() {
cat << EOF 
usage: $0 [-a ARCH] [-t TDLIB_VERSION] [-w WEBRTC_TAG] [-h] [-j] [-c]

Download prebuilt libraries for YAST Client.

OPTIONS:
    -a ARCH           The architecture to use when checking if a library needs to be downloaded or not.
    -j                Enable Harbour compatibility. Currently, only skips WebRTC.
    -t TDLIB_VERSION  The TDLib version to download.
    -w WEBRTC_TAG     The Git tag to use for downloading WebRTC.
    -h                Show this message and exit.
EOF
}

ARCH=aarch64
HARBOUR=false
TDLIB_VERSION=1.8.67
WEBRTC_TAG=v3

while getopts "hja:t:w:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    j) HARBOUR=true ;;
    a) ARCH=$OPTARG ;;

    t) TDLIB_VERSION=$OPTARG ;;
    w) WEBRTC_TAG=$OPTARG ;;

    ?)
      usage
      exit
      ;;
  esac
done

echo "Downloading for $ARCH"

# TDLib
if [ ! -f tdlib/$ARCH/lib/libtdjson.so.$TDLIB_VERSION ]; then
    echo "Downloading TDLib"
    curl -OL https://github.com/yast-client/td/releases/download/v$TDLIB_VERSION/tdlib.zip

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

# tg_owt/WebRTC
if [[ $HARBOUR == true ]]; then
    echo "Skipping WebRTC download for harbour build"
elif [ ! -d tg_owt/$ARCH ]; then
    echo "Downloading WebRTC"
    curl -OL https://github.com/yast-client/tg_owt/releases/download/$WEBRTC_TAG/tg_owt.zip
    unzip -o tg_owt.zip -d ./tg_owt
    rm tg_owt.zip
    rm tg_owt/include -r
else
    echo "WebRTC for $ARCH already downloaded"
fi

# Add anything else here later if needed