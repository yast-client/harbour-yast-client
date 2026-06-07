# tg_owt

YAST supports calls. They are implemented through tgcalls - the Telegram Calls Library. Telegram calls rely on WebRTC, specifically [tg_owt](https://github.com/desktop-app/tg_owt). You can skip building it by downloading a prebuilt version from [here](https://github.com/ferniegram/tg_owt/releases/latest) and extracting the archive to tg_owt/ (`include` directory can be omitted). If you'd like to compile it manually, keep reading.

## tg_owt

Now we can build actual tg_owt. We will need to use a slightly [patched version](https://github.com/ferniegram/tg_owt) with support for packaged openh264 as well as some other libraries.

```bash
sfdk config target=SailfishOS-5.0.0.62-aarch64 # Adjust the target if needed

git clone https://github.com/ferniegram/tg_owt --recursive
cd tg_owt
```

If you use i486 architecture, also install `nasm`:
```bash
sfdk build-shell --maintain zypper install -y nasm
```

Proceed with actually building the library:

```bash
mkdir build
cd build
sfdk build-init

# Instal necessary packages
sfdk build-shell --maintain zypper install -y ninja ccache git \
    libjpeg-turbo-devel ffmpeg-devel opus-devel libvpx-devel \
    pulseaudio-devel


sfdk build-shell cmake .. -GNinja \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DTG_OWT_PACKAGED_BUILD=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_C_FLAGS="-fPIC" \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    -DTG_OWT_USE_PIPEWIRE=OFF \
    -DTG_OWT_USE_X11=OFF \
    -DTG_OWT_BUILD_AUDIO_BACKENDS=ON \
    -DCMAKE_INSTALL_PREFIX:PATH=../out

sfdk build-shell cmake --build . --target install
```

The file we need will be in `../out/libtg_owt.a`, and the includes (they're already present in libfernie/tg_owt/) will be in `../out/include/`.
