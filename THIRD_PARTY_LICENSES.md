# Third-party licenses

The Psito Player code is under the Apache License 2.0. It uses these components. The
full texts of everything compiled into the app are in **Settings, About, Full license
texts**, and in `/usr/share/doc/psito-player/NOTICES` when installed from the package. On
Windows, this file and the license texts are in the `licenses` folder of the install.

## Dart packages

| Package | License |
|---|---|
| Flutter and its packages | BSD-3-Clause |
| `media_kit`, `media_kit_libs_linux`, `media_kit_libs_windows_audio` | MIT |
| `audio_metadata_reader` | MIT |
| `image` | MIT |
| `sqlite3`, `smtc_windows`, `flutter_rust_bridge` | MIT |
| `dbus` | MPL-2.0 |
| `ffi`, `file_selector`, `intl`, `path` | BSD-3-Clause |

## System libraries, not shipped with the player

| Library | License |
|---|---|
| libmpv | GPL-2+ or LGPL-2.1+ in the source. On Debian and Ubuntu the binaries are GPL-3+ |
| FFmpeg, used by libmpv | LGPL-2.1+ for the main libraries |
| SQLite | Public domain |
| GTK 3 | LGPL-2.1+ |

The player loads libmpv at run time. Where that library is under the GPL, those terms
apply to the two together when distributed. The player's source is public, and anyone
who wants a closed build needs to replace the engine behind `PlayerEngine`.

## Shipped with the Windows installer

| Library | License |
|---|---|
| libmpv (`libmpv-2.dll`, built with `-Dgpl=false`) | LGPL-2.1+ |
| FFmpeg, inside that DLL (`--disable-gpl --enable-version3`) | LGPL-3.0+ |
| SQLite (`sqlite3.dll`) | Public domain |
| The Rust crates of `smtc_windows` | MIT or Apache-2.0 |
| Microsoft Visual C++ Runtime | Microsoft Software License, as redistributable files |

`libmpv-2.dll` comes from `media_kit_libs_windows_audio`. Its source and build recipe,
with the other small libraries linked into it, are at
<https://github.com/media-kit/libmpv-win32-audio-build>, release `2023-09-24`. The DLL
sits next to the player and can be replaced by another build of the same API.

## Fonts and icons

The interface uses the Material Icons (Apache-2.0), which come with Flutter.
