# tg_owt

Ferniegram supports calls. They are implemented through tgcalls - the Telegram Calls Library. Telegram calls rely on WebRTC, specifically [tg_owt](https://github.com/desktop-app/tg_owt). You can skip building it by downloading a prebuilt version from [here](https://github.com/ferniegram/tg_owt/releases/tag/v1) and extracting the archive to tg_owt/ (`include` directory can be omitted). If you'd like to compile it manually, keep reading.

## openh264

tg_owt relies on the openh264 library, which is not provided in the SailfishOS repositories. We'll have to compile it manually.

```bash
git clone https://github.com/cisco/openh264
cd openh264

sfdk config target=SailfishOS-5.0.0.62-aarch64 # Adjust the target if needed
sfdk build-init
```

If you use i486 architecture, also install `nasm`:
```bash
sfdk build-shell --maintain zypper install -y nasm
```

Now, build:
```bash
sfdk build-shell make CFLAGS="-fPIC" CXXFLAGS="-fPIC" LDFLAGS="-fPIC" libraries

cd ..
```

## tg_owt

Now we can build actual tg_owt. We will need to use a slightly [patched version](https://github.com/ferniegram/tg_owt) with support for statically compiled openh264.

```bash
git clone https://github.com/ferniegram/tg_owt --recursive
cd tg_owt

mkdir build
cd build
sfdk build-init

# Instal necessary packages
sfdk build-shell --maintain zypper install -y ninja ccache \
    libjpeg-turbo-devel ffmpeg-devel opus-devel libvpx-devel \
    libsrtp-devel
```

If you have system libabsl installed, remove it so a packaged version would be used:
```bash
sfdk build-shell --maintain zypper remove -y abseil-cpp-devel
```

Now, go ahed and actually compile tg_owt using:
```bash
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
    -DTG_OWT_OPENH264_INCLUDE_PATH=../../openh264/codec/api \
    -DTG_OWT_OPENH264_LIB_PATH=../../openh264/libopenh264.a \
    -DCMAKE_INSTALL_PREFIX:PATH=../out

sfdk build-shell cmake --build . --target install
```

The file we need will be in `../out/libtg_owt.a`, and the includes (they're already present in libfernie/tg_owt/) will be in `../out/include/`. You'll also need the openh264 library file located at `openh264/libopenh264.a`.

***(TODO):*** *storing webrtc in a separate `.so` would probably be better*