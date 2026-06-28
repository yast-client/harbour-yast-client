# YAST Client
YAST Client is a yet another SailfishOS Telegram client

**YAST is still work-in-progress.**

## Credits

Author: roundedrectangle

Icon is based on Fernschreiber's icon.

### Translations

- Italian by @legacychimera247
- Russian by @windes14

## Fernschreiber PRs included in YAST

Thanks to the following people who created PRs for Fernschreiber which were not merged to it:
- [#576](https://github.com/Wunderfitz/harbour-fernschreiber/pull/576) by @jgibbon: albums and C2 notch fixes
- [#565](https://github.com/Wunderfitz/harbour-fernschreiber/pull/565) by @jgibbon: emoji/twemoji update to 15.1

## Fernschreiber credits

YAST wouldn't be possible without everyone who contributed to Fernschreiber. You can see the full, up-to-date list of contributors on [Fernschreiber's README](https://github.com/Wunderfitz/harbour-fernschreiber/blob/master/README.md). Here is a brief list of the contributors:

Author: Sebastian J. Wolf [sebastian@ygriega.de](mailto:sebastian@ygriega.de) and several contributors
Icon: Designed by [Matteo](https://github.com/iamnomeutente), adjustments by [Slava Monich](https://github.com/monich)

Code (Features, Bugfixes, Optimizations etc.):
- Chat list model, chat model, notifications, TDLib receiver, animated stickers, project dependencies, qml/c++ optimizations, chatPhoto, TDLibFile, code reviews, logging categories: [Slava Monich](https://github.com/monich)
- Chat info page, performance improvements to chat page, location support, app initialization/registration with Telegram, project dependencies, emoji handling, qml/js optimizations, multi-message actions, i18n fixes, message media UI, chat permission handling, bug fixes, code reviews, logging categories, bot support, github build: [jgibbon](https://github.com/jgibbon)
- Copy message to clipboard: [Christian Stemmle](https://github.com/chstem)
- Hide send message button if send-by-enter is switched on, focus text input on entering a chat: [santhoshmanikandan](https://github.com/santhoshmanikandan)
- Integration of logout and sesison options to settings page, search results optimization, highlight unread conversations: [Peter G.](https://github.com/nephros)
- Option to always append last message in notifications: [Johannes Bachmann](https://github.com/dscheinah)
- Option to jump to quoted message, widescreen UI adjustments, bug fixes for message forwarding and copying: [Mikhail Barashkov](https://github.com/mbarashkov)

Translations:
- Chinese: [dashinfantry](https://github.com/dashinfantry)
- Finnish: [jorm1s](https://github.com/jorm1s)
- French: [Patrick Hervieux](https://github.com/pherjung), [Nicolas Bourdais](https://github.com/nbourdais)
- Hungarian: [edp17](https://github.com/edp17)
- Italian: [Matteo](https://github.com/iamnomeutente)
- Polish: [atlochowski](https://github.com/atlochowski)
- Russian: [Rustem Abzalov](https://github.com/arustg) and [Slava Monich](https://github.com/monich)
- Slovak: [okruhliak](https://github.com/okruhliak)
- Spanish: [carlosgonz](https://github.com/GNUuser)
- Swedish: [Åke Engelbrektson](https://github.com/eson57)

This project uses the following libraries:

- The Telegram Database Library (TDLib) - available on [GitHub.com](https://github.com/tdlib/td). Thanks for making it available under the conditions of the Boost Software License 1.0! Details about the license of TDLib in [its license file](https://github.com/tdlib/td/blob/master/LICENSE_1_0.txt).
- Emoji parsing and artwork by [Twitter Emoji (Twemoji)](http://twitter.github.io/twemoji/), copyright 2018 Twitter, Inc and other contributors, Code licensed under the [MIT License](http://opensource.org/licenses/MIT), Graphics licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Animated sticker parsing and animation by [rlottie](https://github.com/Samsung/rlottie), copyright 2020 Samsung Electronics Co., Ltd. and [other contributors](https://github.com/Samsung/rlottie/blob/master/AUTHORS), Code licensed under the [MIT License](https://github.com/Samsung/rlottie/blob/master/licenses/COPYING.MIT), some rlottie components [licensed under other licenses](https://github.com/Samsung/rlottie/blob/master/COPYING).
- Reverse geocoding for location attachments by [OpenStreetMap Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim).
- Calls work through [tgcalls](https://github.com/TelegramMessenger/tgcalls) - the Telegram Calls Library. Thanks for making it available under the [GNU LGPL V3 license](https://github.com/TelegramMessenger/tgcalls/tree/master/LICENSE)!
- tgcalls relies internally on WebRTC, and YAST packages WebRTC using [tg_owt](https://github.com/desktop-app/tg_owt). Thanks for making it available under the [BSD 3-Clause license](https://github.com/desktop-app/tg_owt/blob/master/LICENSE)!
- WebRTC relies on [openh264](https://github.com/cisco/openh264) for working with the H264 codec. Thanks for making it available under the [BSD 2-Clause license](https://github.com/cisco/openh264/blob/master/LICENSE)!

## License
Licensed under GNU GPLv3

## Build
### Local build

This contains information about building YAST for SailfishOS. AsteroidOS version of YAST is no longer supported; a separate client for AsteroidOS based on yaqtlib will soon be developed instead.

Simply clone this repository and ensure to have all [submodules](https://git-scm.com/docs/git-submodule) imported as well (e.g. by using `git submodule update --init --recursive`). Then use the project file `CMakeLists.txt` to import the sources in your SailfishOS IDE. To build and run Fernschreiber or an application which is based on Fernschreiber, you need to create the file `harbour-yast-client/src/tdlibsecrets.h` and enter the required constants in the following format:

```
#pragma once
const char TDLIB_API_ID[] = "42424242";
const char TDLIB_API_HASH[] = "1234567890abcdef1234567890abcdef";
```

You get the Telegram API ID and hash as soon as you've registered your own application on [https://my.telegram.org](https://my.telegram.org).

Moreover, you need to have a compiled version of [TDLib 1.8.65](https://github.com/tdlib/td) in the sub-directory `tdlib`. This sub-directory must contain another sub-directory that fits to the target device architecture (e.g. aarch64, armv7hl or i486). Within this directory, there needs to be a folder called `lib` that contains at least `libtdjson.so`. For armv7hl the relative path would consequently be `tdlib/armv7hl/lib`.

You may just want to download the [tdlib.zip from our fork](https://github.com/roundedrectangle/td/releases) to just use the exact version of the latest official Fernschreiber release. To use it, you need to extract it into your local `tdlib/` folder as described above. If so, you're done and can compile Fernschreiber using the Sailfish SDK. If you want to build TDLib for yourself, please keep on reading.

In case you want to use the same codebase which was used to compile the library that is shipped with YAST, please [check out the fork](https://github.com/roundedrectangle/td):

- `alias sfdk=~/SailfishOS/bin/sfdk`
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

Unless harbour compatibility is enabled, YAST also requites tg_owt (WebRTC) for calls. You can just download it from [our fork](https://github.com/yast-client/tg_owt/releases/latest) and extract to the tg_owt/ folder in the root of this project. If you want to compile tg_owt manually, see [here](doc/tg_owt.md).

### Harbour compatibility
Some YAST features are not harbour-compatible. In the harbour version, they can be stripped out by changing the `HARBOUR_COMPLIANCE` value to `on` in the SPEC file. Currently, such features include:

1. Audio recording backend based on the GStreamer C API
2. Calls (see above)

### Github Action

Please read the "Local build" section anyway to understand what's going on before continuing. If you want to automatically build your fork on Github, you'll still need to get a Telegram API ID and hash. These are then [added as project secrets](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository) named `TDLIB_API_ID` and `TDLIB_API_HASH`.

By default, only commits on the main branch will be built. You may [change that for your fork](https://docs.github.com/en/actions/quickstart).

Nightly releases are available [here](https://github.com/yast-client/harbour-yast-client/releases/nightly). If a pushed tag starts with 'v', a release for it will be automatically created.


## Debug
YAST does only output a few TDLib messages by default. To get its own debug log messages, you can either run a debug build to see all of them or use the environment variable `QT_LOGGING_RULES` to specify/filter which messages you'd like to see.

Run `QT_LOGGING_RULES="yaqtlib.*=true;yast-client.*=true" harbour-yast-client` to see all messages or replace the `*` with specific logging categories. You'll find the logging category inside the corresponding `.cpp` file for backend usage or you can use `JS` to only see frontend messages.

You can append ` &> yast.log` to the command to create a text file containing the debug messages.

**Please be aware that debug messages will most likely include personal information** including (but not limited to) chat content and user ids/names of yourself and all your chat partners. Do not share it publicly and, at your discretion, try to remove private info even from the parts you do share with a trusted person.

### GDB

To debug complex issues you can use GDB. First, ensure that you installed not only the app, but also its debugsource and debuginfo packages. Then launch it with `gdb /usr/bin/harbour-yast-client`, optionally prepending the command with `QT_LOGGING_RULES="yaqtlib.*=true;yast-client.*=true"` if you want to read the logs.

Inside GDB, you will have to enter `handle SIGILL nostop noprint` command to ignore some false errors coming from OpenSSL. Otherwise app will fail

You can then proceed with adding required breakpoints via `b ../harbour-yast-client/src/file_name.cpp:line_number` (`break`). A breakpoint can also be removed with `clear ../harbour-yast-client/src/file_name.cpp:line_number`.

After that you can run the program with `run`. It will pause at your specified breakpoints. In those cases you can use `step` to jump to the next part of the code, `next` to jump to next code line directly (without diving into functions) or `continue` to run the program normally (for example, if you only need to debug the second time the program reaches a specific code block). If the program crashes, it will also be possible to read the stack trace using `bt` (`backtrace`).

Alternatively, GDB can be used from Sailfish IDE. To ensure OpenSSL false errors will be ignored, go to Options in it, then Debugging, GDB and add the following to startup commands: `handle SIGILL nostop noprint`. Then run the program in debug mode as usual. Note that it might not always work correctly, so using GDB from command line is preferred.

## Contribute

If you want to contribute bug fixes, improvements, new features etc. please create a pull request (PR). PRs are always welcome and will be reviewed as soon as possible, but may take some time. :)
