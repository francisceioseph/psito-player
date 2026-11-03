# Third-party licenses

The Psito Player code is under the Apache License 2.0. It uses these components. The
full texts of everything compiled into the app are in **Settings, About, Full license
texts**, and in `/usr/share/doc/psito-player/NOTICES` when installed from the package.

## Dart packages

| Package | License |
|---|---|
| Flutter and its packages | BSD-3-Clause |
| `media_kit`, `media_kit_libs_linux` | MIT |
| `audio_metadata_reader` | MIT |
| `image` | MIT |
| `sqlite3` | MIT |
| `dbus` | MPL-2.0 |
| `file_selector`, `intl`, `path` | BSD-3-Clause |

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

## Fonts and icons

The interface uses the Material Icons (Apache-2.0), which come with Flutter.
