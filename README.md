# YAST Client
YAST Client is a yet another SailfishOS Telegram client

## Credits

Author: @roundedrectangle

### Translations

See [here](doc/translating.md) for additional notes on translating YAST.

- Italian by @legacychimera247
- Russian by @windes14

### Fernschreiber

YAST wouldn't be possible without everyone who contributed to Fernschreiber. You can see the full, up-to-date list of contributors on [Fernschreiber's README](https://github.com/Wunderfitz/harbour-fernschreiber/blob/master/README.md). A brief list of Fernschreiber contributors is available [here](doc/fernschreiber-credits.md).

### Libraries

This project uses the following libraries:

- [yaqtlib](https://github.com/yast-client/yaqtlib) is a yet another Qt TDLib library. Licensed under [GNU LGPL V3](https://github.com/TelegramMessenger/tgcalls/tree/master/LICENSE)
- [TDLib](https://github.com/tdlib/td) (Telegram Database library), cross-platform library for building Telegram clients. Licensed under [Boost Software License 1.0](https://github.com/tdlib/td/blob/master/LICENSE_1_0.txt)
- Emoji parsing and artwork by [twemoji](https://github.com/jdecked/twemoji), copyright 2022–present Jason Sofonia & Justine De Caires, 2014–2021 Twitter. Code is licensed under the [MIT License](http://opensource.org/licenses/MIT), graphics licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Animations in TGS (Telegram Stickers) format are rendered using [tlottie](https://github.com/dkaraush/tlottie), licensed under the [MIT license](https://github.com/dkaraush/tlottie/blob/main/LICENSE)
- Reverse geocoding for location attachments is done using [OpenStreetMap Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim)
- Calls work using [tgcalls](https://github.com/TelegramMessenger/tgcalls), the Telegram Calls Library. Licensed under [GNU LGPL V3](https://github.com/TelegramMessenger/tgcalls/tree/master/LICENSE)
- [tg_owt](https://github.com/desktop-app/tg_owt) (WebRTC). Licensed under [BSD 3-Clause license](https://github.com/desktop-app/tg_owt/blob/master/LICENSE)
- WebRTC relies on [openh264](https://github.com/cisco/openh264) for working with the H264 codec. Thanks for making it available under the [BSD 2-Clause license](https://github.com/cisco/openh264/blob/master/LICENSE)!

## License
Licensed under GNU GPLv3

## Build
### Local build

This contains information about building YAST for SailfishOS. AsteroidOS version of YAST is no longer supported; a separate client for AsteroidOS based on yaqtlib will soon be developed instead.

Simply clone this repository and ensure to have all [submodules](https://git-scm.com/docs/git-submodule) imported as well (e.g. by using `git submodule update --init --recursive`). Then use the project file `CMakeLists.txt` to import the sources in your SailfishOS IDE. To build and run YAST Client, you need to obtain your own Telegram API ID and hash on [https://my.telegram.org](https://my.telegram.org). After that, create the file `harbour-yast-client/src/tdlibsecrets.h` and enter the required constants in the following format:

```
#pragma once
const char TDLIB_API_ID[] = "42424242";
const char TDLIB_API_HASH[] = "1234567890abcdef1234567890abcdef";
```

YAST Client depends on TDLib and WebRTC libraries, which are heavy. For your convenience, CMake will automatically download them. If you want to build (or download) them manually, see [here](doc/libraries.md).

### Harbour compatibility
Some YAST features are not harbour-compatible. In the harbour version, they can be stripped out by changing the `HARBOUR_COMPLIANCE` value to `on` in the SPEC file. Currently, such features include:

1. Audio recording backend based on the GStreamer C API
2. Calls (see above)
3. Contact sync (see notes in [ContactSync.qml](qml/components/ContactSync.qml) for more info)

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

You can contribute to YAST in many ways. If you found a bug, or want to suggest an improvement of a new feature, you can create an issue on GitHub. You can also join the [YAST discussion group](https://t.me/+Tz72Lf_eKeVlYmVi) and share your idea there.

If you know how to code and want to fix a bug, add a new feature or something else, you can submit pull requests to YAST, (and, if needed, YAST's core library, [yaqtlib](https://github.com/yast-client/yaqtlib)), which is very welcome.

Another way to contribute is to translate the app to your language. You can do so by downloading the `.ts` file for your language, editing it manually or using Qt Linguist, after which forking YAST, changing the file's contents in your fork and finally submitting a pull request with the changes. If you are starting a new translation, simply take an existing translation file as a reference, rename it to `harbour-yast-client-<language code>.ts`, change the language code in the file, translate it as usual and submit a PR with the translation file added.

**YAST Client currently has a strict AI (LLM) policy.** You can use AI for researching, learning, troubleshooting, debugging and similar purposes. However, if your PR heavily contains AI-generated code blocks, it may get closed, as such code is often prone to errors and bad styling. It is also strictly prohibited to include any AI-generated text blocks in Markdown files. *These rules are subject to change.*