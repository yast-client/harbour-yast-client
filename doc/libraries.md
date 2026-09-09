# Libraries

CMake automatically downloads prebuilt TDLib and WebRTC for your convenience. If you want to download prebuilts manually or build them from scratch, keep reading.

## TDLib

You need to have a compiled version of [TDLib](https://github.com/tdlib/td) in the sub-directory `tdlib`. This sub-directory must contain another sub-directory that fits to the target device architecture (e.g. aarch64, armv7hl or i486). Within this directory, there needs to be a folder called `lib` that contains at least `libtdjson.so.<version>`. For armv7hl the relative path would consequently be `tdlib/armv7hl/lib`.

You can simply download [tdlib.zip from the YAST fork](https://github.com/yast-client/td/releases). To use it, you need to extract it into your local `tdlib/` folder as described above.

In case you want to use the same codebase which was used to compile the library that is shipped with YAST, please [check out the fork](https://github.com/roundedrectangle/td) and run the following commands:

- `alias sfdk=~/SailfishOS/bin/sfdk` (may not be needed on newer SDKs)
- `sfdk config target=SailfishOS-5.0.0.62-aarch64` (this compiles the sources on SFOS 5.0 and ARM64 - the target needs to be adjusted according to the running SDK engine and the platform)
- `mkdir build`
- `cd build`
- `sfdk build-init`
- `sfdk build-shell --maintain zypper install ninja ccache`
  - optional, this installs ninja, which is usually faster than make, and ccache, which can speed up rebuilds
- `sfdk build-shell cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=../tdlib -DTD_ENABLE_LTO=ON ..`
  - if you don't have Ninja, remove the `-GNinja` flag, this will switch to make
  - in case of compilation issues, try removing the flag `-DTD_ENABLE_LTO=ON`
- `sfdk build-shell cmake --build . --target install`

In case of errors try to remove `CMakeCache.txt` file from the build directory.

You'll find the compiled library in the directory `td/tdlib`. You might also need to copy the `td/tdlib/include` folder to the `tdlib/` folder in the root of this project

## WebRTC (tg_owt)

YAST supports calls. They are implemented through tgcalls - the Telegram Calls Library. Telegram calls rely on WebRTC, specifically [tg_owt](https://github.com/desktop-app/tg_owt). You can skip building it by downloading a prebuilt version from [here](https://github.com/yast-client/tg_owt/releases/latest) and extracting the archive to tg_owt/ (`include` directory can be omitted). If you'd like to compile it manually, keep reading.

We will need to use a slightly [patched version](https://github.com/yast-client/tg_owt) with support for packaged openh264 as well as some other libraries.

```bash
sfdk config target=SailfishOS-5.0.0.62-aarch64 # Adjust the target if needed

git clone https://github.com/yast-client/tg_owt --recursive
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

The file we need will be in `../out/libtg_owt.a`, and the includes (they're already present in yaqtlib/tg_owt/) will be in `../out/include/`.
